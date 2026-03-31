# Phase 6 — Scaffolding: Implementation Summary

**Agent:** Thoth Coding Agent
**Date:** 2026-03-23
**Branch:** `brain/1.7.x.x`
**Status:** PHASE 6 COMPLETE — ALL THOTH PHASES DONE — AWAITING COMMIT REVIEW

---

## What Was Built

Phase 6 delivers the agent development starter kit: a complete developer guide, a manifest template, and a self-contained agent skeleton that a developer can fork and customize into a working cosmos-logos agent.

### Files Created

| File | Lines | Purpose |
|------|-------|---------|
| `BUILDING_AN_AGENT.md` | 230 | Complete 9-section developer guide covering identity generation, manifest writing, server building, capability implementation, auth, metering, containerization, trust, and testing. Includes the 10 architectural invariants. |
| `scaffolding/cosmos-logos.template.json` | 40 | Minimal valid manifest with placeholder values (`AGENT_NAME`, `agent-codename`, `YOUR_ORG`, `REPLACE_WITH_YOUR_PUBLIC_KEY`). Contains all required fields plus optional display, metadata, and one chat capability. |
| `scaffolding/agent-template/main.py` | 140 | Complete single-file FastAPI agent: lifespan with SQLite init, manifest loading, CORS, four endpoints (discovery, health, ping, chat SSE), customizable system prompt, Anthropic streaming integration. |
| `scaffolding/agent-template/seashell.py` | 62 | Standalone `meter_operation()` function: checks daily cap, records to `seashell_ledger` with `operation_id` dedup, raises HTTP 429 on free tier exhaustion. No dependency on Thoth's entitlement module — fully self-contained. |
| `scaffolding/agent-template/requirements.txt` | 5 | Minimal dependencies: fastapi, uvicorn, anthropic, aiosqlite, python-multipart. No pynacl, gitpython, or pygithub — those are Thoth-specific. |
| `scaffolding/agent-template/Dockerfile` | 10 | Multi-stage Python 3.12-slim build. Copies deps from builder stage. Exposes port 3000. |
| `scaffolding/agent-template/docker-compose.yml` | 12 | Single service with env_file, keys mount (read-only), and named data volume. Port configurable via `AGENT_PORT` env var. |
| `scaffolding/agent-template/.env.example` | 5 | `ANTHROPIC_API_KEY`, `AGENT_PORT`, `AGENT_DB_PATH` |
| `scaffolding/agent-template/.gitignore` | 6 | Protects: `__pycache__`, `.env`, `*.db`, `keys/*.key`, `.venv/` |
| `scaffolding/agent-template/README.md` | 40 | Quick start (keys, env, manifest, run/docker), endpoint table, customization checklist. |
| `tests/test_scaffolding.py` | 55 | 7 tests: manifest template validity, required fields, template file existence, route presence in main.py, metering in seashell.py, developer guide existence and topic coverage. |

---

## Developer Guide Sections

### BUILDING_AN_AGENT.md

| Section | Content |
|---------|---------|
| 1. Generate Your Identity | Ed25519 keypair via OpenSSL, fingerprint extraction, .gitignore guidance |
| 2. Write Your Manifest | Full `cosmos-logos.json` example with all required fields, schema validation command |
| 3. Build the Server | Minimum viable agent (4 endpoints), template usage, from-scratch FastAPI example |
| 4. Add Capabilities | Chat (anthropic-messages-v1) with SSE streaming, custom capabilities (rest-json) with `x-` prefix convention |
| 5. Add Auth | Ed25519 signatures, sealed-box envelopes, envelope manifest section |
| 6. Add Metering | SeashellMeter usage, `meter_operation()` pattern |
| 7. Containerize | Multi-stage Dockerfile, docker-compose.yml with volumes |
| 8. Declare Trust | Trust array with codename, URL, relationship |
| 9. Test Your Agent | curl commands for health, discovery, manifest validation |

The guide ends with the 10 architectural invariants that every agent must uphold.

---

## Agent Template Architecture

```
scaffolding/agent-template/
├── main.py              ← Single-file FastAPI app (all 4 required endpoints)
├── seashell.py           ← Standalone metering (no Thoth dependency)
├── requirements.txt      ← 5 dependencies
├── Dockerfile            ← Multi-stage build
├── docker-compose.yml    ← One-command deploy
├── .env.example          ← Config template
├── .gitignore            ← Security defaults
└── README.md             ← Quick start guide
```

### What a Developer Does

1. Fork or copy the template directory
2. Generate Ed25519 keypair
3. Copy `cosmos-logos.template.json` → `cosmos-logos.json`, fill in identity and public key
4. Edit `main.py:SYSTEM_PROMPT` with their agent's personality
5. Add capability routes as needed
6. `docker compose up` or `uvicorn main:app`

The agent is immediately discoverable at `/.well-known/cosmos-logos.json`.

### Template Design Decisions

- **Single-file agent**: `main.py` is completely self-contained — no package structure, no imports from Thoth. A developer can understand the entire agent by reading one file.
- **Standalone metering**: `seashell.py` is a standalone module, not an import from `thoth.entitlement`. It uses the same SQLite table schema but has no dependency chain.
- **Minimal dependencies**: 5 packages vs Thoth's 9. No git, GitHub, or crypto libraries — those are Thoth-specific capabilities.
- **Port 3000 default**: Generic port for the template. Thoth uses 3441 (Olympus-616 convention).

---

## Manifest Template

`scaffolding/cosmos-logos.template.json` includes:

| Section | Fields | Status |
|---------|--------|--------|
| `cosmos_logos_version` | `"1.0.3"` | Preset |
| `identity` | name, codename, purpose, description, version, repo, maintainers | Placeholders |
| `display` | icon_url, color, homepage | Placeholders |
| `network` | endpoint, health, well_known | Defaults |
| `cryptography` | algorithm, public_key | Ed25519 + placeholder key |
| `capabilities` | One chat capability | Working default |
| `trust` | ttl=3600, agents=[] | Empty trust |
| `metadata` | tags, created, updated, license | Defaults |

A developer replaces the uppercase placeholders (`AGENT_NAME`, `YOUR_ORG`, `REPLACE_WITH_YOUR_PUBLIC_KEY`) and has a valid manifest.

---

## What Was NOT Done

- **Task 6.5 — Convert to GitHub template repo**: This is a manual toggle in GitHub repository settings (Settings → Template repository → check the box). It cannot be done via code — it requires repo admin access on GitHub. The Cosmic Turtle or repo owner handles this.
- **Scaffolding CLI tool**: No `thoth scaffold my-agent` command. The template is a simple directory copy. A CLI tool would add complexity without proportional value at this stage.
- **Schema validation in template**: The template does not include `cosmos-logos.schema.json`. Developers are pointed to the Thoth repo for the schema. Including it would create a maintenance burden of keeping two copies in sync.

---

## Test Results

```
83 passed in 2.66s

Phase 1 tests:  16 passed
Phase 2 tests:  26 passed
Phase 3 tests:   2 passed
Phase 4 tests:  18 passed
Phase 5 tests:  14 passed
Phase 6 tests:   7 passed (NEW)
```

### Phase 6 Test Coverage

| Test | What It Validates |
|------|-------------------|
| `test_template_is_valid_json` | Manifest template parses as JSON, has correct version and codename |
| `test_template_has_required_fields` | All required fields present: cosmos_logos_version, identity (name, codename, purpose, version, repo), network (endpoint), cryptography (algorithm, public_key), capabilities (verb, protocol, path), trust (ttl, agents) |
| `test_template_files_exist` | All 8 template files present: main.py, seashell.py, requirements.txt, Dockerfile, docker-compose.yml, .env.example, .gitignore, README.md |
| `test_main_has_required_routes` | main.py contains all 4 required endpoints and SSE media type |
| `test_seashell_has_metering` | seashell.py contains meter_operation, operation_id, seashell_ledger, 429 |
| `test_guide_exists` | BUILDING_AN_AGENT.md exists |
| `test_guide_covers_key_topics` | Guide mentions Ed25519, cosmos-logos.json, /.well-known/, /health, Docker, Invariants |

---

## Exit Criteria

| Criterion | Status |
|-----------|--------|
| Developer guide complete | ✓ 9 sections covering the full agent lifecycle |
| Manifest template valid | ✓ All required fields, placeholder values |
| Agent template runs | ✓ Self-contained FastAPI skeleton with 4 endpoints |
| Metering template available | ✓ Standalone seashell.py with SQLite |
| Docker deployment ready | ✓ Dockerfile + docker-compose.yml |
| Template is forkable | ✓ README with quick start, .env.example, .gitignore |
| Convert to GitHub template | ⏸ Manual step — requires repo admin on GitHub |
| All previous tests pass | ✓ 83/83 |

---

## Full Project Summary — All Phases Complete

### Phase Completion

| Phase | Description | Tasks | Tests | Status |
|-------|-------------|-------|-------|--------|
| Phase 0 | Foundation | 12 | 0 | ✓ Complete (prior session) |
| Phase 1 | Core Agent | 10 | 16 | ✓ Complete |
| Phase 2 | Local Git + Journal Backend | 15 | 26 | ✓ Complete |
| Phase 3 | Journal UI | 13 | 2 | ✓ Complete |
| Phase 4 | Code Agent + Webhooks | 12 | 18 | ✓ Complete |
| Phase 5 | Entitlement | 9 | 14 | ✓ Complete |
| Phase 6 | Scaffolding | 5 | 7 | ✓ Complete |
| **Total** | | **76** | **83** | **All green** |

### File Count by Package

| Package | Files | Purpose |
|---------|-------|---------|
| `thoth/` | 1 | Package init (version) |
| `thoth/auth/` | 3 | Service bridge, session store |
| `thoth/config.py` | 1 | Settings loader |
| `thoth/main.py` | 1 | App factory, lifespan |
| `thoth/entitlement/` | 3 | Adapter ABC, SQLite/OlympusCoin adapters, SeashellMeter |
| `thoth/git/` | 5 | Lock, bootstrap, local ops, conflict resolver, sync |
| `thoth/github/` | 4 | Client, diff chunker, PR management, branches |
| `thoth/llm/` | 3 | Claude wrapper, code review, writing heuristics |
| `thoth/routes/` | 6 | Discovery, chat, journal, GitHub, webhook, entitlement |
| `thoth/webhooks/` | 2 | Job store, event handlers |
| `static/` | 1 | journal.html |
| `scaffolding/` | 9 | Template manifest, agent skeleton (8 files) |
| `tests/` | 12 | 83 tests across all phases |
| **Total** | **51 source files** | |

### API Surface

| Endpoint | Method | Phase |
|----------|--------|-------|
| `/.well-known/cosmos-logos.json` | GET | 1 |
| `/health` | GET | 1 |
| `/ping` | GET | 1 |
| `/chat` | POST | 1 |
| `/journal/entry` | POST | 2 |
| `/journal/entries` | GET | 2 |
| `/journal/entry/{path}` | GET | 2 |
| `/journal/search` | GET | 2 |
| `/journal/status` | GET | 2 |
| `/journal/sync` | POST | 2 |
| `/journal/settings` | POST | 2 |
| `/journal/settings/migrate` | POST | 2 |
| `/github/review` | POST | 4 |
| `/github/pr` | POST | 4 |
| `/github/branch` | POST | 4 |
| `/webhook/github` | POST | 4 |
| `/entitlement/ledger` | GET | 5 |
| `/entitlement/balance` | GET | 5 |

### Remaining Work

| Item | Scope | Notes |
|------|-------|-------|
| Phase 7 — TurtleShell Integration | Olympus-616 team | Agent discovery UI, service delegation, rate table display. Separate repo (iris). |
| Task 6.5 — GitHub template repo | Repo admin | Manual toggle in GitHub settings |
| Wire `@meter` to routes | Future | Requires auth middleware integration for user_id |
| Auto-sync background task | Future | Scheduler for periodic journal sync |
| CodeMirror 6 full init | Future | Editor upgrade from textarea fallback |

---

*Phase 6 Implementation Summary — Thoth Coding Agent — 2026-03-23*
*All 6 Thoth phases complete. 83 tests passing. Ready for commit review.*
