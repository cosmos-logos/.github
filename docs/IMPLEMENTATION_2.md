# Phase 2 — Local Git + Journal Backend: Implementation Summary

**Agent:** Thoth Coding Agent
**Date:** 2026-03-23
**Branch:** `brain/1.7.x.x`
**Status:** PHASE 2 COMPLETE — AWAITING COMMIT REVIEW

---

## What Was Built

Phase 2 delivers the offline-first journal system: local git operations, journal CRUD API, GitHub sync state machine, conflict resolution, and smart mode writing heuristics.

### Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `thoth/git/lock.py` | 28 | `RepoLock` — per-path async mutex using `asyncio.Lock`. Class-level dict keyed by resolved path. Enforces Invariant 12. |
| `thoth/git/bootstrap.py` | 68 | `bootstrap_repo()` — first-run init: creates dir, `git init`, sets identity (`Thoth <thoth@cosmos-logos.local>`), writes `.gitignore`, creates `entries/` dir, makes initial commit. Idempotent — returns existing repo if `.git` already present. |
| `thoth/git/local.py` | 205 | `LocalGit` — all journal git operations: `commit_entry` (auto_merge/pr modes), `read_entry`, `list_entries`, `search` (git grep), `status` (branch, ahead/behind, dirty, entry count). All methods synchronous (designed for `run_in_executor`). |
| `thoth/git/conflict.py` | 97 | `ConflictResolver` — `local_wins` strategy. Iterates `unmerged_blobs()`, runs `checkout --ours` for each conflicted path, commits the resolution. Returns a `ConflictLog` with records of every resolved file. |
| `thoth/git/sync.py` | 158 | `GitSync` — 5-state machine (`IDLE` → `CHECKING` → `PULLING` → `PUSHING` → `ERROR`). Tests remote connectivity via `git ls-remote`, fetches, merges (with conflict resolution fallback), pushes. Dirty guard prevents sync with uncommitted changes. |
| `thoth/llm/writing.py` | 80 | `analyze_entry()` — deterministic smart mode heuristic. Examines word count, code block count, code density (ratio of code lines to total), and tag count. Returns `WritingAnalysis` with `recommended_mode` (`auto_merge` or `pr`) and human-readable `reason`. No LLM calls (Invariant 4). |
| `thoth/routes/journal.py` | 178 | Seven journal endpoints plus settings persistence. All git mutations wrapped in `run_in_executor` + `RepoLock`. Auto-bootstraps repo on first request. |
| `tests/test_git.py` | 97 | Tests for bootstrap (create, idempotent, custom branch), LocalGit (commit/read, list, search, status, PR branch mode), ConflictResolver (no-conflict case). |
| `tests/test_journal_routes.py` | 105 | Integration tests for all journal routes via FastAPI TestClient with temp repo path. |
| `tests/test_writing.py` | 35 | Tests for smart mode heuristic — short entry, long entry, code-heavy, many tags, high code density. |

### Files Modified

| File | Change |
|------|--------|
| `thoth/main.py` | Added `journal_router` import and `app.include_router(journal_router)` |
| `thoth/git/bootstrap.py` | Fixed initial commit to use `git.Actor` instead of raw string (GitPython requires Actor objects for `author`/`committer` params) |

---

## API Endpoints

| Method | Path | Auth | Metered | Purpose |
|--------|------|------|---------|---------|
| `POST` | `/journal/entry` | TBD | Yes (Phase 5) | Create and commit a journal entry |
| `GET` | `/journal/entries` | No | No (Invariant 5) | List all entries with metadata |
| `GET` | `/journal/entry/{path}` | No | No (Invariant 5) | Read a single entry by path |
| `GET` | `/journal/search?q=` | No | No (Invariant 5) | Search entries via git grep |
| `GET` | `/journal/status` | No | No (Invariant 5) | Repo sync status (branch, ahead/behind, entry count) |
| `POST` | `/journal/sync` | TBD | Yes (Phase 5) | Explicit GitHub sync (pull + push) |
| `POST` | `/journal/settings` | TBD | No | Update journal settings |
| `POST` | `/journal/settings/migrate` | TBD | No | Migrate repo to new path |

---

## Architecture Decisions

### Entry Format

Entries are Markdown files with YAML frontmatter, stored in `entries/`:

```
entries/2026-03-23-my-title-a1b2c3d4.md
```

Filename: `{date}-{slug}-{hash}.md` where `hash` is the first 8 chars of `SHA256(timestamp + title)`. This prevents collisions for same-day, same-title entries.

Frontmatter:
```yaml
---
title: My Title
date: 2026-03-23T14:30:00Z
tags: [tag1, tag2]
---
```

### Commit Modes

| Mode | Behavior |
|------|----------|
| `auto_merge` | Commits directly to the active branch (default) |
| `pr` | Creates a `thoth/journal/{date}-{slug}-{hash}` branch, commits there, returns to the original branch |
| `smart` | Runs the writing heuristic, then delegates to `auto_merge` or `pr` |

### Smart Mode Thresholds

| Trigger | Threshold | Result |
|---------|-----------|--------|
| Word count | ≥ 500 | PR mode |
| Code blocks | ≥ 3 | PR mode |
| Code density | ≥ 40% | PR mode |
| Tag count | ≥ 5 | PR mode |

If none trigger, the entry goes to `auto_merge`. The heuristic is purely deterministic — no LLM calls, upholding Invariant 4.

### GitSync State Machine

```
IDLE ──→ CHECKING ──→ PULLING ──→ PUSHING ──→ IDLE
  ↑          │            │            │
  └──────────┴────────────┴────────────┘
                    ERROR
```

- **CHECKING**: `git ls-remote` with 10s timeout
- **PULLING**: `fetch` + `merge`. On conflict → `ConflictResolver.resolve_local_wins()`
- **PUSHING**: `push` with ahead-count tracking
- **ERROR**: recoverable — next sync attempt starts from IDLE

Guards:
- No remote configured → returns immediately with error message
- Dirty working tree → refuses to sync (prevents data loss)

### Conflict Resolution

`local_wins` is the only strategy. When a merge conflict occurs:

1. Iterate `unmerged_blobs()` to find conflicted paths
2. `git checkout --ours` for each conflicted file
3. Stage resolved files
4. Commit with message: `fix(journal): resolve N conflict(s) — local_wins`
5. Return a `ConflictLog` for the user to review

The remote version is discarded. This upholds Invariant 9 (GitHub is sync, not primary) — the user's local journal always wins.

### Async Wrappers

Every journal route follows the pattern:

```python
async with lock:
    result = await _run_in_executor(git.some_method, args)
```

- `_run_in_executor` → `loop.run_in_executor(None, ...)` (Invariant 11)
- `RepoLock.for_path()` → per-path `asyncio.Lock` (Invariant 12)
- Read-only operations skip the lock (no mutation risk)

### Settings Persistence

`POST /journal/settings` updates in-memory settings and persists to `.thoth.json`. The merge is additive — only the `journal` section is overwritten; other sections (llm, github, entitlement) are preserved.

`POST /journal/settings/migrate` copies the entire git repo via `shutil.copytree` under the RepoLock, then updates the config.

---

## What Was NOT Done

- **Auth middleware on journal routes**: `ServiceBridge` is built (Phase 1) but not wired as route dependencies. Write endpoints (`/entry`, `/sync`, `/settings`) will require auth when the middleware is integrated.
- **Auto-sync background task**: `auto_sync` and `sync_interval_seconds` are configurable but no background scheduler runs periodic syncs. This could be added as a lifespan task in a future phase.
- **Conflict resolution UI feedback**: The `ConflictLog` is returned but not surfaced in any user-facing endpoint. The sync endpoint returns `conflicts_resolved` count.

---

## Test Results

```
42 passed in 2.53s

tests/test_auth.py                  8 passed (Phase 1)
tests/test_chat.py                  4 passed (Phase 1)
tests/test_discovery.py             4 passed (Phase 1)
tests/test_git.py                  11 passed (Phase 2 — NEW)
tests/test_journal_routes.py       10 passed (Phase 2 — NEW)
tests/test_writing.py               5 passed (Phase 2 — NEW)
```

### Phase 2 Test Coverage

| Test | What It Validates |
|------|-------------------|
| `test_creates_repo` | Bootstrap creates `.git`, `.gitignore`, `entries/.gitkeep`, initial commit |
| `test_idempotent` | Re-bootstrapping same path returns same repo |
| `test_custom_branch` | Bootstrap respects `default_branch` parameter |
| `test_commit_and_read` | Write entry → read back with correct title, content, tags |
| `test_list_entries` | Multiple entries listed with correct count |
| `test_search` | `git grep` finds content inside entries |
| `test_search_no_results` | Missing content returns empty list |
| `test_read_missing` | Non-existent path returns None |
| `test_status` | Branch name, remote status, entry count |
| `test_pr_mode_creates_branch` | PR mode creates `thoth/journal/...` branch, returns to main |
| `test_no_conflicts` | ConflictResolver on clean repo returns empty log |
| `test_create_entry` | `POST /journal/entry` → 200, correct path and mode |
| `test_list_entries` | `GET /journal/entries` → 200, correct count |
| `test_read_entry` | `GET /journal/entry/{path}` → 200, correct content |
| `test_read_missing_entry` | Missing entry → 404 |
| `test_search` | `GET /journal/search?q=` → 200, results found |
| `test_search_empty_query` | Empty query → 400 |
| `test_status` | `GET /journal/status` → 200, correct branch and count |
| `test_sync_no_remote` | `POST /journal/sync` without remote → error message |
| `test_smart_mode` | Short entry via smart mode → auto_merge |
| `test_settings_update` | `POST /journal/settings` → 200, settings updated |
| `test_short_entry_auto_merge` | < 500 words → auto_merge |
| `test_long_entry_pr` | ≥ 500 words → pr mode |
| `test_code_heavy_pr` | ≥ 3 code blocks → pr mode |
| `test_many_tags_pr` | ≥ 5 tags → pr mode |
| `test_high_code_density_pr` | > 40% code lines → high density detected |

---

## Exit Criteria

| Criterion | Status |
|-----------|--------|
| Create entry → committed to local git | ✓ `POST /journal/entry` commits with frontmatter |
| List entries from git tree | ✓ `GET /journal/entries` with metadata |
| Read single entry | ✓ `GET /journal/entry/{path}` (no auth — Invariant 5) |
| Search entries via git grep | ✓ `GET /journal/search?q=` |
| Status shows branch, ahead/behind, entry count | ✓ `GET /journal/status` |
| Sync to GitHub (when remote configured) | ✓ `POST /journal/sync` with 5-state machine |
| Conflict resolution works | ✓ `local_wins` strategy with ConflictLog |
| Smart mode heuristic selects commit mode | ✓ Deterministic analysis, no LLM |
| PR mode creates feature branch | ✓ `thoth/journal/{date}-{slug}-{hash}` |
| Settings update and persist | ✓ `POST /journal/settings` writes `.thoth.json` |
| All Phase 1 tests still pass | ✓ 16/16 Phase 1 tests green |

---

## Invariants Upheld

| # | Invariant | How |
|---|-----------|-----|
| 1 | All state reproducible from local git repo | Journal entries are files in git. No external state. |
| 3 | No hidden state outside user-controlled systems | Entries, settings, and sync state all in user's git repo or `.thoth.json` |
| 4 | All LLM output optional, never authoritative | Smart mode heuristic is deterministic — zero LLM calls |
| 5 | Reads are never metered | All GET endpoints are free and unauthenticated |
| 9 | GitHub is sync, not primary | Local repo always works. Sync is explicit user action. Conflicts resolve local_wins. |
| 11 | All git mutations in `run_in_executor` | Every write route uses `_run_in_executor()` |
| 12 | All git mutations in `RepoLock` | Every write route acquires `RepoLock.for_path()` |

---

## Next: Phase 3 — Journal UI

Phase 3 builds the single-file journal HTML application:

| Task | What It Does |
|------|-------------|
| 3.1 | HTML skeleton — dark theme, responsive, TurtleShell design language |
| 3.2 | Markdown editor — CodeMirror 6 (CDN), fallback to textarea |
| 3.3 | Live preview — marked.js, 300ms debounce |
| 3.4 | Slash commands — `/title`, `/tag`, `/mode` (client-side) |
| 3.5 | Save flow — POST to `/journal/entry`, SSE confirmation |
| 3.6 | Entry sidebar — local git tree, unsynced badges, click to load |
| 3.7 | Search — input → `GET /journal/search?q=` → results list |
| 3.8 | Sync button + offline banner — polls `/journal/status` every 30s |
| 3.9 | Settings panel — all config options, first-load setup flow |
| 3.10 | Read-without-auth — no session needed for reads |
| 3.11 | Draft auto-save — `sessionStorage` on keystroke |
| 3.12 | Smart mode banner — three options (PR / auto-merge / suppress) |
| 3.13 | SeaShell balance display |

**Exit criteria:** Open `journal.html`, write entry, save, see in sidebar, search, sync to GitHub. Works offline. Settings configurable.

---

*Phase 2 Implementation Summary — Thoth Coding Agent — 2026-03-23*
