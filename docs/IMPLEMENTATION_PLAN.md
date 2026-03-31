# Thoth Writing Agent — Implementation Plan
## Lead Developer Agent: Cosmic Turtle
### Version: 1.0.0 — March 23, 2026

**Spec:** cosmos-logos/thoth Formal Specification v1.2.0
**Branch:** `brain/1.7.x.x`
**Status:** AWAITING PM REVIEW

---

## Open Questions (Blocking)

| # | Question | Impact | Default If No Answer |
|---|----------|--------|---------------------|
| Q1 | Does `cosmos-logos` GitHub org exist? Create `thoth` repo there? | Phase 0 | Create local, push later |
| Q2 | JWT signing key for service delegation — OG_Signing_Key or new key? | Phase 1 auth | Use OG_Signing_Key initially |
| Q3 | Is TurtleShell agent discovery UI (Add Agent by URL) in scope? | Phase 7 | Build standalone first, discovery UI separate |
| Q4 | Deployment target — local dev, Mac Mini fleet, or cloud? | Dockerfile, registry | Local dev + Docker, ghcr.io/olympus-616/thoth |
| Q5 | Anthropic API key — own key or shared with Athena? | .env config | Own key (spec says so) |
| Q6 | Journal embedding — iframe in turtleshell-web or separate URL? | Phase 3 UI | Separate URL, linked from TurtleShell |

---

## Architecture Overview

### What Gets Built Where

| Deliverable | Repository | Language | Description |
|-------------|-----------|----------|-------------|
| Thoth Agent Server | `cosmos-logos/thoth` (submodule at `/thoth`) | Python/FastAPI | Core agent: git, journal, code review, webhooks, entitlement |
| cosmos-logos.json (Thoth) | `cosmos-logos/thoth` | JSON | Agent discovery manifest |
| cosmos-logos.json (Athena) | `cosmos-logos/thoth` or `athena` | JSON | Reference manifest for existing agent |
| cosmos-logos.schema.json | `cosmos-logos/thoth` | JSON Schema | Validator for all agent manifests |
| journal.html | `cosmos-logos/thoth/static/` | HTML/JS/CSS | Single-file journal UI |
| Scaffolding | `cosmos-logos/thoth/scaffolding/` | Template files | Agent development starter kit |
| Docker Image | `ghcr.io/olympus-616/thoth:1.0.0` | Dockerfile | Containerized agent |
| Agent Discovery UI | `iris/reactforce/turtleshell` | React/TypeScript | "Add Agent by URL" in Settings → Agent Setup |
| cosmos-logos Store | `iris/reactforce/turtleshell` | TypeScript/Zustand | Agent registry, token delegation, rate table storage |

### Dependency Graph

```
Phase 0 (Foundation) ─────────────────────────────────┐
    │                                                   │
Phase 1 (Core Agent) ──── Phase 2 (Local Git + Journal Backend)
    │                          │
    │                     Phase 3 (Journal UI)
    │                          │
Phase 4 (Code Agent + Webhooks)│
    │                          │
Phase 5 (Entitlement) ────────┘
    │
Phase 6 (Scaffolding)
    │
Phase 7 (TurtleShell Discovery Integration) ← separate feature, can run in parallel
```

---

## Phase 0 — Foundation

**Goal:** Repo exists, manifests committed, CI validates schema, submodule added to olympus-616.

### Tasks

| # | Task | Files | Estimate |
|---|------|-------|----------|
| 0.1 | Create `thoth` directory structure (full tree from spec Section 2) | All dirs + `__init__.py` files | 15 min |
| 0.2 | Write `cosmos-logos.json` (Thoth manifest — exact copy from spec) | `cosmos-logos.json` | 10 min |
| 0.3 | Write `cosmos-logos.json` (Athena-616 reference manifest) | `athena-616.cosmos-logos.json` | 10 min |
| 0.4 | Write `cosmos-logos.schema.json` (JSON Schema for agent manifests) | `cosmos-logos.schema.json` | 30 min |
| 0.5 | Write `requirements.txt` | `requirements.txt` | 5 min |
| 0.6 | Write `.env.example` | `.env.example` | 5 min |
| 0.7 | Write `Dockerfile` (multi-stage: deps → app) | `Dockerfile` | 15 min |
| 0.8 | Write `docker-compose.yml` | `docker-compose.yml` | 10 min |
| 0.9 | Write `.thoth.json.example` + `.thoth.local.json.example` | Config templates | 10 min |
| 0.10 | Write `turtleshell.json` (user preferences template) | `turtleshell.json` | 5 min |
| 0.11 | Write `README.md` | `README.md` | 20 min |
| 0.12 | GitHub Actions: validate manifest on push | `.github/workflows/validate.yml` | 10 min |
| 0.13 | Add as submodule to olympus-616 at `/thoth` | `.gitmodules` | 5 min |

**Exit criteria:** `cosmos-logos.json` served, schema validates, CI green, submodule linked.

---

## Phase 1 — Core Agent

**Goal:** FastAPI server boots, serves discovery, validates auth, streams chat via Claude.

### Tasks

| # | Task | Files | Estimate |
|---|------|-------|----------|
| 1.1 | `main.py` — FastAPI app, lifespan startup checks, CORS, static mount | `thoth/main.py` | 30 min |
| 1.2 | `config.py` — env loader, cosmos-logos.json loader, settings models | `thoth/config.py` | 20 min |
| 1.3 | Discovery route — `/.well-known/cosmos-logos.json` with version headers | `thoth/routes/discovery.py` | 15 min |
| 1.4 | Ping + Health routes | `thoth/routes/discovery.py` | 10 min |
| 1.5 | Service bridge — JWT validation (issuer, audience, expiry) | `thoth/auth/service_bridge.py` | 30 min |
| 1.6 | Session management — encrypted cookie, 8h expiry | `thoth/auth/session.py` | 20 min |
| 1.7 | Claude wrapper — Anthropic SDK, streaming SSE, persona from manifest | `thoth/llm/claude.py` | 30 min |
| 1.8 | Chat route — `/chat` SSE endpoint with Thoth persona | `thoth/routes/chat.py` | 25 min |
| 1.9 | SQLite initialization (seashell_ledger, webhook_jobs, webhook_deliveries) | `thoth/main.py` + schema | 15 min |
| 1.10 | Tests — discovery, ping, health, chat SSE format | `tests/` | 30 min |

**Dependencies:** Phase 0 complete.
**Exit criteria:** `GET /.well-known/cosmos-logos.json` returns valid manifest. `POST /chat` streams Claude response with Thoth persona. JWT validation works.

---

## Phase 2 — Local Git + Journal Backend

**Goal:** Journal CRUD works entirely offline against local git. GitHub sync works when network available.

### Tasks

| # | Task | Files | Estimate |
|---|------|-------|----------|
| 2.1 | `RepoLock` — async mutex per repo path | `thoth/git/lock.py` | 10 min |
| 2.2 | `RepoBootstrap` — first-run init, git identity, gitignore, initial commit | `thoth/git/bootstrap.py` | 30 min |
| 2.3 | `LocalGit` — commit, read, search (git grep), list, all via `run_in_executor` | `thoth/git/local.py` | 45 min |
| 2.4 | `ConflictResolver` — local_wins strategy, conflict log | `thoth/git/conflict.py` | 20 min |
| 2.5 | `GitSync` — state machine (5 states), push, pull, network check, dirty guard | `thoth/git/sync.py` | 40 min |
| 2.6 | Journal routes — `POST /journal/entry` (write per mode: auto_merge/pr/smart) | `thoth/routes/journal.py` | 30 min |
| 2.7 | Journal routes — `GET /journal/entries` (local git tree) | `thoth/routes/journal.py` | 15 min |
| 2.8 | Journal routes — `GET /journal/search?q=` (git grep) | `thoth/routes/journal.py` | 15 min |
| 2.9 | Journal routes — `GET /journal/entry/{path}` (read, no auth required) | `thoth/routes/journal.py` | 10 min |
| 2.10 | Journal routes — `GET /journal/status` (sync state, ahead count) | `thoth/routes/journal.py` | 15 min |
| 2.11 | Journal routes — `POST /journal/sync` (explicit GitHub sync) | `thoth/routes/journal.py` | 20 min |
| 2.12 | Settings routes — `POST /journal/settings`, `POST /journal/settings/migrate` | `thoth/routes/journal.py` | 25 min |
| 2.13 | Smart mode heuristic — word count, tags, code density | `thoth/llm/writing.py` | 15 min |
| 2.14 | Branch naming — `thoth/journal/{date}-{slug}-{hash}` | `thoth/git/local.py` | 10 min |
| 2.15 | Tests — bootstrap, commit, read, search, sync, conflict resolution | `tests/` | 40 min |

**Dependencies:** Phase 1 complete (auth + config).
**Exit criteria:** Create entry → committed to local git. List entries. Search. Sync to GitHub. Status shows unsynced count. Conflict resolution works.

---

## Phase 3 — Journal UI

**Goal:** `journal.html` is a complete, zero-build journal application.

### Tasks

| # | Task | Files | Estimate |
|---|------|-------|----------|
| 3.1 | HTML skeleton — dark theme, responsive, TurtleShell design language | `static/journal.html` | 30 min |
| 3.2 | Markdown editor — CodeMirror 6 (CDN), fallback to textarea | `static/journal.html` | 45 min |
| 3.3 | Live preview — marked.js, 300ms debounce | `static/journal.html` | 20 min |
| 3.4 | Slash commands — `/title`, `/tag`, `/mode` (client-side) | `static/journal.html` | 25 min |
| 3.5 | Save flow — POST to `/journal/entry`, SSE confirmation | `static/journal.html` | 20 min |
| 3.6 | Entry sidebar — local git tree, unsynced badges, click to load | `static/journal.html` | 30 min |
| 3.7 | Search — input → `GET /journal/search?q=` → results list | `static/journal.html` | 15 min |
| 3.8 | Sync button + offline banner — polls `/journal/status` every 30s | `static/journal.html` | 20 min |
| 3.9 | Settings panel — all config options, first-load setup flow | `static/journal.html` | 30 min |
| 3.10 | Read-without-auth — no session needed for reads | `static/journal.html` | 10 min |
| 3.11 | Draft auto-save — `sessionStorage` on keystroke | `static/journal.html` | 10 min |
| 3.12 | Smart mode banner — three options (PR / auto-merge / suppress) | `static/journal.html` | 15 min |
| 3.13 | SeaShell balance display | `static/journal.html` | 10 min |

**Dependencies:** Phase 2 complete (all journal API endpoints).
**Exit criteria:** Open `journal.html`, write entry, save, see in sidebar, search, sync to GitHub. Works offline. Settings configurable.

---

## Phase 4 — Code Agent + Webhooks

**Goal:** Thoth reviews PRs, manages branches, responds to GitHub webhooks.

### Tasks

| # | Task | Files | Estimate |
|---|------|-------|----------|
| 4.1 | GitHub client — PyGitHub wrapper, rate limit handling, exponential backoff | `thoth/github/client.py` | 25 min |
| 4.2 | Diff fetching — file-based chunking (not token-based) | `thoth/github/diff.py` | 25 min |
| 4.3 | Code review — diff → Claude → structured output, `dry_run` support | `thoth/llm/code_review.py` | 30 min |
| 4.4 | PR management — create PR, post review comments | `thoth/github/pr.py` | 20 min |
| 4.5 | Branch management — create feature branches | `thoth/github/branches.py` | 15 min |
| 4.6 | GitHub routes — `POST /github/review`, `POST /github/branch`, `POST /github/pr` | `thoth/routes/github.py` | 25 min |
| 4.7 | Webhook handler — HMAC validation, replay protection, 202 + BackgroundTask | `thoth/routes/webhook.py` | 30 min |
| 4.8 | Webhook job persistence — SQLite, status recovery on startup | `thoth/webhooks/jobs.py` | 20 min |
| 4.9 | Event handlers — `pull_request`, `workflow_run` | `thoth/webhooks/github_actions.py` | 25 min |
| 4.10 | LLM cost guards — max calls per event, cooldown, daily cap | `thoth/webhooks/github_actions.py` | 15 min |
| 4.11 | GitHub Actions workflow template | `.github/workflows/thoth-review.yml` | 10 min |
| 4.12 | Tests — webhook HMAC, replay, review format, diff chunking | `tests/` | 35 min |

**Dependencies:** Phase 1 (auth, Claude), Phase 2 (git operations).
**Exit criteria:** PR review works (dry_run and live). Webhook receives event, returns 202, processes in background. Job persisted to SQLite.

---

## Phase 5 — Entitlement

**Goal:** SeaShell metering operational with SQLite. Adapter interface ready for future settlement.

### Tasks

| # | Task | Files | Estimate |
|---|------|-------|----------|
| 5.1 | `UsageEvent` dataclass with `operation_id` deduplication | `thoth/entitlement/seashell.py` | 10 min |
| 5.2 | `SettlementAdapter` ABC | `thoth/entitlement/adapter.py` | 10 min |
| 5.3 | `SQLiteAdapter` — aiosqlite, dedup on `operation_id` | `thoth/entitlement/adapter.py` | 20 min |
| 5.4 | `OlympusCoinAdapter` stub (interface only, no implementation) | `thoth/entitlement/adapter.py` | 5 min |
| 5.5 | `SeashellMeter` — reads rates from cosmos-logos.json, `@meter` decorator | `thoth/entitlement/seashell.py` | 25 min |
| 5.6 | Wire meter to all metered endpoints (journal_create, code_review, etc.) | All route files | 20 min |
| 5.7 | `GET /entitlement/ledger` — usage history endpoint | `thoth/routes/journal.py` or new | 15 min |
| 5.8 | Free tier enforcement — daily caps from manifest | `thoth/entitlement/seashell.py` | 15 min |
| 5.9 | Tests — metering, dedup, free tier limits | `tests/` | 20 min |

**Dependencies:** Phase 1 (config loads manifest), Phase 2 (journal endpoints to meter).
**Exit criteria:** Every metered operation creates a ledger entry. Ledger queryable. Free tier enforced. `operation_id` prevents duplicates.

---

## Phase 6 — Scaffolding

**Goal:** Any developer can fork Thoth and build their own cosmos-logos agent.

### Tasks

| # | Task | Files | Estimate |
|---|------|-------|----------|
| 6.1 | `BUILDING_AN_AGENT.md` — complete developer guide | `BUILDING_AN_AGENT.md` | 60 min |
| 6.2 | `cosmos-logos.template.json` — minimal valid manifest | `scaffolding/cosmos-logos.template.json` | 10 min |
| 6.3 | Agent template — FastAPI skeleton with discovery, ping, health, chat | `scaffolding/agent-template/` | 30 min |
| 6.4 | SeaShell template — meter wired to SQLite | `scaffolding/agent-template/seashell.py` | 10 min |
| 6.5 | Convert repo to GitHub template (settings toggle) | GitHub settings | 2 min |

**Dependencies:** All previous phases (the scaffolding extracts patterns from the working agent).
**Exit criteria:** A developer can `Use this template` → fill in cosmos-logos.json → `docker-compose up` → has a working agent with discovery, chat, and metering.

---

## Phase 7 — TurtleShell Agent Discovery Integration (Parallel Track)

**Goal:** TurtleShell web/iOS can discover, validate, and connect to any cosmos-logos agent.

This is a **separate feature** that can be built in parallel once Phase 0 manifests are committed.

### Tasks

| # | Task | Files | Repo | Estimate |
|---|------|-------|------|----------|
| 7.1 | `cosmos-logos-store.ts` — Zustand store for discovered agents, rate tables, delegated tokens | `lib/store/` | iris | 30 min |
| 7.2 | `cosmos-logos-client.ts` — fetch manifest, validate schema, version negotiation | `lib/api/` | iris | 25 min |
| 7.3 | Agent Setup page redesign — "Add Agent by URL" input, agent card preview, service requirements check, rate table display | `pages/Agents.tsx` | iris | 60 min |
| 7.4 | Service delegation — generate scoped JWT with delegated GitHub token for agent | `lib/auth/` or backend | iris + ares | 45 min |
| 7.5 | Agent tab/unlock rendering — when agent declares `unlocks`, surface UI (e.g., Journal tab) | `pages/Chat.tsx` menu | iris | 20 min |
| 7.6 | Rate change detection — 24h poll, version compare, block + notify | `cosmos-logos-store.ts` | iris | 20 min |
| 7.7 | iOS agent discovery (mirror of web) | `Core/AgentInjection/` | turtleshell-ios | 60 min |

**Dependencies:** Phase 0 manifests committed. Can run in parallel with Phases 1-6.
**Exit criteria:** User enters Thoth URL → sees agent card with capabilities + rates → clicks "Add" → GitHub token delegated → Journal tab appears.

---

## Technical Decisions

### Python Dependencies (`requirements.txt`)

```
fastapi>=0.110
uvicorn[standard]>=0.29
anthropic>=0.40
gitpython>=3.1
pygithub>=2.3
pyjwt[crypto]>=2.8
aiosqlite>=0.20
aiohttp>=3.9
python-multipart>=0.0.9
```

### Docker Strategy

- Base: `python:3.12-slim`
- Multi-stage: deps → app (like Ares/Hermes pattern)
- Volumes: `~/.turtleshell/journal` mounted for git repo persistence
- Port: 3441 (fits Olympus-616 port convention)

### Port Assignment

| Service | Port |
|---------|------|
| Thoth | 3441 |

Follows the pattern: Athena 3401, Hermes 3411, Apollo 3421, Poseidon 3431, **Thoth 3441**, Ares 3451.

### Key Design Decisions

1. **No ORM** — SQLite via `aiosqlite` directly. Three tables. No migrations framework needed.
2. **No Pydantic settings** — Simple env + JSON file loading in `config.py`. Spec is explicit about config structure.
3. **GitPython, not libgit2** — Spec calls for GitPython. Thread pool wrapping is well-defined.
4. **CodeMirror 6 via CDN** — No npm, no build. `<script src="https://cdn.jsdelivr.net/npm/@codemirror/...">`. Fallback to `<textarea>` if CDN unreachable (offline mode).
5. **Session in encrypted cookie** — Not in SQLite. Memory-only. 8h expiry. Simpler than token management.

---

## Risk Mitigations

| Risk | Mitigation | Phase |
|------|-----------|-------|
| GitPython blocks event loop | All ops in `run_in_executor` (Invariant 11) | Phase 2 |
| Concurrent git writes | `RepoLock` async mutex (Invariant 12) | Phase 2 |
| Webhook 10s timeout | BackgroundTask + 202 (spec Section 8) | Phase 4 |
| JWT spoofing | Validate issuer + audience + exp (spec Section 3) | Phase 1 |
| LLM cost explosion | Per-event limits + cooldown + daily cap | Phase 4 |
| Rate table change without notice | Version detection + 30-day notice (Invariant 6) | Phase 7 |

---

## Estimated Total Effort

| Phase | Tasks | Estimated Time |
|-------|-------|---------------|
| Phase 0 — Foundation | 13 | ~2.5 hours |
| Phase 1 — Core Agent | 10 | ~4 hours |
| Phase 2 — Local Git + Journal | 15 | ~6 hours |
| Phase 3 — Journal UI | 13 | ~4.5 hours |
| Phase 4 — Code Agent + Webhooks | 12 | ~5 hours |
| Phase 5 — Entitlement | 9 | ~2.5 hours |
| Phase 6 — Scaffolding | 5 | ~2 hours |
| Phase 7 — TurtleShell Integration | 7 | ~4.5 hours |
| **Total** | **84 tasks** | **~31 hours** |

---

## Execution Strategy

1. **Phases 0-2** execute sequentially (foundation → server → git/journal backend)
2. **Phase 3** (UI) can start as soon as Phase 2 API endpoints are stubbed
3. **Phase 4** (webhooks) can start after Phase 1 (needs auth + Claude, not journal)
4. **Phase 5** (entitlement) can start after Phase 1 (just needs config + SQLite)
5. **Phase 7** (TurtleShell integration) is independent — starts after Phase 0 manifests exist
6. **Phase 6** (scaffolding) is last — extracts patterns from working code

**Optimal parallel execution:** Phases 0 → 1 → {2, 4, 5 in parallel} → 3 → 6. Phase 7 runs independently.

---

*Implementation Plan v1.0.0 — Cosmic Turtle — March 23, 2026*
*cosmos-logos/thoth · CloudPremise LLC · MIT License*
