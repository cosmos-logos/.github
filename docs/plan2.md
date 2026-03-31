PM review first. Then I'll output the full v1.6 as MD.

---

**ACCEPT from Grok v1.6:**

Stack agnosticism principle — correct and important. The Grid has no runtime preference. cosmos-logos is the only contract.

Unified cosmos-logos schema with expanded fields — accept. `endpoint` field is the key addition. Allows local `.local` addresses, tunneled URLs, or remote endpoints. This is what makes multi-runtime discovery work.

Thoth added back to Section 2 as reference implementation — accept. Three agents, three runtimes, one discovery protocol. That's the demonstration.

mDNS/Bonjour as primary local discovery — already accepted in v1.3, confirmed again.

Step 0 in build sequence — finalize unified cosmos-logos schema before anything else. Accept. Schema-first is correct.

**REJECT from Grok v1.6:**

Section 12 still has "HTTPS endpoint required." Grok flagged this in v1.3 and we rejected it then. Rejecting again. Internet exposure is never required. Local LAN is the default. HTTPS only applies if the user chooses to expose.

Athena v1.5 removed the curriculum mission, the soccer mom positioning, the homepage concepts, and the SendGrid goodwill framing. Those were the heart of v1.4. Athena stripped the soul out to clean the architecture. We keep the soul.

**PM directive for v1.6:**

Merge Grok's technical additions onto v1.4's foundation. Not onto Athena's stripped-down v1.5.

---

# OLYMPUS-616 Unified Platform Spec v1.6

**Hermes SMS · Agora · Homework Buddy · Thoth**
CloudPremise LLC | March 2026
*v1.0 Thoth · v1.2 Athena · v1.3 Grok · v1.4 Thoth · v1.5 Athena · v1.6 Grok + Thoth PM final*

---

## 1. The Heart of It

> Software runs where it is owned, not where it is hosted.

Two products. Two families. One grid.

Homework Buddy started as a demo. It became something more the moment a father realized his stepson could build it. Now it is a curriculum — the path a kid walks from zero to their first working AI agent. Clone it. Fork it. Break it. Fix it. Ship it.

Agora started as a construction management tool. It became something more the moment a wife needed to manage a house rebuild and didn't want her conversations in Slack, her files in some company's cloud, her group in someone else's database.

> "Hi honey, check out Agora — this offline group chat we can put on our Mac Mini. Have you heard of TurtleShell.ai? You should set one up for our soccer team."

Neither product knows the other exists. Both run on the same grid. Both bring new users into TurtleShell.ai — one kid at a time, one family at a time.

---

## 2. Product Positioning

### 2.1 Homework Buddy — Build Your First AI Agent

> "Text me your homework buddy."

**Target:** Kids 10–17. Parents who want visibility. First-time developers who have never shipped anything.

**Stack:** PHP 8.2 + Laravel + MySQL + Apache/Nginx. Full local LAMP. Teaches the classics.

Homework Buddy is not just an app. It is a curriculum delivered as a GitHub repository. The child who clones it becomes a developer. The kid who forks it submits their first open source pull request.

| What They Learn | How They Learn It |
|---|---|
| Open source | GitHub fork, branch, pull request |
| Local AI | Grok API, prompt engineering in PHP |
| Off-grid dev | LAMP stack, runs without cloud |
| Sovereignty | My hardware. My data. My rules. |
| Real infra | SMS via Hermes, email via SendGrid, cosmos-logos |
| Database | MySQL schema, migrations, real data modeling |
| APIs | Grok + Hermes + cosmos-logos registration |

---

### 2.2 Agora — Sovereign Group Chat for Real Families

> "Join our Agora group." — and Slack is gone.

**Target:** Soccer moms. Husbands who tinker. Families in renovation. Neighborhoods. Anyone using a WhatsApp group or Slack channel they don't own.

**Stack:** Angular 17 + Tailwind + Google OAuth + Google Sheets. Familiar. Trusted. Google-native.

| Use Case | Who Deploys / Who Uses |
|---|---|
| Home renovation | Husband deploys. Wife manages. Contractor, designer, foreman text in. |
| Soccer team | Any parent deploys. Whole team uses. Coach broadcasts via SMS. |
| Neighborhood | One tech-curious neighbor sets it up. Everyone else just texts. |
| School project | Parent deploys for the kids. AI helps coordinate. Data stays home. |
| Small business | Owner deploys. No Slack subscription. No data on someone else's server. |

---

### 2.3 Thoth — Reference Implementation

**Stack:** Python + FastAPI + local Git + Anthropic Claude.

**Purpose:** Production-grade sovereign writing and code-review agent. The technical north star for advanced builders. Proves Python joins the grid on the same discovery protocol as PHP and Angular.

---

**Unified Truth (Grok v1.6 — accepted):**
All three run independently. All three are discovered identically via TurtleShell → Add Agent → URL. The cosmos-logos.json of each declares its runtime location and capabilities. TurtleShell is stack-agnostic. The Grid has no runtime preference.

---

## 3. Homepage & README Concepts

### 3.1 Homework Buddy — GitHub README Hero

```
╔══════════════════════════════════════════╗
║  Homework Buddy                          ║
║  Build your first AI agent.              ║
║                                          ║
║  Text it your homework.                  ║
║  It texts you back when it's due.        ║
║                                          ║
║  PHP. MySQL. Grok AI.                    ║
║  Runs on your own computer. Free.        ║
╚══════════════════════════════════════════╝
```

### README Quickstart — Written for a Kid

```bash
# You are about to build your first AI agent.
# This is real software. It runs on your computer. You built it.

# Step 1: Get the code
git clone https://github.com/cloudpremise/homework-buddy
cd homework-buddy

# Step 2: Start the app
docker-compose up

# Step 3: Open it
open http://localhost:8080

# That's it. Your AI agent is running.
# Now go to CUSTOMIZE.md to make it yours.
```

**Three paths below the quickstart:**
- **I just want to use it** — parent setup guide, 10 minutes
- **I want to understand it** — code walkthrough, every file explained
- **I want to build on it** — fork guide, first PR, contribution guide

---

### 3.2 Agora — Homepage Concept

```
╔══════════════════════════════════════════╗
║  Agora                                   ║
║  Your group. Your server. Your rules.    ║
║                                          ║
║  Private group chat with AI assist.      ║
║  Runs on your Mac Mini.                  ║
║                                          ║
║  Text in or use the full app.            ║
║  Powered by TurtleShell.ai               ║
╚══════════════════════════════════════════╝
```

---

## 4. Free Tier — Olympus-616 Goodwill Infrastructure

Olympus-616 provides two free services as goodwill to the universe. Not a freemium trap. An invitation. The upgrade is to ownership, not to a subscription.

| Service | Provider | What It Enables |
|---|---|---|
| Email validation | SendGrid via Olympus-616 | Free tier signup — no TurtleShell required |
| SMS reminders | Twilio via Hermes SMS | 10 messages/day free |
| Upgrade nudge | AI response at limit | "Download TurtleShell for unlimited — your data stays yours." |

**BYOK (Bring Your Own Keys) — accepted from Grok:**
Users may supply their own Twilio and SendGrid keys. When BYOK is configured, messaging bypasses Olympus-616 entirely. No Hermes or Proteus usage. Credentials stored locally. System remains fully functional offline.

```env
AI_MODE=local|grok
SMS_MODE=olympus|byok
EMAIL_MODE=olympus|byok
```

---

## 5. System Topology

| Domain | Component | Responsibility |
|---|---|---|
| Local Agent Node | Homework Buddy (PHP 8.2 + MySQL + Grok) | AI tutoring, data, offline execution |
| Local Agent Node | Thoth (Python + FastAPI + Claude) | Writing agent, reference implementation |
| Cloud Backbone | Olympus-616 (AWS ECS + Salesforce + Proteus) | Messaging, routing, Salesforce data layer, SendGrid |
| Interface Layer | TurtleShell.ai + cosmos-logos | Stack-agnostic discovery, UI, acquisition loop |
| Collaboration Room | Agora (Angular 17 + Google Stack) | Group collaboration, projects, tasks, assets, AI broker |
| Messaging Layer | Hermes SMS (Node.js, Olympus-616) | All SMS/WhatsApp/iMessage routing — pass-through only |
| Email Layer | SendGrid via Olympus-616 | Free tier validation, upgrade nudges |

**HARD CONSTRAINTS:**
- Cloud MUST NOT execute AI
- Local MUST NOT depend on cloud for core function
- Hermes is a router — no AI, no business logic, no persistence

---

## 6. Core Principles

### 6.1 Off-Grid Execution
Homework Buddy is fully functional without Olympus-616, TurtleShell.ai, or any external service. Hermes SMS and SendGrid are optional enhancements.

### 6.2 Sovereign Compute
Users retain full control of execution, full control of data, and the ability to operate disconnected.

### 6.3 Stack Agnosticism (Grok v1.6 — accepted)
The Grid embraces multiple runtimes within the same TurtleShell. PHP, Python, Angular coexist. The Grid does not favor any runtime. It only requires that each agent honors the cosmos-logos protocol.

### 6.4 Discovery Invariant (Grok v1.6 — accepted)
Every agent regardless of language MUST expose a valid cosmos-logos.json at `/.well-known/cosmos-logos.json`. TurtleShell discovers and routes to the exact endpoint declared in the manifest — `http://homework-buddy.local:8080`, `https://thoth.example.com`, or any valid URL.

### 6.5 Teach By Doing
Homework Buddy is a curriculum disguised as an application. The README is the textbook. The first pull request is the graduation.

### 6.6 Goodwill First
Ten free messages a day is an invitation. Olympus-616 absorbs the cost. This is the price of building a movement.

---

## 7. Component Architecture

### 7.1 Olympus-616 — Cloud Backbone

| Module | Responsibility |
|---|---|
| AWS ECS/Fargate | Compute layer — all Olympus-616 services run here |
| Salesforce Org | Production data layer — CloudPremise owned org |
| Proteus ORM | Data abstraction — bridges AWS to Salesforce objects |
| Hermes SMS | All SMS/WhatsApp/iMessage routing via Twilio — pass-through only |
| SendGrid | Email validation, free tier onboarding, upgrade nudges |
| Gate IDP | Identity — OAuth 2.0 PKCE, JWT entitlement claims |
| Ares | Security edge — all external traffic filtered here |

**Constraint:** Stateless coordination only. No AI. No application data. No business logic.

---

### 7.2 Hermes SMS

```
Inbound SMS → Twilio webhook → Hermes SMS
  └── group registry: phone number → agent type + group ID
  └── context fetch from agent context endpoint
  └── AI call (Gemini for Agora / Grok for Homework Buddy)
  └── store message + response via agent data_write_endpoint
  └── deliver via same inbound channel
```

**Rules:** No AI execution. No business logic. No data persistence. Router only.

**cosmos-logos registration:**
```json
POST /hermes/register
{
  "agent": "homework_buddy",
  "group_id": "{family_id}",
  "phone_number": "+1XXXXXXXXXX",
  "context_endpoint": "http://homework-buddy.local:8080/api/context/{family_id}",
  "data_write_endpoint": "http://homework-buddy.local:8080/api/messages",
  "ai_model": "grok",
  "channel": ["sms", "whatsapp", "imessage"]
}
```

---

### 7.3 Agora — Google-Native Group Collaboration

| Layer | Technology |
|---|---|
| Frontend | Angular 17 (standalone) + Tailwind CSS |
| Auth | Google OAuth 2.0 (Drive + Sheets + identity scopes) |
| Data | Google Sheets API v4 — one Sheet per group (5 tabs) |
| Files | Google Drive API v3 — per-group folder |
| AI (UI) | Gemini 1.5 Flash — direct CORS from Angular, no proxy |
| AI (SMS) | Gemini 1.5 Flash — via Hermes SMS context endpoint |
| Distribution | TurtleShell.ai via cosmos-logos.json |

**Google Sheets schema:**

| Tab | Columns | Purpose |
|---|---|---|
| messages | id, name, role, content, ai_response, channel, timestamp | Full log — UI and SMS unified |
| members | id, name, role, email, phone, channel_pref | Roster |
| projects | id, name, status, owner, description | Project cards |
| tasks | id, project, title, assignee, status, due | Tasks |
| assets | id, name, drive_id, mime_type, project, uploaded_by | Drive files |

**Role-aware AI broker:**

| Role | Gemini Behavior |
|---|---|
| owner | Decision framing, tradeoffs, high-level status |
| pm | Schedule impacts, resource conflicts, sequencing |
| decorator | Material options, aesthetic considerations, sourcing |
| foreman | Construction sequence, crew logistics, constraints |

---

### 7.4 Homework Buddy — PHP Local Agent

| Layer | Technology |
|---|---|
| Backend | PHP 8.2 + Laravel (REST API + webhook handler) |
| Database | MySQL 8 — assignments, reminders, members, messages, free_users |
| Frontend | PHP Blade templates (default) or Vue.js SPA |
| AI Model | Grok API (xAI) — PHP curl from Laravel controller |
| AI Mode | `local` (offline) or `grok` (default) or pluggable future |
| Email | SendGrid via Olympus-616 or BYOK |
| SMS | Hermes SMS (Olympus-616) or BYOK Twilio |
| Local discovery | mDNS / Bonjour — zero config on LAN |
| Optional exposure | ngrok or Cloudflare Tunnel — user-initiated, never required |
| Distribution | TurtleShell.ai via cosmos-logos.json at `/.well-known/` |

**MySQL schema:**

| Table | Key Columns | Purpose |
|---|---|---|
| families | id, name, phone_number, lock_flag, plan, created_at | One family = one group |
| members | id, family_id, name, role, phone, email, gate_user_id | role: parent or child |
| assignments | id, family_id, child_id, subject, description, due_date, added_by, status | All assignments |
| reminders | id, assignment_id, send_at, channel, status | Registered with Hermes |
| messages | id, family_id, sender, role, content, ai_response, channel, timestamp | Full log |
| free_users | id, email, validated, daily_count, last_reset, created_at | Freemium tier |

**Freemium tier:**

| Tier | Access | Upgrade Path |
|---|---|---|
| Free (email) | 10 msg/day, SendGrid validation, Grok AI, SMS reminders | "Download TurtleShell for unlimited — your data stays yours." |
| TurtleShell | Unlimited, parent lock, full UI, cosmos-logos citizen | Full Olympus-Grid sovereign user |

**Parent lock flag:** `lock_flag` boolean per family. When true, only `role = parent` can create/edit assignments. AI enforces and notifies parent when child attempts creation.

**AI role-aware behavior:**

| Sender | Grok Behavior |
|---|---|
| child (free) | Warm, encouraging, age-appropriate. Enforces 10 msg/day. |
| child (TurtleShell) | Same tone, no limit. Respects lock_flag. |
| parent (lock off) | Full access. Add/edit/delete. Full family context. |
| parent (lock on) | Same. Notifies parent when child attempts assignment creation. |

---

## 8. Acquisition Loop

### Homework Buddy
1. Kid signs up with email → SendGrid validates → 10 free messages/day
2. Kid hits daily limit → Grok: "Download TurtleShell for unlimited"
3. Kid installs TurtleShell → authenticates → Homework Buddy room surfaces
4. Kid is now a sovereign TurtleShell user. Their first AI agent brought them in.

### Agora
1. Wife discovers Agora → texts husband → husband clones repo on Mac Mini
2. Husband deploys → group created → Hermes SMS provisions phone number
3. Wife shares link or number → soccer team joins → each prompted to install TurtleShell
4. Each new member becomes a TurtleShell user. The group brought them in.

---

## 9. Data Flows

### 9.1 Sovereign — No Internet
```
User → Local Node (PHP + MySQL + Grok API)
     → Response delivered locally
     [Zero internet dependency]
```

### 9.2 Free Tier Email Validation
```
User signs up → POST to Olympus-616 SendGrid endpoint
     → SendGrid validation email
     → User clicks link → validated → 10 msg/day unlocked
```

### 9.3 SMS Flow
```
Child texts group phone number
     → Twilio → Hermes SMS (pass-through)
     → context fetch from local node endpoint
     → Grok API call (role-aware prompt + last 20 messages)
     → store to MySQL via data_write_endpoint
     → SMS response delivered
```

### 9.4 Reminder Flow
```
Assignment created → register with Hermes SMS
     → DynamoDB: { send_at: night-before 8pm + morning-of 7am }
     → EventBridge fires Lambda at scheduled time
     → Hermes SMS delivers via child's preferred channel
```

---

## 10. Local Node Exposure (Grok v1.6 — hardened)

### Primary — Sovereign Local Network
- mDNS / Bonjour — zero config on LAN (`http://homework-buddy.local:8080`)
- Manual URL entry in TurtleShell
- Docker Compose on same host — single command launch

### Optional — Global Access (User-Initiated Only)
- Cloudflare Tunnel — persistent, free tier available
- ngrok — development and demo use
- Tailscale / WireGuard — secure remote access

**Invariant:** Internet exposure is never required for core functionality. The cosmos-logos.json simply declares wherever the agent is actually listening.

---

## 11. cosmos-logos Manifest — Unified Schema (Grok v1.6)

Every agent MUST serve at `/.well-known/cosmos-logos.json`. No secrets. Public. No cloud dependencies required to read.

### Required Fields (expanded schema — Grok v1.6)

```
schema, version, schema_versions_supported
agent: { id, name, title, description, author, repository }
model: { provider, id, streaming, fallback }
capabilities: [ array of strings ]
auth: { type: "none" | "jwt" | "gate_idp" | "google" }
unlocks: [ UI surfaces in TurtleShell ]
entitlement: { free_tier, seashell_rates, developer }
persona: { system_prompt, voice }
discovery: { well_known, ping, health }
endpoint: "exact base URL where this agent runs"
```

### Homework Buddy
```json
{
  "schema": "cosmos-logos/agent",
  "version": "1.0.0",
  "agent": {
    "id": "homework-buddy",
    "name": "Homework Buddy",
    "title": "Build Your First AI Agent",
    "description": "Text it your homework. It texts you back.",
    "repository": "https://github.com/cloudpremise/homework-buddy"
  },
  "model": {
    "provider": "xai",
    "id": "grok-beta",
    "fallback": "local"
  },
  "capabilities": [
    "homework_tutoring",
    "local_ai",
    "offline_execution",
    "sms_reminders",
    "parent_controls",
    "open_source"
  ],
  "auth": { "type": "none" },
  "entitlement": {
    "free_tier": { "messages_per_day": 10 },
    "upgrade": "turtleshell"
  },
  "discovery": {
    "well_known": "/.well-known/cosmos-logos.json",
    "ping": "/ping",
    "health": "/health"
  },
  "endpoint": "http://homework-buddy.local:8080"
}
```

### Agora
```json
{
  "schema": "cosmos-logos/agent",
  "version": "1.0.0",
  "agent": {
    "id": "agora",
    "name": "Agora",
    "title": "Your group. Your server. Your rules.",
    "description": "Private group collaboration with AI assist.",
    "repository": "https://github.com/cloudpremise/agora"
  },
  "model": {
    "provider": "google",
    "id": "gemini-1.5-flash",
    "streaming": true
  },
  "capabilities": [
    "group_collaboration",
    "projects",
    "tasks",
    "assets",
    "sms_channel",
    "ai_broker"
  ],
  "auth": {
    "type": "google",
    "scopes": ["openid", "email", "drive", "spreadsheets"]
  },
  "discovery": {
    "well_known": "/.well-known/cosmos-logos.json",
    "ping": "/ping",
    "health": "/health"
  },
  "endpoint": "http://agora.local:4200"
}
```

### Thoth (Reference)
```json
{
  "schema": "cosmos-logos/agent",
  "version": "1.0.0",
  "agent": {
    "id": "thoth",
    "name": "Thoth",
    "title": "Sovereign Writing Agent",
    "description": "AI-assisted writing and code review on your own hardware.",
    "repository": "https://github.com/cloudpremise/thoth"
  },
  "model": {
    "provider": "anthropic",
    "id": "claude-sonnet-4-6",
    "streaming": true
  },
  "capabilities": [
    "writing_assistant",
    "code_review",
    "local_ai",
    "git_backed",
    "offline_execution"
  ],
  "auth": { "type": "none" },
  "discovery": {
    "well_known": "/.well-known/cosmos-logos.json",
    "ping": "/ping",
    "health": "/health"
  },
  "endpoint": "http://thoth.local:8000"
}
```

---

## 12. Open Runtime Adapter Protocol

| Runtime | Agent | Status |
|---|---|---|
| Angular / TypeScript | Agora | **REFERENCE — Google-native, soccer mom deployment** |
| PHP 8.2 / Laravel | Homework Buddy | **REFERENCE — local-first, kids build this** |
| Python / FastAPI | Thoth | **REFERENCE — advanced builders, technical north star** |
| Node.js | Athena adapter | Spec published — build on signal |
| Swift | TurtleShell iOS | Spec published — build on signal |
| Any runtime | Community | Implement cosmos-logos contract — self-register |

---

## 13. Build Sequence — Super Agent

| # | Deliverable | Component | Dependency |
|---|---|---|---|
| 0 | Finalize unified cosmos-logos schema (all three agents honor this) | Protocol | None — schema first |
| 1 | Hermes SMS + Twilio webhooks + SendGrid endpoint | Olympus-616 | Step 0 |
| 2 | DynamoDB group registry + EventBridge reminders | Olympus-616 | Step 1 |
| 3a | Agora Angular SPA + Google services + Sheets schema | Agora | Step 1 |
| 3b | Homework Buddy PHP/Laravel + MySQL + Grok + SendGrid + BYOK | Homework Buddy | Step 1 |
| 3c | README quickstart + kid docs + CUSTOMIZE.md | Homework Buddy | Step 3b |
| 4 | All agents register with Hermes SMS | All | Steps 2 + 3a + 3b |
| 5 | cosmos-logos manifests at `/.well-known/` for all agents | All | Step 4 |
| 6 | TurtleShell discovers all three agents via manifest | TurtleShell.ai | Step 5 |
| 7 | Owl Roost (Agora) + first Homework Buddy family live | Both | Step 6 |
| 8 | Adapter spec published — all runtimes build simultaneously | Network | Step 7 |

---

## 14. Open Questions for Super Agent

- Grok API — confirm current production model string for PHP curl
- cosmos-logos `endpoint` field — confirm local `.local` addresses resolve correctly in TurtleShell discovery
- Agora Google Sheets ownership — creator-owned shared vs service account
- Homework Buddy UI — Blade vs Vue.js for TurtleShell embedding
- Lock flag UX — settings toggle vs SMS command vs both
- Freemium daily reset — midnight UTC vs user local timezone
- Docker Compose — confirm single file includes PHP + MySQL + optional ngrok profile
- BYOK mode — confirm credential storage pattern (`.env` local only, never in cosmos-logos.json)
- SendGrid template IDs — confirm Olympus-616 account template IDs for validation email
- Thoth model string — confirm `claude-sonnet-4-6` is correct for cosmos-logos schema

---

*v1.0 Thoth (PM baseline) · v1.2 Athena (topology, Salesforce/Proteus) · v1.3 Grok (sovereignty hardening) · v1.4 Thoth (curriculum + soccer mom positioning + SendGrid) · v1.5 Athena (architecture hardened) · v1.6 Grok (stack agnosticism, unified schema, Thoth added) + Thoth PM final (soul restored)*

*CloudPremise LLC | TurtleShell.ai | Olympus-616 | March 2026*
*Next: Super Agent build — Step 0 is cosmos-logos schema finalization*