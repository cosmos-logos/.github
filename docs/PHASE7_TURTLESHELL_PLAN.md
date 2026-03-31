# Phase 7 — TurtleShell Web Integration
## Detailed Implementation Plan for Thoth Agent Review
### Cosmic Turtle (Engineering Architect) · March 23, 2026

---

## Status: PLAN — NO CODE CHANGES YET

This plan is for review by the Thoth agent before any code is written. It identifies architectural concerns, protocol boundary contracts, and sequencing dependencies between the two repos.

---

## 1. Architecture Assessment

### Two Separate Concepts — Do Not Merge

The existing codebase has two "agent" concepts that must remain distinct:

| Concept | Store | Purpose | Example |
|---------|-------|---------|---------|
| **Voice/LLM Agent** | `agent-store.ts` | Selects which LLM backbone routes chat (Athena, Turtle, Mars, Gemini) | User picks "Thoth" from voice dropdown → chat goes to Claude via Thoth persona |
| **cosmos-logos Agent** | NEW `cosmos-logos-store.ts` | External sovereign agent with its own server, endpoints, auth, and entitlement | User adds Thoth URL → manifest fetched → Journal surface unlocks |

The existing `agent-store.ts` and its `AGENT_CATALOG` (Turtle, Athena, Thoth, Mars, Gemini) are **voice selectors** that route through Athena's MCP. The cosmos-logos agents are **independent servers** with their own endpoints. These do NOT share a store.

The existing hardcoded "Thoth" in `AGENT_CATALOG` (id: 'thoth') is a voice/persona selector — it tells Athena to use the Thoth persona. The cosmos-logos Thoth is a separate server at `localhost:3441` with its own journal, git backend, and entitlement. They may share a name but are architecturally distinct.

**Decision needed from PM/Thoth:** Should the voice "Thoth" in the agent picker be removed or renamed to avoid confusion with the cosmos-logos Thoth? Or do they coexist — one is "voice Thoth" (LLM routing) and the other is "Thoth agent" (cosmos-logos service)?

---

## 2. Critical Concerns

### 2.1 Auth Model Divergence

The original Thoth spec (Section 3) described **JWT service delegation**:
```
TurtleShell issues JWT → Thoth validates JWT → extracts delegated GitHub token from claims
```

The Phase 7 prompt describes **Ed25519 sealed-box encryption + request signing**:
```
TurtleShell encrypts GitHub token with Thoth's public key → signs request with TurtleShell's private key → Thoth decrypts + verifies
```

These are fundamentally different auth models. The Phase 7 model is significantly more complex but aligns with the cosmos-logos-specification-v1.0.3 which specifies Ed25519 cryptography.

**Questions for Thoth agent:**
1. Does Thoth's actual implementation validate Ed25519 signatures on incoming requests? Or does it accept the sealed envelope without signature verification?
2. Is the `trust.agents` array actually enforced? If TurtleShell's public key isn't in the array, does Thoth reject all authenticated requests?
3. What's the exact header validation logic? Does Thoth check `x-cosmos-signature` + `x-cosmos-timestamp` + `x-cosmos-envelope` on every write endpoint?

### 2.2 Bundle Size — libsodium

`libsodium-wrappers-sumo` is **~190KB gzipped**. This is significant for the Salesforce Lightning Container iframe where every KB matters. The iris portal's current JS bundle is ~500KB gzipped.

**Alternatives considered:**
- `tweetnacl` (3KB) — has Ed25519 sign/verify but **lacks** `crypto_box_seal` and `ed25519_pk_to_curve25519`
- `noble-ed25519` + `noble-curves` (~15KB combined) — has Ed25519 but no sealed box
- `libsodium-wrappers` (not sumo, ~110KB) — has `crypto_box_seal` but may lack the Ed25519→Curve25519 conversion

**Recommendation:** Use `libsodium-wrappers-sumo` for correctness. Accept the bundle size hit. The crypto must match exactly what Thoth's server uses (PyNaCl wraps libsodium). Mismatched implementations = silent auth failures.

### 2.3 Salesforce Lightning Container Constraints

The iris portal runs inside an SF Lightning Container iframe. Key constraints:

| Constraint | Impact on Phase 7 |
|------------|-------------------|
| Cross-origin fetch | Thoth at `localhost:3441` requires CORS headers. Does Thoth set `Access-Control-Allow-Origin`? |
| iframe CSP `frame-src` | Journal.html iframe embedding may be blocked by SF CSP. The CSP trusted sites we added cover `athena-616.ngrok.io` but not `localhost:3441`. |
| localStorage namespacing | In SF, LockerService namespaces localStorage. The cosmos-logos store must work within this constraint. |
| sessionStorage for sealed tokens | sessionStorage works in the iframe but dies on tab close AND on SF Lightning Container recreation (which happens during OAuth flows). |

**Question for Thoth agent:** Does Thoth's FastAPI server include CORS middleware? Specifically:
- `Access-Control-Allow-Origin: *` (or configurable)
- `Access-Control-Allow-Headers: x-cosmos-signature, x-cosmos-timestamp, x-cosmos-envelope, Content-Type`
- `Access-Control-Expose-Headers: X-CosmosLogos-Version-Supported, X-CosmosLogos-Rate-Table-Version`

### 2.4 Keypair Lifecycle

TurtleShell's Ed25519 keypair needs to persist across sessions but is security-sensitive. Options:

| Storage | Pros | Cons |
|---------|------|------|
| localStorage | Persists across sessions | Accessible to any JS on the page; SF LockerService namespaces it |
| sessionStorage | More secure (dies on close) | Keypair lost on every tab close — regeneration means new trust entry in Thoth |
| IndexedDB | Persistent, structured | More complex API; still accessible to JS |
| Generated fresh each session | No persistence needed | Requires adding new public key to Thoth trust array every session — unworkable |

**Recommendation:** Store in localStorage (encrypted with a user-derived key if possible). The keypair must persist — regenerating it means manually updating Thoth's trust array every time.

In the SF iframe context, localStorage is accessible (we already use it for tokens). The private key is used only for signing — even if leaked, it only proves identity to Thoth, it doesn't grant access to anything.

---

## 3. Task Breakdown

### Task 7.0 — Dependencies + Types

Install `libsodium-wrappers-sumo`. Define TypeScript interfaces matching the actual cosmos-logos.json schema.

**New files:**
- `lib/cosmos-logos/types.ts` — `CosmosLogosManifest`, `AgentCapability`, `TrustEntry`, `NetworkConfig`, `CryptographyConfig`

**Key type decisions:**
```typescript
interface CosmosLogosManifest {
  cosmos_logos_version: string
  identity: {
    codename: string
    name: string
    version: string
    purpose?: string
  }
  display?: {
    color?: string
    icon_url?: string
  }
  network: {
    endpoint: string
    health?: string
    well_known?: string
  }
  cryptography: {
    algorithm: string
    public_key: string
    signing_header: string
    timestamp_header: string
  }
  envelope?: {
    header: string
  }
  capabilities: Array<{
    verb: string
    protocol_binding?: string
    endpoint?: string
  }>
  trust: {
    agents: TrustEntry[]
  }
  entitlement?: {
    currency: string
    developer: string
    rate_table_version: string
    rates: Record<string, number>
    free_tier?: Record<string, number>
  }
}
```

### Task 7.1 — Crypto Layer (`lib/cosmos-logos/crypto.ts`)

**Dependencies:** `libsodium-wrappers-sumo`

**Functions:**
1. `generateKeypair()` → generates Ed25519 keypair, stores in localStorage
2. `loadKeypair()` → loads from localStorage, generates if not found
3. `getPublicKeyPem()` → returns PEM-formatted public key for trust registration
4. `sealToken(token: string, recipientPublicKeyPem: string)` → Ed25519→Curve25519 conversion + `crypto_box_seal`
5. `signRequest(body: string, privateKey: Uint8Array)` → Ed25519 detached signature + ISO timestamp
6. `buildAuthHeaders(manifest, body, privateKey, sealedToken)` → builds the three auth headers using names from manifest

**Critical:** Must call `await sodium.ready` before any crypto operation. libsodium-wrappers requires async initialization.

**Output at end of task:** Console log of TurtleShell's public key in PEM format for manual addition to Thoth's trust array.

### Task 7.2 — Manifest Client (`lib/cosmos-logos/client.ts`)

**Functions:**
1. `fetchManifest(agentUrl)` → GET `/.well-known/cosmos-logos.json` with version header
2. `pingAgent(agentUrl)` → GET `/ping`, returns boolean
3. `healthCheck(agentUrl)` → GET `/health`, returns status object
4. `validateManifest(manifest)` → type guard checking required fields

**Error handling:**
- Network error → "Agent not reachable"
- 404 → "No cosmos-logos manifest found at this URL"
- Invalid manifest → "Invalid agent manifest: missing {field}"
- Version mismatch → "Agent version {x} not supported"

### Task 7.3 — Agent Store (`lib/cosmos-logos/store.ts`)

**Separate store from `agent-store.ts`.** Zustand with `persist` middleware (localStorage key: `turtleshell-cosmos-agents`).

**State:**
```typescript
{
  agents: ConnectedAgent[]           // persisted
  pendingRateAcknowledgements: string[] // agent IDs with unacknowledged rate changes
}
```

**Actions:**
- `addAgent(url, manifest, rateTableVersion)`
- `removeAgent(agentId)` — also clears sessionStorage sealed token
- `getAgent(agentId)` → returns ConnectedAgent or null
- `getUnlockedSurfaces()` → derived: checks connected agents' capabilities against required services
- `sealAndStoreToken(agentId, githubToken, manifest)` → calls crypto.sealToken, stores in sessionStorage
- `getSealedToken(agentId)` → reads from sessionStorage
- `checkRateTableUpdate(agentId, currentVersion)` → boolean
- `acknowledgeRateTableUpdate(agentId, newVersion)`

**Token re-sealing:** On page load, if an agent is connected (in localStorage) but sealed token is missing (sessionStorage cleared), the UI shows "Reconnect" button. User clicks → re-seals from ServiceRegistry GitHub token. No new OAuth.

### Task 7.4 — Thoth API Client (`lib/agents/thoth.ts`)

Typed client for all Thoth endpoints. Reads header names from manifest (never hardcoded).

**Read methods (no auth):** `getEntries()`, `getEntry(path)`, `search(q)`, `getStatus()`, `getBalance()`, `getLedger()`

**Write methods (auth required):** `createEntry(...)`, `sync()`, `chat(messages)` (SSE async generator)

**Auth header construction:** Uses `buildAuthHeaders()` from crypto.ts with header names from `manifest.cryptography.signing_header`, `manifest.cryptography.timestamp_header`, `manifest.envelope.header`.

### Task 7.5 — Agent Setup Page Redesign (`pages/Agents.tsx`)

**Current page:** Hardcoded catalog of 4 voice agents (Athena, Apollo, Hermes, Hephaestus). Click to select active voice.

**New page structure:**

```
Agent Setup

← Back to Chat

┌─ CONNECTED AGENTS ──────────────────────────┐
│ [AgentCard: Thoth]  📜                       │
│   Thoth · Writing Agent                      │
│   chat · journal · code_review               │
│   🐚 Balance: 47 shells                      │
│   [Disconnect]                               │
└──────────────────────────────────────────────┘

┌─ ADD AGENT ──────────────────────────────────┐
│ Agent URL: [https://localhost:3441        ]   │
│ [Fetch Manifest]                              │
│                                               │
│ (After fetch: shows AddAgentPanel with        │
│  agent card, capabilities, rate table,        │
│  required services check, [Connect] button)   │
└──────────────────────────────────────────────┘

┌─ VOICE / LLM ───────────────────────────────┐
│ (Existing agent picker — select dropdown      │
│  matching the one already in Chat menu)       │
└──────────────────────────────────────────────┘
```

Three sections: Connected cosmos-logos agents (top), Add Agent (middle), Voice/LLM selector (bottom, existing functionality moved here).

### Task 7.6 — Journal Page (`pages/Journal.tsx`)

**Option A (iframe):** Embed `{thothUrl}/static/journal.html` in an iframe. Fast, uses Thoth's existing UI.

**Option B (native):** React components calling ThothClient. Better UX integration but more work.

**Recommendation:** Start with Option A. If SF CSP blocks the iframe, fall back to Option B.

**Route:** `/turtleshell/journal`
**Navigation:** Only visible in Chat menu when `getUnlockedSurfaces()` includes `journal`

### Task 7.7 — Route + Navigation Wiring

**New route in `routes.tsx`:**
```tsx
{ route: "/turtleshell/journal", component: <TurtleShellLayout><Journal /></TurtleShellLayout>, privacy: "private" }
```

**Chat menu update in `Chat.tsx`:**
Add Journal to the menu items, conditionally shown:
```tsx
// Only show if Thoth connected + journal capability unlocked
const cosmosStore = useCosmosLogosStore()
const surfaces = cosmosStore.getUnlockedSurfaces()

// In nav items array:
...(surfaces.includes('journal') ? [{ to: '/turtleshell/journal', icon: BookText, label: 'Journal' }] : []),
```

### Task 7.8 — Rate Change Detection

Background poll every 24 hours (or on app mount):
- Fetch manifest from each connected agent
- Compare `X-CosmosLogos-Rate-Table-Version` header with stored version
- If changed: show notification, block metered ops until acknowledged

---

## 4. Sequencing

```
Task 7.0 (types + deps)
  ↓
Task 7.1 (crypto) ──→ OUTPUT: TurtleShell public key PEM
  ↓                        ↓
  ↓                   [Manual step: Add key to Thoth trust array, restart Thoth]
  ↓
Task 7.2 (manifest client)
  ↓
Task 7.3 (agent store)
  ↓
Task 7.4 (thoth client)
  ↓
Task 7.5 (Agent Setup page redesign)
  ↓
Task 7.6 (Journal page)
  ↓
Task 7.7 (route + nav wiring)
  ↓
Task 7.8 (rate change detection)
```

Tasks 7.1-7.4 are foundational (library code). Tasks 7.5-7.8 are UI integration.

**Blocking dependency:** Task 7.1 outputs TurtleShell's public key. This must be added to Thoth's `cosmos-logos.json` trust array before authenticated requests work. This is a cross-repo manual step.

---

## 5. Questions for Thoth Agent

Before I write code, I need these answers from the Thoth agent:

| # | Question | Why It Matters |
|---|----------|---------------|
| 1 | What is the exact structure of `cosmos-logos.json` as served by your running instance? | The Phase 7 prompt says it diverged from the spec. I need the actual JSON, not the spec's version. |
| 2 | Does your server enforce Ed25519 signature verification on write endpoints? | If not enforced yet, I can implement the crypto layer but skip signing until it is. |
| 3 | Does your server enforce the trust array? (Reject requests from unknown signers?) | Determines whether the manual trust registration step is blocking. |
| 4 | What CORS headers does your FastAPI server send? | TurtleShell runs in a browser — cross-origin fetch to `localhost:3441` needs CORS. |
| 5 | What's the exact SSE format for `/chat`? Event names, data structure, done signal? | I need to parse the stream correctly in the ThothClient. |
| 6 | What does `POST /journal/entry` expect as request body and return as response? | I need the exact JSON contract for the ThothClient. |
| 7 | Is there a `/journal/settings` endpoint to get current config? (For the first-load setup flow) | The spec mentions first-load config but I need the API. |
| 8 | What does `GET /entitlement/balance` return? Exact JSON shape? | For the SeaShell balance display. |
| 9 | Can you provide a curl example of a successful authenticated request? | So I can verify my crypto implementation matches yours. |
| 10 | Is `journal.html` served at `/static/journal.html` or a different path? | For the iframe embedding in Task 7.6. |

---

## 6. Files Changed Summary

### New Files (12)

| File | Purpose |
|------|---------|
| `lib/cosmos-logos/types.ts` | TypeScript interfaces for cosmos-logos manifest |
| `lib/cosmos-logos/crypto.ts` | Ed25519 keygen, sealed-box, signing |
| `lib/cosmos-logos/client.ts` | Manifest fetcher, validator, ping |
| `lib/cosmos-logos/store.ts` | Zustand store for connected agents |
| `lib/agents/thoth.ts` | Typed Thoth API client |
| `components/agents/AgentCard.tsx` | Displays agent info from manifest |
| `components/agents/AddAgentPanel.tsx` | URL input → manifest fetch → connect flow |
| `components/agents/AgentUnlock.tsx` | Renders unlock surfaces (Journal tab, etc.) |
| `pages/Journal.tsx` | Journal surface (iframe or native) |
| (none — types.ts covers this) | |

### Modified Files (4)

| File | Change |
|------|--------|
| `pages/Agents.tsx` | Full redesign: connected agents + add agent + voice selector |
| `pages/Chat.tsx` | Add Journal to nav menu (conditional on unlock) |
| `config/routes.tsx` | Add `/turtleshell/journal` route |
| `package.json` | Add `libsodium-wrappers-sumo` dependency |

### NOT Modified

| File | Reason |
|------|--------|
| `agent-store.ts` | Voice/LLM selection is separate from cosmos-logos agents |
| `service-store.ts` | Services (GitHub, SF, etc.) are separate from agents |
| `environment-store.ts` | No environment changes needed |
| `mcp-headers.ts` | MCP headers are for Athena/Poseidon, not cosmos-logos |
| Any OAuth flow | No new OAuth — uses existing GitHub service connection |

---

## 7. Risk Assessment

| Risk | Severity | Mitigation |
|------|----------|-----------|
| libsodium bundle size (+190KB) | Medium | Accept it — crypto correctness > bundle size |
| SF CSP blocks iframe to Thoth | High | Fall back to native React Journal UI (Option B) |
| Ed25519→Curve25519 conversion mismatch | High | Use same library (libsodium) as Thoth server (PyNaCl) |
| Trust array manual step blocks testing | Medium | Thoth could add a `--dev-mode` flag that skips trust verification |
| sessionStorage token lost on SF iframe recreation | Medium | Show "Reconnect" button — one click re-seals token |
| Rate table poll fires 24h later, user sees stale rates | Low | Also check on app mount, not just interval |
| Thoth CORS not configured | High | Thoth must add CORS middleware — blocking question #4 |

---

## 8. Estimated Effort

| Task | Files | Estimate |
|------|-------|----------|
| 7.0 Types + deps | 1 new | 20 min |
| 7.1 Crypto layer | 1 new | 45 min |
| 7.2 Manifest client | 1 new | 25 min |
| 7.3 Agent store | 1 new | 35 min |
| 7.4 Thoth client | 1 new | 30 min |
| 7.5 Agent Setup page | 1 rewrite + 2 new components | 60 min |
| 7.6 Journal page | 1 new | 20 min |
| 7.7 Route + nav wiring | 2 modified | 15 min |
| 7.8 Rate change detection | in store | 15 min |
| **Total** | **12 new, 4 modified** | **~4.5 hours** |

---

*Phase 7 Plan v1.0.0 — Cosmic Turtle → Thoth Agent Review*
*No code written. Awaiting protocol boundary confirmation.*
