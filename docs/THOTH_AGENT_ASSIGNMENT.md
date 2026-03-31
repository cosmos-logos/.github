# Thoth Agent — Assignment Brief

**From:** Cosmic Turtle (Engineering Architect, Olympus-616)
**To:** Thoth Coding Agent
**Date:** 2026-03-23
**Status:** READY FOR EXECUTION

---

## Your Identity

You are the Thoth coding agent. You build the Thoth writing and coding agent — a sovereign, open-source, Git-native application powered by the Anthropic Claude API. You are the first reference implementation of the cosmos-logos agent discovery protocol.

**Your repo:** `cosmos-logos/thoth` (to be created)
**Your port:** 3441
**Your language:** Python 3.12 + FastAPI
**Your license:** MIT

---

## Your Boundaries

| You DO | You DO NOT |
|--------|-----------|
| Build the Thoth FastAPI server | Touch any Olympus-616 code |
| Write cosmos-logos.json manifests | Modify Ares, Hermes, Athena, or any other god |
| Build journal.html (single-file UI) | Change iris/turtleshell React code |
| Build the SeaShell entitlement ledger | Integrate with Plutus directly |
| Build GitHub webhook handling | Manage TurtleShell service connections |
| Build the scaffolding/developer guide | Build the TurtleShell agent discovery UI |

The Cosmic Turtle handles the Olympus-616 side (agent discovery UI, service delegation, JWT contracts). You handle the Thoth side. You meet at the protocol boundary.

---

## The Specification

The complete spec is in the user's message that triggered this assignment. It is the **Thoth Writing Agent Formal Specification v1.2.0** — a 15-section document covering:

1. Executive Summary
2. System Architecture (with full repo structure)
3. Auth & Service Trust Model
4. Local-First Git Architecture
5. cosmos-logos.json Specification
6. Journal Application
7. GitHub Integration
8. Webhook Architecture
9. SeaShell Entitlement System
10. TurtleShell Discovery Protocol
11. Agent Development Scaffolding
12. Implementation Plan (6 phases)
13. Risk Register (20 risks with mitigations)
14. Four-Model Panel Final Decisions (30 locked decisions)
15. Architectural Invariants (12 rules that cannot be broken)

**Read the full spec before writing any code.** Every design decision has been reviewed by a four-model panel (Claude, GPT-4o, Gemini, Grok — two rounds each).

---

## Implementation Phases

Execute sequentially. All code goes in your repo.

### Phase 0 — Foundation
Create the repo structure, manifests, schema, config templates, Dockerfile, docker-compose.yml, README, CI.

### Phase 1 — Core Agent
FastAPI app, startup checks, discovery route with version headers, ping/health, service bridge (JWT validation), session management, Claude SSE chat with Thoth persona, SQLite init.

### Phase 2 — Local Git + Journal Backend
RepoLock (async mutex), RepoBootstrap (first-run), LocalGit (all ops via run_in_executor), ConflictResolver (local_wins), GitSync (5-state machine), all journal CRUD routes, settings, status endpoint.

### Phase 3 — Journal UI
`static/journal.html` — single file, zero build. CodeMirror 6 (CDN), marked.js preview, slash commands, entry sidebar, search, sync button, offline banner, settings panel, draft auto-save, smart mode banner.

### Phase 4 — Code Agent + Webhooks
GitHub client (PyGitHub + rate limits), file-based diff chunking, Claude code review with dry_run, PR/branch management, webhook handler (HMAC + replay protection + 202 BackgroundTask), job persistence, event handlers, cost guards.

### Phase 5 — Entitlement
UsageEvent with operation_id, SQLiteAdapter, OlympusCoinAdapter stub, SeashellMeter with @meter decorator, ledger endpoint, free tier enforcement.

### Phase 6 — Scaffolding
BUILDING_AN_AGENT.md, cosmos-logos.template.json, agent-template/ skeleton, convert to GitHub template repo.

---

## Critical Architecture Context

### Port Assignments (Olympus-616 Fleet)

```
Athena      3401    LLM Router
Hermes      3411    Message Transport
Apollo      3421    Voice Engine
Poseidon    3431    MCP Tools
THOTH       3441    Writing Agent ← YOU
Ares        3451    API Gateway
Proteus     3461    Universal ORM
Aphrodite   3471    Design System
Zeus        3481    Fleet Controller
Hera        3491    Auth Gateway
Hestia      3501    Home Services
Hephaestus  3511    Build Forge
Mnemosyne   3711    Episodic Memory
Plutus      3701    Billing
Dashboard    717    Off-Grid UI
```

### JWT Token Format (Ares)

Ares currently validates JWTs with:
- **Issuer:** `https://cloudpremise.com`
- **Audience:** `https://api.cloudpremise.com`
- **Algorithm:** RS256
- **Key:** `OG_Signing_Key.crt` (Salesforce-issued RSA-4096)

Your service bridge will validate a *different* JWT format for cosmos-logos service delegation:
- **Issuer:** `turtleshell`
- **Audience:** `thoth`
- **Claims:** `services.github.delegated_token`

This JWT contract is defined in spec Section 3. The signing key is TBD (pending PM answer on Q2). For now, implement the validation logic with configurable key loading.

### Cookie-to-Header Mapping (Ares)

When requests flow through Ares, these cookies become headers:
```
__Host-og_access      → x-user-identity
__Host-gh_access      → x-github-token
__Host-sf_access      → x-salesforce-token
__Host-google_access  → x-google-token
__Host-hs_access      → x-hubspot-api-key
```

Your service bridge reads `x-github-token` from incoming requests (delegated by TurtleShell through Ares) OR validates a TurtleShell session JWT that contains a delegated token.

### Agent Store (Current iris Model)

Thoth is already in the agent catalog:
```typescript
{
  id: 'thoth',
  name: 'Thoth',
  description: 'Claude-powered reasoning agent',
  icon: '📜',
  capabilities: ['chat', 'reasoning'],
  requiredServices: ['olympus_grid'],
}
```

This will be updated in Phase 7 (by the Cosmic Turtle, not you) to use cosmos-logos discovery instead of a hardcoded catalog.

### Environment Patterns

Three deployment contexts exist:
- **cloud:** `https://api-int.turtleshell.ai`
- **offgrid:** `https://athena-616.ngrok.io` (ngrok tunnel to local fleet)
- **custom:** User-provided endpoint

Your Docker container will be added to the off-grid fleet's `docker-compose.yml` (by the Cosmic Turtle).

### Cosmos-Logos Protocol (v1.0.3)

The cosmos-logos spec defines:
- **Manifest at** `/.well-known/cosmos-logos.json`
- **Ed25519 signing** for request authentication
- **Version negotiation** via `X-CosmosLogos-Version` header
- **Capability verbs** (what agent can do) separate from protocol bindings (how)
- **TTL-based caching** of manifests

For v1, focus on the manifest serving and version headers. Ed25519 signing is Phase 2+ — the spec says "service_delegation" auth type, not cryptographic signing between Thoth and TurtleShell.

---

## 12 Architectural Invariants

These cannot be broken. Ever. By any implementation decision.

1. All state must be reproducible from the local git repo.
2. `cosmos-logos.json` is the only discovery surface.
3. No hidden state outside user-controlled systems.
4. All LLM output is optional. Never authoritative.
5. Reads are never metered.
6. Rate changes require `rate_table_version` bump + 30-day notice.
7. Auto-approve is always user opt-in. Never a default.
8. OAuth tokens never appear in URL parameters.
9. GitHub is sync, not primary. The local repo always works.
10. Agents do not maintain their own service logins.
11. All git mutations are wrapped in `run_in_executor`.
12. All git mutations are wrapped in `RepoLock`.

---

## Python Dependencies

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

---

## Docker

```dockerfile
FROM python:3.12-slim AS deps
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

FROM python:3.12-slim
WORKDIR /app
COPY --from=deps /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=deps /usr/local/bin /usr/local/bin
COPY . .
EXPOSE 3441
CMD ["uvicorn", "thoth.main:app", "--host", "0.0.0.0", "--port", "3441"]
```

---

## .env.example

```bash
# Required
ANTHROPIC_API_KEY=sk-ant-...

# Optional — webhook support
THOTH_SECRET=your-webhook-hmac-secret

# Optional — local config
THOTH_LOCAL_REPO=~/Documents/journal
THOTH_PORT=3441

# Optional — TurtleShell integration
TURTLESHELL_PUBLIC_KEY_PATH=./keys/turtleshell.pub
```

---

## Commit Convention

```
type(thoth): description

Examples:
feat(thoth): add journal entry creation via local git
fix(thoth): wrap git search in run_in_executor
docs(thoth): add BUILDING_AN_AGENT.md
```

---

## What Success Looks Like

After all 6 phases:

1. `GET /.well-known/cosmos-logos.json` returns a valid manifest
2. `POST /chat` streams Claude responses with Thoth persona
3. `POST /journal/entry` commits to local git
4. `GET /journal/entries` lists entries from local git tree
5. `GET /journal/search?q=morning` returns git grep results
6. `POST /journal/sync` pushes to GitHub (when network available)
7. `journal.html` loads, works offline, saves entries
8. `POST /github/review` reviews a PR with Claude
9. `POST /webhook/github` handles events with 202 + background processing
10. SeaShell ledger tracks all metered operations
11. A developer can fork the template and build their own cosmos-logos agent

No external dependencies beyond the Anthropic API. User owns all data. The local git repo always works. The journal is sovereign.

---

*Assignment Brief v1.0.0 — Cosmic Turtle → Thoth Agent*
*cosmos-logos/thoth · CloudPremise LLC · MIT License*
*"The shell carries everything. The scribe records it all."*
