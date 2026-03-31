# Phase 0 — Foundation: Implementation Summary

**Agent:** Thoth Coding Agent
**Date:** 2026-03-23
**Branch:** `brain/1.7.x.x`
**Status:** PHASE 0 COMPLETE — AWAITING COMMIT REVIEW

---

## Decisions Made Before Implementation

### Q1 — Repo Location
Resolved: Build in `cosmos-logos/thoth` on `brain/1.7.x.x`. User handles all commits.

### Q2 — Auth Model
Resolved: **No JWTs anywhere in Thoth.** Auth is cosmos-logos native:
- Thoth's Ed25519 public key is published in `cosmos-logos.json`
- TurtleShell derives X25519 from that key
- GitHub tokens are passed via `crypto_box_seal` (libsodium sealed box) in the `x-cosmos-envelope` header
- Thoth decrypts with its private key, uses the token for the request, never persists it

This replaced the JWT-based service delegation from the original assignment brief.

### Q3/Q6 — TurtleShell Integration
Resolved: Thoth builds standalone. Any TurtleShell changes are communicated as instructions to the Olympus-616 team.

### Q5 — API Key
Resolved: Own `ANTHROPIC_API_KEY`, not shared with Athena.

### Dependencies Changed
- `pyjwt[crypto]` → **removed** (no JWTs)
- `pynacl` → **added** (Ed25519 signatures + sealed box decryption)

---

## Files Created

### Directory Structure
```
.github/workflows/          CI pipeline
keys/                       Ed25519 keypair (private key gitignored)
scaffolding/agent-template/  Phase 6 agent starter kit (empty)
static/                     Phase 3 journal UI (empty)
tests/                      Test suite
  __init__.py
thoth/                      Python package root
  __init__.py               v0.1.0
  auth/__init__.py
  entitlement/__init__.py
  git/__init__.py
  github/__init__.py
  llm/__init__.py
  routes/__init__.py
  webhooks/__init__.py
```

### Manifests & Schema
| File | Purpose |
|------|---------|
| `cosmos-logos.json` | Thoth agent manifest. Ed25519 public key, 3 capabilities (chat, journal, code_review), envelope config, trust array. |
| `athena-616.cosmos-logos.json` | Reference manifest showing how Athena-616 declares trust toward Thoth. Placeholder public key. |
| `cosmos-logos.schema.json` | JSON Schema (2020-12) validating any cosmos-logos v1.0.3 manifest. Covers identity, display, network, cryptography (with key rotation fields), capabilities (with conditional spec_url for custom protocol), trust, envelope, metadata. |

### Configuration & Infrastructure
| File | Purpose |
|------|---------|
| `requirements.txt` | fastapi, uvicorn, anthropic, gitpython, pygithub, **pynacl**, aiosqlite, aiohttp, python-multipart |
| `.env.example` | ANTHROPIC_API_KEY, THOTH_SECRET, THOTH_LOCAL_REPO, THOTH_PORT, key paths |
| `Dockerfile` | Multi-stage python:3.12-slim. Installs git in runtime stage. Port 3441. |
| `docker-compose.yml` | Single service, journal-data volume, keys mounted read-only. |
| `.thoth.json.example` | Application config: journal, llm, github, entitlement settings. |
| `turtleshell.json` | TurtleShell connection config: key paths, header names, timestamp tolerance. |
| `.gitignore` | Protects: private keys, .env, __pycache__, .db, .thoth.json, journal/ |
| `.github/workflows/validate.yml` | CI: validates both manifests against schema on push/PR. |

### Cryptographic Identity
- Ed25519 keypair generated via OpenSSL
- Private key: `keys/thoth.key` (gitignored, never committed)
- Public key: `keys/thoth.pub` (committable) + inline in `cosmos-logos.json`
- Fingerprint: `SHA256:YIi7qCXw8Vj+0mKSJtpzbngxlOMJwtqlTrRpZbxNu+c=`

### Updated by User
| File | Notes |
|------|-------|
| `README.md` | User rewrote with full project overview, quick start, endpoints table, architecture, invariants. |
| `CLAUDE.md` | User rewrote with build commands, architecture diagram, design boundaries, commit convention, ecosystem context, invariants. |

---

## What Was NOT Done

- **Task 0.13** (add as submodule to olympus-616): Out of scope for this agent. Requires Olympus-616 repo access.
- **`.thoth.local.json.example`**: Deferred — `.thoth.json.example` covers the config shape. Local overrides can be documented when config.py is implemented in Phase 1.

---

## Validation

Both manifests validated against the schema (required fields, top-level key allowlist). Full `jsonschema` library validation deferred to CI (requires pip install).

---

## Instructions for Olympus-616 (TurtleShell Integration)

Once Phase 0 is committed, the Olympus-616 agent can begin parallel work on manifest consumption:

1. **Fetch `cosmos-logos.json`** from `GET /.well-known/cosmos-logos.json` (or raw from repo)
2. **Validate against `cosmos-logos.schema.json`**
3. **Read `cryptography.public_key`** — PEM-encoded Ed25519 key
4. **Derive X25519 public key** from the Ed25519 key (libsodium `crypto_sign_ed25519_pk_to_curve25519`)
5. **Encrypt GitHub token** via `crypto_box_seal(x25519_public_key, token_bytes)` → base64url → set as `x-cosmos-envelope` header
6. **Sign requests** with TurtleShell's own Ed25519 key → `x-cosmos-signature` header + `x-cosmos-timestamp` header

Thoth will validate the signature and decrypt the envelope on its end (Phase 1, tasks 1.5-1.6).

---

## Next: Phase 1 — Core Agent

Phase 1 builds the running FastAPI server:

| Task | File | What It Does |
|------|------|-------------|
| 1.1 | `thoth/main.py` | FastAPI app, lifespan startup, CORS, static mount |
| 1.2 | `thoth/config.py` | Env loader, manifest loader, settings |
| 1.3-1.4 | `thoth/routes/discovery.py` | `/.well-known/cosmos-logos.json`, `/health`, `/ping` |
| 1.5 | `thoth/auth/service_bridge.py` | Ed25519 signature verification + envelope decryption |
| 1.6 | `thoth/auth/session.py` | Session management |
| 1.7 | `thoth/llm/claude.py` | Anthropic SDK wrapper, SSE streaming, Thoth persona |
| 1.8 | `thoth/routes/chat.py` | `/chat` SSE endpoint |
| 1.9 | `thoth/main.py` | SQLite schema init (seashell_ledger, webhook_jobs) |
| 1.10 | `tests/` | Discovery, ping, health, chat SSE tests |

**Exit criteria:** Server boots. Discovery returns manifest. Chat streams Claude. Auth validates Ed25519 signatures and decrypts envelopes.

---

*Phase 0 Implementation Summary — Thoth Coding Agent — 2026-03-23*
