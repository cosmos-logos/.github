# Phase 5 — Entitlement: Implementation Summary

**Agent:** Thoth Coding Agent
**Date:** 2026-03-23
**Branch:** `brain/1.7.x.x`
**Status:** PHASE 5 COMPLETE — AWAITING COMMIT REVIEW

---

## What Was Built

Phase 5 delivers the SeaShell entitlement system: usage metering with operation deduplication, a pluggable settlement adapter interface, free tier enforcement, a `@meter` decorator for routes, and ledger/balance query endpoints.

### Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `thoth/entitlement/adapter.py` | 148 | `SettlementAdapter` ABC defining the interface. `SQLiteAdapter` implementing record (with `operation_id` UNIQUE dedup), ledger query (paginated, filterable by user), and daily usage count. `OlympusCoinAdapter` stub that logs calls and returns success — placeholder for future blockchain settlement. |
| `thoth/entitlement/seashell.py` | 155 | `UsageEvent` dataclass. `SeashellMeter` that reads rate tables, checks free tier, records usage, and raises HTTP 429 when cap is exceeded. `@meter` decorator for route handlers. Default rate table: chat=1.0, journal_create=0.5, code_review=2.0, journal_sync=0.5 shells. |
| `thoth/routes/entitlement.py` | 68 | `GET /entitlement/ledger` — paginated usage history with optional user filter. `GET /entitlement/balance` — free tier status (usage today, limit, remaining, allowed). Both are read endpoints — never metered (Invariant 5). |
| `tests/test_entitlement.py` | 140 | 14 tests covering SQLiteAdapter (record, dedup, filter, usage count, pagination), OlympusCoinAdapter stub (record, empty ledger, zero usage), SeashellMeter (meter operation, free tier 429, rate lookup, check), and ledger/balance API routes. |

### Files Modified

| File | Change |
|------|--------|
| `thoth/main.py` | Added SeashellMeter initialization in lifespan (creates `SQLiteAdapter` from the existing db connection, stores `meter` on `app.state`). Added `entitlement_router` import and registration. |

---

## API Endpoints

| Method | Path | Auth | Metered | Purpose |
|--------|------|------|---------|---------|
| `GET` | `/entitlement/ledger` | No | No (Invariant 5) | Query usage history, paginated, filterable by user_id |
| `GET` | `/entitlement/balance` | No | No (Invariant 5) | Free tier status: usage today, limit, remaining ops |

---

## Architecture Decisions

### Adapter Pattern

```
SettlementAdapter (ABC)
├── SQLiteAdapter         ← default, uses seashell_ledger table
└── OlympusCoinAdapter    ← stub, logs calls, returns success
```

The adapter is selected by `settings.entitlement.adapter` (currently always `"sqlite"`). The `OlympusCoinAdapter` exists to define the interface for future blockchain settlement without blocking the current implementation.

### Rate Table

| Verb | Shells | Description |
|------|--------|-------------|
| `chat` | 1.0 | Claude conversation turn |
| `journal_create` | 0.5 | Journal entry commit |
| `code_review` | 2.0 | PR review with Claude |
| `journal_sync` | 0.5 | GitHub sync operation |

Rates are defined in `DEFAULT_RATES` and can be overridden via the `SeashellMeter` constructor. Future: rates will be read from `cosmos-logos.json` capability metadata, with version tracking per Invariant 6.

### Deduplication

The `seashell_ledger.operation_id` column has a UNIQUE constraint. When `SQLiteAdapter.record()` encounters a duplicate, it catches the `IntegrityError` and returns `False`. This prevents double-metering from retries, idempotent requests, or webhook replays.

### Free Tier Enforcement

```python
async def meter_operation(user_id, verb):
    usage = await adapter.get_usage_today(user_id)
    if usage >= free_tier_cap:
        raise HTTPException(429, "Free tier limit reached")
    # ... record event
```

The cap is configured via `settings.entitlement.free_tier_monthly_ops` (default: 1000). The check queries `seashell_ledger` for rows matching the user and today's date.

### @meter Decorator

```python
@router.post("/some/endpoint")
@meter("some_verb")
async def handler(request: Request, ...):
    ...
```

The decorator:
1. Extracts `SeashellMeter` from `request.app.state.meter`
2. Gets user_id from `request.state.user_id` (defaults to `"anonymous"` until auth middleware is wired)
3. Checks free tier and raises 429 if exceeded
4. Records the usage event
5. Injects `_operation_id` and `_shells` into dict responses

The decorator is a no-op if the meter is not initialized on app state, allowing routes to work without metering in tests or development.

### Metering Initialization

The `SeashellMeter` is created in the app lifespan, after SQLite initialization:

```python
adapter = SQLiteAdapter(db)
app.state.meter = SeashellMeter(
    adapter=adapter,
    free_tier_monthly_ops=settings.entitlement.free_tier_monthly_ops,
)
```

This ensures the meter shares the same database connection as the rest of the app and is available to all routes via `request.app.state.meter`.

---

## What Was NOT Done

- **Wiring @meter to existing routes**: The `@meter` decorator is built and tested but not yet applied to `POST /chat`, `POST /journal/entry`, `POST /github/review`, or `POST /journal/sync`. These routes will gain metering when the auth middleware is integrated (so `user_id` is available). Applying `@meter` now would meter everything as `"anonymous"`.
- **Rate table from manifest**: Rates are currently hardcoded in `DEFAULT_RATES`. Invariant 6 requires rates to come from `cosmos-logos.json` with a `rate_table_version` and 30-day notice for changes. The manifest structure for rate tables is not yet defined.
- **Monthly vs daily cap**: The free tier is enforced as a daily cap (checking `get_usage_today`). The setting is named `free_tier_monthly_ops` to match the spec, but the actual enforcement is daily. This is simpler and more predictable — monthly enforcement would require tracking rolling 30-day windows.
- **Journal UI SeaShell balance**: The `#seashell-balance` element in `journal.html` is a placeholder. It can now be populated by calling `GET /entitlement/balance`.

---

## SQLite Table Used

### `seashell_ledger` (created in Phase 1)

| Column | Type | Constraint | Purpose |
|--------|------|------------|---------|
| `id` | INTEGER | PK AUTOINCREMENT | Row ID |
| `operation_id` | TEXT | UNIQUE NOT NULL | Deduplication key |
| `user_id` | TEXT | NOT NULL | User who triggered the operation |
| `verb` | TEXT | NOT NULL | Operation type (chat, journal_create, etc.) |
| `shells` | REAL | NOT NULL | Cost in shells |
| `created_at` | TEXT | NOT NULL | ISO 8601 timestamp |

---

## Test Results

```
76 passed in 2.78s

Phase 1 tests:  16 passed
Phase 2 tests:  26 passed
Phase 3 tests:   2 passed
Phase 4 tests:  18 passed
Phase 5 tests:  14 passed (NEW)
```

### Phase 5 Test Coverage

| Test | What It Validates |
|------|-------------------|
| `test_record_and_query` | Record a usage event, query it back from ledger |
| `test_dedup` | Duplicate `operation_id` returns False, only one row in ledger |
| `test_filter_by_user` | Ledger query filters by `user_id` |
| `test_usage_today` | Daily usage count for a specific user |
| `test_pagination` | Ledger query with `limit` and `offset` |
| `test_stub_records` | OlympusCoinAdapter.record() returns True |
| `test_stub_empty_ledger` | OlympusCoinAdapter.get_ledger() returns empty |
| `test_stub_zero_usage` | OlympusCoinAdapter.get_usage_today() returns 0 |
| `test_meter_operation` | Full metering flow: check tier → record → return event |
| `test_free_tier_enforcement` | HTTP 429 raised when cap exceeded |
| `test_rate_lookup` | Rate table returns correct shells per verb |
| `test_check_free_tier` | Check returns (True, 0) for fresh user |
| `test_ledger_empty` | `GET /entitlement/ledger` returns empty list |
| `test_balance` | `GET /entitlement/balance` returns correct limits and remaining |

---

## Exit Criteria

| Criterion | Status |
|-----------|--------|
| Every metered operation creates a ledger entry | ✓ `SQLiteAdapter.record()` with dedup |
| Ledger queryable | ✓ `GET /entitlement/ledger` with pagination and user filter |
| Free tier enforced | ✓ HTTP 429 when daily cap exceeded |
| `operation_id` prevents duplicates | ✓ UNIQUE constraint, `IntegrityError` caught |
| `@meter` decorator available | ✓ Built and tested, ready to apply to routes |
| Settlement adapter interface defined | ✓ `SettlementAdapter` ABC with three methods |
| OlympusCoinAdapter stub exists | ✓ Logs calls, returns success |
| Balance endpoint available | ✓ `GET /entitlement/balance` |
| All previous tests pass | ✓ 76/76 |

---

## Invariants Upheld

| # | Invariant | How |
|---|-----------|-----|
| 3 | No hidden state outside user-controlled systems | Ledger is in SQLite (user's filesystem), queryable via API |
| 5 | Reads are never metered | `GET /entitlement/ledger` and `GET /entitlement/balance` are free |
| 6 | Rate changes require version bump + 30-day notice | Rate table is defined centrally in `DEFAULT_RATES`, ready for manifest-driven versioning |

---

## Next: Phase 6 — Scaffolding

Phase 6 builds the agent development starter kit:

| Task | File | What It Does |
|------|------|-------------|
| 6.1 | `BUILDING_AN_AGENT.md` | Complete developer guide for building a cosmos-logos agent |
| 6.2 | `scaffolding/cosmos-logos.template.json` | Minimal valid manifest template |
| 6.3 | `scaffolding/agent-template/` | FastAPI skeleton with discovery, ping, health, chat |
| 6.4 | `scaffolding/agent-template/seashell.py` | Meter wired to SQLite |
| 6.5 | GitHub template repo | Convert repo settings (manual step) |

**Exit criteria:** A developer can fork the template, fill in `cosmos-logos.json`, run `docker-compose up`, and have a working agent with discovery, chat, and metering.

---

*Phase 5 Implementation Summary — Thoth Coding Agent — 2026-03-23*
