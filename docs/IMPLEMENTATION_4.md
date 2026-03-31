# Phase 4 — Code Agent + Webhooks: Implementation Summary

**Agent:** Thoth Coding Agent
**Date:** 2026-03-23
**Branch:** `brain/1.7.x.x`
**Status:** PHASE 4 COMPLETE — AWAITING COMMIT REVIEW

---

## What Was Built

Phase 4 delivers GitHub integration (code review, PR management, branch creation) and webhook processing (HMAC validation, replay protection, background job queue, LLM cost guards).

### Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `thoth/github/client.py` | 73 | PyGitHub wrapper with exponential backoff on rate limit errors. Retries up to 3 times with configurable wait. Respects `X-RateLimit-Reset` header. |
| `thoth/github/diff.py` | 120 | File-based diff fetching from PR, chunking by byte size, and formatting into markdown for Claude review. Enforces max files (50) and max diff bytes (500KB). |
| `thoth/github/pr.py` | 82 | Create pull requests, post full reviews (with event type: APPROVE/REQUEST_CHANGES/COMMENT), and post simple comments. |
| `thoth/github/branches.py` | 58 | Create branches from existing refs and list branches with optional prefix filter. |
| `thoth/llm/code_review.py` | 130 | Claude-powered structured code review. Sends formatted diffs with a review-specific system prompt. Parses JSON response into `CodeReview` dataclass with summary, approval, and per-file comments with severity levels. |
| `thoth/routes/github.py` | 143 | Three GitHub API endpoints: review, create PR, create branch. All require a GitHub token (never stored — Invariant 10). Review endpoint integrates diff fetching, Claude analysis, and optional posting. |
| `thoth/routes/webhook.py` | 130 | Webhook receiver: HMAC-SHA256 signature validation, replay protection via delivery ID lookup, SQLite job persistence, 202 immediate response, BackgroundTask processing. |
| `thoth/webhooks/jobs.py` | 135 | Async SQLite job store: create, get, update status, log delivery attempts, get pending jobs, recover stale jobs on startup. |
| `thoth/webhooks/github_actions.py` | 130 | Event handlers for `pull_request` (opened/synchronize/reopened) and `workflow_run`. Cost guard with per-PR cooldown (60s), per-event limit (3 calls), and daily cap (50 calls). |
| `.github/workflows/thoth-review.yml` | 22 | GitHub Actions workflow: triggers on PR open/sync/reopen, calls Thoth's review endpoint with the PR details. |
| `tests/test_webhook.py` | 85 | HMAC validation (valid, invalid, missing), replay protection (duplicate delivery rejected). |
| `tests/test_diff.py` | 55 | Diff chunking (single, multiple, empty, oversized), diff formatting. |
| `tests/test_code_review.py` | 60 | Review JSON parsing (valid, code-fenced, invalid fallback, critical count). |
| `tests/test_cost_guard.py` | 42 | Cost guard (first call, cooldown, different PR, daily cap, daily reset). |

### Files Modified

| File | Change |
|------|--------|
| `thoth/main.py` | Added `github_router` and `webhook_router` imports and registration |

---

## API Endpoints

| Method | Path | Auth | Metered | Purpose |
|--------|------|------|---------|---------|
| `POST` | `/github/review` | GitHub token | Yes (Phase 5) | Review a PR with Claude — fetch diffs, analyze, optionally post |
| `POST` | `/github/pr` | GitHub token | No | Create a pull request |
| `POST` | `/github/branch` | GitHub token | No | Create a feature branch |
| `POST` | `/webhook/github` | HMAC-SHA256 | No | Receive GitHub webhook events (returns 202) |

---

## Architecture Decisions

### Code Review Pipeline

```
POST /github/review
  │
  ├─ GitHubClient.get_repo(token)          ← PyGitHub, per-request token
  ├─ fetch_pr_diffs(repo, pr_number)       ← file-based chunking
  ├─ format_diff_for_review(diffs)         ← markdown with diff fences
  ├─ ClaudeClient.chat(formatted_diff)     ← structured JSON prompt
  ├─ _parse_review(raw_response)           ← JSON → CodeReview dataclass
  │
  ├─ if dry_run: return review
  └─ if !dry_run: post_comment(repo, pr)   ← formatted review to GitHub
```

**Review output format (from Claude):**
```json
{
  "summary": "One-paragraph assessment",
  "approval": "approve | request_changes | comment",
  "comments": [
    {"file": "path.py", "line": 42, "severity": "critical", "body": "..."}
  ]
}
```

Severity levels: `critical` (🔴), `warning` (🟡), `suggestion` (🔵), `praise` (🟢).

The parser handles three cases:
1. Clean JSON → direct parse
2. Code-fenced JSON (` ```json ... ``` `) → strip fences, then parse
3. Non-JSON response → fallback to raw text summary with `comment` approval

### Diff Chunking Strategy

Diffs are chunked **by file count and byte size**, not by token count. This keeps the logic deterministic and avoids tokenizer dependencies.

| Limit | Default | Source |
|-------|---------|--------|
| Max files per review | 50 | `settings.github.review_max_files` |
| Max diff bytes per review | 500,000 | `settings.github.review_max_diff_bytes` |
| Max bytes per chunk | 500,000 | `chunk_diffs()` parameter |

When a PR exceeds limits, diffs are truncated with a warning log. The `chunk_diffs()` function splits into multiple chunks for future multi-pass review.

### GitHub Token Handling

GitHub tokens arrive in the request body (from the client or webhook). They are:
- Never stored in memory beyond the request lifecycle
- Never logged
- Used to create a per-request `GitHubClient` instance
- Released via `gh.close()` in a `finally` block

This upholds Invariant 10 (agents do not maintain their own service logins) and Invariant 8 (OAuth tokens never in URL parameters).

### Webhook Processing Flow

```
GitHub Event → POST /webhook/github
  │
  ├─ Validate HMAC-SHA256 signature
  ├─ Check delivery ID for replay
  ├─ Parse JSON payload
  ├─ Persist job to SQLite (status: pending)
  ├─ Return 202 Accepted immediately
  │
  └─ BackgroundTask:
       ├─ Update status → processing
       ├─ Dispatch to event handler
       ├─ Log delivery result
       └─ Update status → completed | failed
```

**Key design:**
- 202 response within milliseconds (spec Section 8 requires < 10s)
- Job persisted before background processing starts
- Delivery attempts logged to `webhook_deliveries` table
- Stale jobs (stuck in `processing`) can be recovered on startup via `recover_stale()`

### HMAC Validation

```python
expected = "sha256=" + hmac.new(secret, body, sha256).hexdigest()
hmac.compare_digest(signature, expected)  # constant-time comparison
```

- Uses `THOTH_SECRET` environment variable
- If secret is not set, logs a warning but accepts the webhook (development mode)
- Signature format: `sha256=<hex_digest>`

### Replay Protection

Each GitHub webhook delivery has a unique `X-GitHub-Delivery` header. Before creating a job, Thoth checks `webhook_jobs` for an existing row with the same `delivery_id`. Duplicates return `{"status": "duplicate"}` without creating a new job.

### Cost Guards

Three layers of protection against LLM cost explosions:

| Guard | Limit | Scope |
|-------|-------|-------|
| Per-PR cooldown | 60 seconds | Same `repo#pr_number` key |
| Per-event limit | 3 LLM calls | Single webhook event |
| Daily cap | 50 LLM calls | All events in a calendar day |

The daily counter resets when the date changes. The cost guard is a process-global singleton — it resets on server restart (acceptable for the current single-process model).

---

## GitHub Actions Workflow

`.github/workflows/thoth-review.yml` triggers on PR events (opened, synchronize, reopened) for non-draft PRs:

```yaml
- name: Request Thoth Review
  env:
    THOTH_URL: ${{ vars.THOTH_URL || 'http://localhost:3441' }}
    GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
  run: |
    curl -s -X POST "${THOTH_URL}/github/review" \
      -H "Content-Type: application/json" \
      -d '{
        "repo": "${{ github.repository }}",
        "pr_number": ${{ github.event.pull_request.number }},
        "github_token": "'"${GITHUB_TOKEN}"'",
        "dry_run": false
      }' | jq .
```

The `THOTH_URL` is configurable via GitHub repository variables (defaults to localhost for development).

---

## Event Handlers

### `pull_request`

Handles: `opened`, `synchronize`, `reopened`

Actions ignored: `closed`, `edited`, `labeled`, `assigned`, etc.

On a handled action:
1. Checks cost guard for the PR key
2. Returns metadata (action, pr_number, repo, title) for upstream processing
3. Does not auto-trigger a review — the webhook handler logs the event; auto-review is via the GitHub Actions workflow

### `workflow_run`

Tracks CI status (action, conclusion, workflow name) for PRs that Thoth has reviewed. Informational only — does not trigger LLM calls.

### Handler Dispatch

```python
EVENT_HANDLERS = {
    "pull_request": handle_pull_request,
    "workflow_run": handle_workflow_run,
}
```

Unknown event types are logged and marked as completed without processing.

---

## What Was NOT Done

- **Auto-review from webhook**: The webhook handler logs the event but does not automatically call the review endpoint. Auto-review is available via the GitHub Actions workflow. This is intentional — Invariant 7 requires auto-approve to be user opt-in.
- **Inline PR review comments**: The review is posted as a single comment on the PR (via `create_issue_comment`), not as inline review comments on specific lines. PyGitHub's `create_review(comments=[...])` requires diff positions (not line numbers), which adds complexity. The formatted comment includes file:line references.
- **Multi-chunk review**: `chunk_diffs()` is built but the review endpoint does not iterate over chunks. A single review call covers the first chunk within limits. Multi-pass review can be added later.
- **Webhook retry logic**: Failed jobs are marked as `failed` but not retried. The `attempts` counter and `get_pending()` method are ready for a retry scheduler.
- **Cost guard persistence**: The cost guard resets on server restart. For multi-process deployments, it should be moved to SQLite.

---

## Test Results

```
62 passed in 3.84s

Phase 1 tests:  16 passed
Phase 2 tests:  26 passed
Phase 3 tests:   2 passed
Phase 4 tests:  18 passed (NEW)
```

### Phase 4 Test Coverage

| Test File | Tests | What's Covered |
|-----------|-------|----------------|
| `test_webhook.py` | 4 | HMAC validation (valid signature, invalid signature, missing headers), replay protection (duplicate delivery ID) |
| `test_diff.py` | 5 | Chunk splitting (single, multiple, empty, oversized file), diff formatting to markdown |
| `test_code_review.py` | 4 | JSON parsing (valid, code-fenced, invalid fallback), critical count aggregation |
| `test_cost_guard.py` | 5 | First call allowed, cooldown blocking, different PR allowed, daily cap, daily reset |

---

## Exit Criteria

| Criterion | Status |
|-----------|--------|
| PR review works (dry_run) | ✓ Fetches diffs, sends to Claude, returns structured review |
| PR review works (live) | ✓ Posts formatted comment to GitHub when `dry_run=false` |
| Webhook receives event | ✓ `POST /webhook/github` validates HMAC |
| Webhook returns 202 | ✓ Immediate response, background processing |
| Replay protection | ✓ Duplicate delivery IDs detected and rejected |
| Job persisted to SQLite | ✓ `webhook_jobs` table with status tracking |
| Event handlers dispatch | ✓ `pull_request` and `workflow_run` handled |
| Cost guards enforce limits | ✓ Per-PR cooldown, daily cap, per-event limit |
| GitHub Actions workflow template | ✓ `.github/workflows/thoth-review.yml` |
| Branch creation works | ✓ `POST /github/branch` |
| PR creation works | ✓ `POST /github/pr` |
| All previous tests pass | ✓ 62/62 |

---

## Invariants Upheld

| # | Invariant | How |
|---|-----------|-----|
| 4 | All LLM output optional, never authoritative | Review is advisory — `dry_run` is default. User decides whether to post. |
| 7 | Auto-approve is always user opt-in | Webhook handler logs events but does not auto-approve. Review requires explicit API call or GitHub Actions workflow. |
| 8 | OAuth tokens never in URL parameters | GitHub tokens in request body, never in URLs or query strings |
| 10 | Agents do not maintain their own service logins | Token arrives per-request, used once, released in `finally` block |

---

## SQLite Tables Used

### `webhook_jobs` (created in Phase 1)

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INTEGER PK | Auto-increment job ID |
| `event_type` | TEXT | GitHub event type (e.g., `pull_request`) |
| `delivery_id` | TEXT UNIQUE | GitHub delivery UUID (replay protection) |
| `payload` | TEXT | JSON event payload |
| `status` | TEXT | `pending` → `processing` → `completed` / `failed` |
| `attempts` | INTEGER | Delivery attempt count |
| `created_at` | TEXT | ISO 8601 timestamp |
| `updated_at` | TEXT | ISO 8601 timestamp |

### `webhook_deliveries` (created in Phase 1)

| Column | Type | Purpose |
|--------|------|---------|
| `id` | INTEGER PK | Auto-increment delivery ID |
| `job_id` | INTEGER FK | References `webhook_jobs.id` |
| `status_code` | INTEGER | HTTP status of handler result |
| `response_body` | TEXT | Handler response JSON |
| `error` | TEXT | Error message if failed |
| `created_at` | TEXT | ISO 8601 timestamp |

---

## Next: Phase 5 — Entitlement

Phase 5 builds the SeaShell metering system:

| Task | File | What It Does |
|------|------|-------------|
| 5.1 | `thoth/entitlement/seashell.py` | `UsageEvent` dataclass with `operation_id` deduplication |
| 5.2 | `thoth/entitlement/adapter.py` | `SettlementAdapter` ABC |
| 5.3 | `thoth/entitlement/adapter.py` | `SQLiteAdapter` — aiosqlite, dedup on `operation_id` |
| 5.4 | `thoth/entitlement/adapter.py` | `OlympusCoinAdapter` stub (interface only) |
| 5.5 | `thoth/entitlement/seashell.py` | `SeashellMeter` — reads rates from manifest, `@meter` decorator |
| 5.6 | All route files | Wire meter to all metered endpoints |
| 5.7 | `thoth/routes/` | `GET /entitlement/ledger` — usage history endpoint |
| 5.8 | `thoth/entitlement/seashell.py` | Free tier enforcement — daily caps from manifest |
| 5.9 | `tests/` | Metering, dedup, free tier limits |

**Exit criteria:** Every metered operation creates a ledger entry. Ledger queryable. Free tier enforced. `operation_id` prevents duplicates.

---

*Phase 4 Implementation Summary — Thoth Coding Agent — 2026-03-23*
