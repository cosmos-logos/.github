# Phase 3 — Journal UI: Implementation Summary

**Agent:** Thoth Coding Agent
**Date:** 2026-03-23
**Branch:** `brain/1.7.x.x`
**Status:** PHASE 3 COMPLETE — AWAITING COMMIT REVIEW

---

## What Was Built

Phase 3 delivers `static/journal.html` — a complete, single-file, zero-build journal application. No npm, no bundler, no framework. One HTML file with inline CSS and JavaScript, served from the FastAPI static mount at `/static/journal.html`.

### Files Created

| File | Size | Purpose |
|------|------|---------|
| `static/journal.html` | ~650 lines | Complete journal UI: editor, preview, sidebar, search, sync, settings, draft auto-save, slash commands, smart mode banner, offline detection |
| `tests/test_journal_ui.py` | 50 lines | Validates static serving and presence of all key UI elements |

### Files Unchanged

No modifications to any existing Python files. The static mount was already configured in `thoth/main.py` (Phase 1).

---

## UI Architecture

### Layout

```
┌──────────────┬─────────────────────────────────────────┐
│   Sidebar    │  Toolbar (title, tags, mode, save)      │
│              ├────────────────────┬────────────────────│
│  Search      │                    │                    │
│  Entry List  │   Editor Pane      │   Preview Pane     │
│              │   (textarea)       │   (rendered HTML)  │
│              │                    │                    │
│              │                    │                    │
│  ──────────  ├────────────────────┴────────────────────│
│  New | Sync  │  Status Bar (connection, branch, words) │
│  | Settings  │                                         │
└──────────────┴─────────────────────────────────────────┘
```

### Design Tokens

TurtleShell dark theme implemented via CSS custom properties:

| Token | Value | Usage |
|-------|-------|-------|
| `--bg-primary` | `#0d1117` | Body background |
| `--bg-secondary` | `#161b22` | Sidebar, toolbar, status bar |
| `--bg-tertiary` | `#21262d` | Inputs, code blocks, buttons |
| `--accent` | `#2e8b57` | Thoth green — buttons, links, active states |
| `--text-primary` | `#e6edf3` | Body text |
| `--text-secondary` | `#8b949e` | Labels, descriptions |
| `--text-muted` | `#6e7681` | Timestamps, placeholders |
| `--danger` | `#f85149` | Errors, offline banner |
| `--warning` | `#d29922` | Unsynced badges |

---

## Feature Inventory

### Task 3.1 — HTML Skeleton
- Responsive flexbox layout with sidebar + main area
- Mobile breakpoint at 768px: sidebar and preview pane hide, toggleable
- All CSS inline (no external stylesheet beyond CodeMirror's)

### Task 3.2 — Markdown Editor
- Primary: `<textarea>` with monospace font
- CodeMirror 6 CDN script tags included with `onerror` fallback detection (`window._cmFailed`)
- Textarea works fully offline without CDN

### Task 3.3 — Live Preview
- marked.js (v12, CDN) renders Markdown to HTML
- 300ms debounce on input events
- Fallback to `<pre>` escaped text if marked.js unavailable
- Full styling for: headings, code blocks, blockquotes, tables, lists, links, images

### Task 3.4 — Slash Commands
- `/title <text>` — sets the title input, removes the command line from editor
- `/tag <text>` — appends to tags input (comma-separated), removes command line
- `/mode <auto_merge|pr|smart>` — sets the mode dropdown, validates input
- Processed on Enter keypress, with toast confirmation

### Task 3.5 — Save Flow
- `POST /journal/entry` with title, content, tags, mode
- Button shows "Saving..." during request
- Toast notification on success (shows path and mode) or failure
- Clears draft on successful save
- Reloads entry list after save

### Task 3.6 — Entry Sidebar
- Fetches `GET /journal/entries` on load
- Renders entry items with title, date, tags
- Click to open: fetches `GET /journal/entry/{path}`, strips frontmatter, populates editor
- Active entry highlighted with accent border
- Empty state: "No entries yet" message

### Task 3.7 — Search
- Input with 300ms debounce
- Calls `GET /journal/search?q=` and filters sidebar to matching entries
- Deduplicates results by path
- Clearing search restores full entry list

### Task 3.8 — Sync Button + Offline Banner
- "Sync" button calls `POST /journal/sync`
- Shows pushed/pulled/conflicts count in toast
- Offline banner (red bar) appears when API calls fail with "Failed to fetch"
- Status dot: green (online) / red (offline)
- Polls `GET /journal/status` every 30 seconds

### Task 3.9 — Settings Panel
- Modal overlay with form fields: repo path, default branch, sync interval, auto-sync toggle
- Saves via `POST /journal/settings`
- Closes on: Cancel button, Save button, Escape key, overlay click

### Task 3.10 — Read Without Auth
- All GET endpoints are unauthenticated (Invariant 5)
- Entry list, search, status, and entry reading work without a session

### Task 3.11 — Draft Auto-Save
- Saves to `sessionStorage` on every keystroke
- Stores: title, tags, content, mode, timestamp
- Restores on page load if no active entry and draft is < 24 hours old
- Cleared on successful save
- Status bar shows "Draft saved" briefly after each auto-save

### Task 3.12 — Smart Mode Banner
- Appears when smart mode commits to a PR branch
- Shows reason text and three buttons: "Create PR", "Auto-merge", "Dismiss"
- All three buttons dismiss the banner (PR/merge actions are informational for Phase 4)

### Task 3.13 — SeaShell Balance Display
- Placeholder element `#seashell-balance` in the status bar
- Will be populated by Phase 5 (entitlement) when the ledger API exists

---

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl/Cmd + S` | Save entry |
| `Escape` | Close settings panel |
| `Enter` (after slash command) | Process `/title`, `/tag`, `/mode` |

---

## API Integration

| UI Action | API Call | Method |
|-----------|----------|--------|
| Page load | `/journal/entries` | GET |
| Page load | `/journal/status` | GET |
| Page load | `/health` | GET |
| Click entry | `/journal/entry/{path}` | GET |
| Search | `/journal/search?q=` | GET |
| Save | `/journal/entry` | POST |
| Sync | `/journal/sync` | POST |
| Status poll (30s) | `/journal/status` | GET |
| Save settings | `/journal/settings` | POST |

All API calls go through a central `api()` helper that handles JSON serialization, error extraction, and offline detection.

---

## Toast Notification System

Non-blocking notifications appear in the bottom-right corner:

- Green left border for success messages
- Red left border for error messages
- Auto-dismiss after 4 seconds
- Slide-up animation on entry

---

## Responsive Behavior

| Viewport | Layout |
|----------|--------|
| > 768px | Three-column: sidebar + editor + preview |
| ≤ 768px | Editor only. Sidebar toggleable via `.show-sidebar` class. Preview toggleable via `.show-preview` class. |

---

## Dependencies (CDN)

| Library | Version | Purpose | Fallback |
|---------|---------|---------|----------|
| marked.js | 12.x | Markdown → HTML rendering | Raw `<pre>` text |
| CodeMirror 6 | 6.x | Code editor (script tag present but not fully wired — textarea is primary) | `<textarea>` (fully functional) |

Both CDN scripts have `onerror` handlers that set flags. The application works fully offline with the textarea + escaped text fallback.

---

## What Was NOT Done

- **CodeMirror 6 full integration**: The CDN script tags are included and load checks are in place, but the editor is not fully initialized as a CodeMirror instance. The textarea works well for MVP. Full CodeMirror initialization (with markdown syntax highlighting, keybindings, and theme) can be added without changing the HTML structure — the `#editor-pane` container is ready.
- **Unsynced badges on entries**: The `.unsynced-badge` CSS class exists but the entry list does not yet compare local vs remote state to show which entries need syncing. Requires `GET /journal/status` to return per-entry sync info.
- **First-load setup flow**: Settings panel opens but doesn't detect first-run. A setup wizard could check if the repo path exists and guide configuration.
- **SeaShell balance population**: Placeholder ready. Needs Phase 5 ledger endpoint.

---

## Test Results

```
44 passed in 2.68s

Phase 1 tests:  16 passed
Phase 2 tests:  26 passed
Phase 3 tests:   2 passed (NEW)
  test_journal_html_served         — static mount returns HTML
  test_journal_html_contains_key_elements — all UI components present
```

---

## Exit Criteria

| Criterion | Status |
|-----------|--------|
| Open `journal.html` in browser | ✓ Served at `/static/journal.html` |
| Write entry in editor | ✓ Textarea with markdown, live preview |
| Save entry | ✓ POST → toast → entry list refresh |
| See entry in sidebar | ✓ Entry list with title, date, tags |
| Click to load entry | ✓ Strips frontmatter, populates editor |
| Search entries | ✓ Debounced search → filtered sidebar |
| Sync to GitHub | ✓ Sync button with status toast |
| Works offline | ✓ Textarea + escaped preview, offline banner |
| Settings configurable | ✓ Modal with repo path, branch, interval, auto-sync |
| Draft auto-save | ✓ sessionStorage, 24h expiry, restore on load |
| Slash commands | ✓ `/title`, `/tag`, `/mode` |
| Smart mode banner | ✓ Shows when smart → PR, three dismiss options |
| Responsive layout | ✓ Collapses sidebar + preview on mobile |
| All previous tests pass | ✓ 44/44 |

---

## Invariants Upheld

| # | Invariant | How |
|---|-----------|-----|
| 3 | No hidden state outside user-controlled systems | Drafts in browser sessionStorage (user's device), all entries in user's git repo |
| 4 | All LLM output optional | Journal UI is fully functional without Claude — pure read/write to git |
| 5 | Reads are never metered | All GET calls (entries, search, status) are free and unauthenticated |
| 9 | GitHub is sync, not primary | Sync is an explicit button click — all editing is local-first |

---

## Next: Phase 4 — Code Agent + Webhooks

Phase 4 builds GitHub integration and webhook processing:

| Task | File | What It Does |
|------|------|-------------|
| 4.1 | `thoth/github/client.py` | PyGitHub wrapper, rate limit handling, exponential backoff |
| 4.2 | `thoth/github/diff.py` | File-based diff chunking |
| 4.3 | `thoth/llm/code_review.py` | Diff → Claude → structured review output, `dry_run` support |
| 4.4 | `thoth/github/pr.py` | Create PR, post review comments |
| 4.5 | `thoth/github/branches.py` | Create feature branches |
| 4.6 | `thoth/routes/github.py` | `POST /github/review`, `/github/branch`, `/github/pr` |
| 4.7 | `thoth/routes/webhook.py` | HMAC validation, replay protection, 202 + BackgroundTask |
| 4.8 | `thoth/webhooks/jobs.py` | SQLite job persistence, status recovery |
| 4.9 | `thoth/webhooks/github_actions.py` | `pull_request`, `workflow_run` event handlers |
| 4.10 | `thoth/webhooks/github_actions.py` | LLM cost guards: per-event limits, cooldown, daily cap |
| 4.11 | `.github/workflows/thoth-review.yml` | GitHub Actions workflow template |
| 4.12 | `tests/` | Webhook HMAC, replay, review format, diff chunking |

**Exit criteria:** PR review works (dry_run and live). Webhook receives event, returns 202, processes in background. Job persisted to SQLite.

---

*Phase 3 Implementation Summary — Thoth Coding Agent — 2026-03-23*
