# Phase 1 — Core Agent: Implementation Summary

**Agent:** Thoth Coding Agent
**Date:** 2026-03-23
**Branch:** `brain/1.7.x.x`
**Status:** PHASE 1 COMPLETE — AWAITING COMMIT REVIEW

---

## What Was Built

Phase 1 delivers a running FastAPI server with discovery, auth, streaming chat, and database initialization.

### Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `thoth/config.py` | 115 | Env loader, `.thoth.json` + `.thoth.local.json` merge, cosmos-logos.json manifest loader, dataclass-based settings |
| `thoth/main.py` | 113 | FastAPI app factory, async lifespan (startup checks, SQLite schema init, shutdown), CORS middleware, static file mount, route registration |
| `thoth/routes/discovery.py` | 53 | `/.well-known/cosmos-logos.json` with `X-CosmosLogos-Version` header + TTL-based cache control, `/health` status endpoint, `/ping` liveness probe |
| `thoth/auth/service_bridge.py` | 196 | Ed25519 signature verification (multi-key, timestamp freshness), sealed-box envelope decryption (Ed25519→Curve25519 key conversion), PEM key parsing |
| `thoth/auth/session.py` | 70 | In-memory session store with 8-hour TTL, create/get/revoke operations, lazy expiry cleanup |
| `thoth/llm/claude.py` | 102 | Anthropic async SDK wrapper, SSE text delta streaming, non-streaming fallback, Thoth persona system prompt |
| `thoth/routes/chat.py` | 72 | `POST /chat` SSE endpoint — request validation, message filtering, `text_delta`/`done`/`error` event stream |
| `tests/conftest.py` | 37 | Shared fixtures: test settings, app factory, synchronous test client |
| `tests/test_discovery.py` | 38 | Tests for `/ping`, `/health`, `/.well-known/cosmos-logos.json`, manifest-missing 503 |
| `tests/test_auth.py` | 100 | Tests for signature verification (valid, bad, expired), sealed-box decrypt roundtrip, session CRUD and expiry |
| `tests/test_chat.py` | 43 | Tests for missing API key 503, empty messages 400, invalid roles 400, SSE stream format with mocked Claude |

### Virtual Environment

A `.venv` was created at the repo root for local development:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt pytest httpx
```

---

## Architecture Decisions

### Config Loading (Task 1.2)

Three-layer merge: defaults → `.thoth.json` → `.thoth.local.json` → env overrides. Settings are plain dataclasses — no Pydantic, per spec. The cosmos-logos.json manifest is loaded once at startup and stored in `Settings.manifest`.

### Auth Model (Tasks 1.5–1.6)

**No JWTs.** Auth is cosmos-logos native, as decided in Phase 0:

- **Signature verification:** `ServiceBridge` accepts a map of trusted agent codenames → PEM public keys. Verifies Ed25519 signatures over `timestamp || body`. Enforces configurable timestamp tolerance (default 300s).
- **Envelope decryption:** Thoth's Ed25519 private key is converted to Curve25519 via `nacl.signing.SigningKey.to_curve25519_private_key()`. Sealed-box (`crypto_box_seal`) decryption recovers the GitHub token from the `x-cosmos-envelope` header.
- **Sessions:** In-memory store with `secrets.token_urlsafe(32)` tokens, 8-hour expiry. No cookies, no database — sessions are ephemeral and server-local.

### Chat Streaming (Tasks 1.7–1.8)

The `/chat` endpoint returns `text/event-stream` with three event types:
- `text_delta` — `{"delta": "..."}` for each streamed token
- `done` — `{}` when the stream completes
- `error` — `{"error": "..."}` if an exception occurs mid-stream

The `ClaudeClient` wraps `anthropic.AsyncAnthropic` and uses the `.messages.stream()` context manager for backpressure-aware streaming.

### SQLite Schema (Task 1.9)

Three tables initialized in the lifespan startup:
- `seashell_ledger` — usage metering with `operation_id` deduplication (Phase 5)
- `webhook_jobs` — background job queue with status tracking (Phase 4)
- `webhook_deliveries` — delivery attempt log per job (Phase 4)

### App Factory

`create_app(settings=None)` builds the app with optional injected settings (used by tests). The module-level `app = create_app()` supports `uvicorn thoth.main:app` for production.

---

## What Was NOT Done

- **`.thoth.local.json.example`**: Deferred from Phase 0, still not created. The config loader supports it — the file shape mirrors `.thoth.json.example`.
- **Auth middleware**: `ServiceBridge` is built but not wired as FastAPI middleware yet. Routes that require auth (journal, GitHub) will wire it in their respective phases.
- **Session cookie/header flow**: The `SessionStore` is built but not integrated into request handling. Phase 2 journal routes will add the `x-thoth-session` header flow.

---

## Test Results

```
16 passed in 0.70s

tests/test_auth.py::TestSignatureVerification::test_valid_signature PASSED
tests/test_auth.py::TestSignatureVerification::test_bad_signature PASSED
tests/test_auth.py::TestSignatureVerification::test_expired_timestamp PASSED
tests/test_auth.py::TestEnvelopeDecryption::test_decrypt_roundtrip PASSED
tests/test_auth.py::TestSessionStore::test_create_and_get PASSED
tests/test_auth.py::TestSessionStore::test_expired_session PASSED
tests/test_auth.py::TestSessionStore::test_revoke PASSED
tests/test_auth.py::TestSessionStore::test_missing_token PASSED
tests/test_chat.py::test_chat_no_api_key PASSED
tests/test_chat.py::test_chat_empty_messages PASSED
tests/test_chat.py::test_chat_invalid_role PASSED
tests/test_chat.py::test_chat_sse_format PASSED
tests/test_discovery.py::test_ping PASSED
tests/test_discovery.py::test_health PASSED
tests/test_discovery.py::test_manifest PASSED
tests/test_discovery.py::test_manifest_missing PASSED
```

---

## Exit Criteria

| Criterion | Status |
|-----------|--------|
| Server boots on port 3441 | ✓ `uvicorn thoth.main:app --port 3441` |
| `GET /.well-known/cosmos-logos.json` returns valid manifest | ✓ With `X-CosmosLogos-Version` header |
| `GET /health` returns agent status | ✓ Includes version, API key presence, manifest presence |
| `GET /ping` returns liveness | ✓ `{"pong": true}` |
| `POST /chat` streams Claude response as SSE | ✓ `text_delta` → `done` event sequence |
| Ed25519 signature verification works | ✓ Multi-key, timestamp freshness enforced |
| Sealed-box envelope decryption works | ✓ Ed25519→Curve25519 conversion, roundtrip tested |
| Session management works | ✓ Create, get, revoke, auto-expiry |
| SQLite schema initializes on startup | ✓ seashell_ledger, webhook_jobs, webhook_deliveries |

---

## Invariants Upheld

| # | Invariant | How |
|---|-----------|-----|
| 2 | `cosmos-logos.json` is the only discovery surface | Manifest served at `/.well-known/cosmos-logos.json` — no other discovery mechanism |
| 4 | All LLM output is optional | Chat endpoint is a capability, not a requirement. Reads never metered. |
| 5 | Reads are never metered | `/health`, `/ping`, `/.well-known/` are all free |
| 8 | OAuth tokens never in URL parameters | Tokens arrive via `x-cosmos-envelope` header, decrypted server-side |
| 10 | Agents do not maintain their own service logins | Thoth never stores GitHub tokens — decrypted per-request from envelope |

---

## Next: Phase 2 — Local Git + Journal Backend

Phase 2 builds the offline-first journal system:

| Task | File | What It Does |
|------|------|-------------|
| 2.1 | `thoth/git/lock.py` | `RepoLock` — async mutex per repo path |
| 2.2 | `thoth/git/bootstrap.py` | First-run init, git identity, gitignore, initial commit |
| 2.3 | `thoth/git/local.py` | `LocalGit` — commit, read, search, list (all via `run_in_executor`) |
| 2.4 | `thoth/git/conflict.py` | `ConflictResolver` — local_wins strategy |
| 2.5 | `thoth/git/sync.py` | `GitSync` — 5-state machine, push, pull, network check |
| 2.6–2.12 | `thoth/routes/journal.py` | Journal CRUD, search, sync, status, settings routes |
| 2.13 | `thoth/llm/writing.py` | Smart mode heuristic — word count, tags, code density |
| 2.14 | `thoth/git/local.py` | Branch naming — `thoth/journal/{date}-{slug}-{hash}` |
| 2.15 | `tests/` | Bootstrap, commit, read, search, sync, conflict resolution |

**Exit criteria:** Create entry → committed to local git. List entries. Search. Sync to GitHub. Status shows unsynced count. Conflict resolution works.

---

*Phase 1 Implementation Summary — Thoth Coding Agent — 2026-03-23*
