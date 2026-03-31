# CLAUDE.md — cosmos-logos Organization

This file provides guidance to Claude Code when working in any cosmos-logos repository.

## What Is cosmos-logos

cosmos-logos is the open agent discovery protocol and the organization that owns the TurtleShell client ecosystem. It defines how sovereign AI agents identify, discover, and authenticate each other — independent of any specific infrastructure.

Olympus-616 is the backend fleet (the gods). cosmos-logos is the protocol and the client applications.

## Organization Repositories

| Repository | Purpose | Deploy Target |
|------------|---------|---------------|
| **turtleshell-web** | Web client (Vite + React + TypeScript + Tailwind) | turtleshell.ai via Netlify |
| **turtleshell-offgrid** | Off-grid server + UI (Node.js Express + React) | Docker / macOS .pkg |
| **turtleshell-ios** | iOS native client (Pure Swift, zero dependencies) | App Store |
| **thoth** | Writing agent | Olympus-616 fleet |
| **homework-buddy** | Tutoring agent | Olympus-616 fleet |
| **agora** | Group collaboration agent | Olympus-616 fleet |
| **.github** | Org-level docs, protocol spec, CLAUDE.md | N/A |

## cosmos-logos Protocol v1.0.3

The protocol uses **Ed25519 sealed envelopes** for agent authentication.

### Discovery

Every agent publishes a manifest at `/.well-known/cosmos-logos.json`. This manifest contains:
- Agent identity and capabilities
- System prompt (`identity.system_prompt`)
- Display settings (`display.visible: true/false`)
- Supported deployment modes

### Sealed Envelope Flow

1. Client generates Ed25519 keypair
2. Client sends public key to agent in a sealed envelope
3. Agent decrypts and returns a **SHA-256 hash proof** — NEVER the plaintext
4. Hash comparison proves successful decryption
5. Ed25519 verification is MANDATORY during agent connection. No exceptions.

### Three Deployment Modes

Every agent supports three connection modes:

| Mode | Description |
|------|-------------|
| **Olympus-Grid** | Cloud deployment at olympus-grid.ai. Full fleet, managed infrastructure. |
| **Developer** | Local development via ngrok tunnel. Same fleet, developer machine. |
| **Off-Grid** | Fully local on-premises. Docker fleet on Mac Mini or any machine. Port 717. |

## Architecture Principles

- Agents own their own manifests — NOT the gateway (Ares). Ares is the security perimeter only.
- Capabilities unlock dynamically: connect Poseidon -> MCP tools appear. Disconnect -> gone.
- Background service agents (Poseidon, Apollo) default to `display.visible: false`.
- Per-agent chat threading: each agent has independent message history.
- Custom agents are built-in agents with `systemPrompt` and `voice` — they route through Athena like everything else.

## Git Workflow

All cosmos-logos repos use the same workflow. The main branch is `brain/1.7.x.x`.

```bash
git newthought    # Create a new feature branch from brain/1.7.x.x
git savethought   # Stage and commit current work
git mainbrain     # Merge current branch back to brain/1.7.x.x
git cleanthoughts # Clean up merged branches
```

## Rules

- **NEVER** commit directly to `brain/1.7.x.x`. Always use feature branches.
- **NEVER** add `Co-Authored-By` lines to commits.
- **NEVER** run git add, git commit, or git push. Only Gregory does staging, commits, and pushes. Edit files locally and report what changed.

## CI/CD

| Repository | Trigger | Pipeline |
|------------|---------|----------|
| turtleshell-web | Merge to `brain/1.7.x.x` | Auto-deploy to turtleshell.ai via Netlify |
| turtleshell-web | PR opened | Netlify preview URL commented on PR |
| turtleshell-offgrid | Merge to `brain/1.7.x.x` | Docker build (multi-arch) + sign macOS .pkg -> GitHub Release |
| turtleshell-ios | Manual | Xcode build + TestFlight |

## License

GNU AGPL v3. All network-facing code must disclose source. Keep this in mind when adding dependencies.
