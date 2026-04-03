#!/bin/bash
# ═══════════════════════════════════════════════════════════════════════
# COSMIC TURTLE — cosmos-logos Development Bootstrap Agent
# ═══════════════════════════════════════════════════════════════════════
# The Cosmic Turtle carries the world on its back.
#
# Bootstraps all four TurtleShell UI surfaces, bumps them to a
# consistent version number, verifies connectivity, and launches
# a development agent with full context across the entire stack.
#
# Usage:
#   ./cosmicturtle.sh              # Auto-increment patch version
#   ./cosmicturtle.sh 1.8.0        # Set explicit version
#
# ═══════════════════════════════════════════════════════════════════════
#
# ARCHITECTURE
#
#   Four UI surfaces share the cosmos-logos v1.0.3 protocol
#   (Ed25519 sealed envelopes) and present the same agent catalog:
#
#   ┌─────────────────────────────────────────────────────────────┐
#   │  Surface              Port    Protocol   Hot Reload         │
#   │  ─────────────────────────────────────────────────────────  │
#   │  turtleshell-web      5173    HTTPS      Vite HMR           │
#   │  iris portal          5174    HTTP       Vite HMR           │
#   │  turtleshell-offgrid  717     HTTP       Restart required   │
#   │  turtleshell-ios      Sim     N/A        Xcode rebuild      │
#   └─────────────────────────────────────────────────────────────┘
#
#   turtleshell-web (port 5173) — Canonical SaaS client at turtleshell.ai.
#     Repo: cosmos-logos/turtleshell-web. Vite + React + TypeScript + Tailwind.
#     Auto-deploys to Netlify on merge to brain/1.7.x.x.
#
#   iris portal (port 5174) — Salesforce Experience Cloud portal version.
#     Lives inside olympus-616/iris/reactforce/turtleshell.
#     Deploy: npm run deployAlpha (builds + pushes static resource to alpha-org)
#     Deploy: npm run publishTurtleshell + sf project deploy start (scratch orgs)
#
#   turtleshell-offgrid (port 717) — On-premises server + built web bundle.
#     Repo: cosmos-logos/turtleshell-offgrid. Node/Express.
#     Serves production build from status/web/ (rebuilt from turtleshell-web).
#     Proxies /v1/* to local Ares fleet on port 3451.
#     Update: cd turtleshell-web/ui && npm run build && cp -r dist/* ../turtleshell-offgrid/status/web/
#     Then restart: kill the node process, cd status && node server.js
#
#   turtleshell-ios (Simulator) — Native iOS app. Pure Swift, zero dependencies.
#     Repo: cosmos-logos/turtleshell-ios.
#     Build: xcodebuild -scheme TurtleShell.ai -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' -derivedDataPath build build
#     Install: xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/TurtleShell.ai.app
#     Launch: xcrun simctl launch booted ai.turtleshell.TurtleShell-ai
#
# ═══════════════════════════════════════════════════════════════════════
#
# VERSION SURFACES (all must match)
#
#   turtleshell-web:
#     - ui/package.json                          → "version" field
#     - ui/src/routes/Settings.tsx               → About section display
#     - ui/src/lib/download.ts                   → DOWNLOAD.version constant
#   iris portal:
#     - reactforce/turtleshell/.../Chatbot.tsx   → IRIS_CHAT_VERSION constant
#   turtleshell-offgrid:
#     - ~/.turtleshell/manifest.json             → "version" field (read by getNodeInfo())
#     - status/server.js                         → fallback version strings
#   turtleshell-ios:
#     - project.pbxproj                          → MARKETING_VERSION (all build configs)
#     - Views/HomeView.swift                     → reads AppInfo.version dynamically
#
# ═══════════════════════════════════════════════════════════════════════
#
# PORT ASSIGNMENTS (MUST NOT collide)
#
#   5173  turtleshell-web      (Vite dev, HTTPS via basicSsl plugin)
#   5174  iris turtleshell portal (Vite dev, HTTP)
#   717   turtleshell-offgrid  (Node/Express, HTTP unless certs present)
#   718   turtleshell-offgrid  HTTP redirect (when HTTPS enabled on 717)
#   3451  Ares API gateway     (offgrid fleet proxies here)
#
# ═══════════════════════════════════════════════════════════════════════
#
# GIT WORKFLOW
#
#   All repos use custom git aliases. NEVER use raw git branch/commit/push.
#
#   git newthought <label>     — Create feature branch from brain/1.7.x.x
#   git add <files>            — Stage specific files (never git add -A)
#   git savethought <label>    — Commit and push to origin
#   git mainbrain              — Switch back to brain/1.7.x.x
#   git pull                   — Pull latest from origin
#   git cleanthoughts          — Delete merged feature branches
#
#   GitHub auth:
#     cosmos-logos repos → gh auth switch --user root-of-trust
#     olympus-616 repos → gh auth switch --user alchemisthomer
#
#   PR creation:
#     gh pr create --title "..." --body "..."
#     Switch gh user BEFORE creating PRs in each org.
#
#   NEVER add Co-Authored-By lines to commits.
#
# ═══════════════════════════════════════════════════════════════════════
#
# DEPLOYMENT CHECKLIST (after feature is complete)
#
#   1. turtleshell-web:
#      Merge PR to brain/1.7.x.x → auto-deploys to turtleshell.ai via Netlify
#
#   2. turtleshell-offgrid:
#      Rebuild web bundle: cd turtleshell-web/ui && npm run build
#      Copy: cp -r dist/* ../turtleshell-offgrid/status/web/
#      Merge PR → triggers Docker build + macOS .pkg signing
#
#   3. iris portal:
#      Deploy to scratch org:
#        cd olympus-616/iris && npm run publishTurtleshell
#        cd olympus-616/olympus-grid && sf project deploy start \
#          --source-dir force-app/ui/portal/default/staticresources/turtleshell \
#          --source-dir force-app/ui/portal/default/staticresources/turtleshell.resource-meta.xml \
#          --target-org dev_enterprise
#      Deploy to alpha org (production managed package):
#        cd olympus-616/iris && npm run deployAlpha
#      Open orgs:
#        cd olympus-616/olympus-grid && sf org open --target-org dev_enterprise
#        cd olympus-616/olympus-grid && sf org open --target-org alpha-org
#
#   4. turtleshell-ios:
#      Merge PR → manual Xcode build + TestFlight upload
#
# ═══════════════════════════════════════════════════════════════════════
#
# MCP INTEGRATION (cosmos-logos → Athena)
#
#   When a cosmos-logos agent with capability verb "x-mcp" is connected
#   (e.g., Poseidon), the UI passes an mcpServers array in the POST body
#   of /v1/athena/chat:
#
#   {
#     "prompt": "...",
#     "mcpServers": [{
#       "namespace": "poseidon-616",
#       "url": "<agent.url + capability.path>",
#       "manifestUrl": "<agent.url>/.well-known/cosmos-logos.json",
#       "verified": true
#     }]
#   }
#
#   MCP URL construction:
#     1. agent.url = the URL used during handshake (e.g., https://athena-616.ngrok.io/v1/poseidon)
#     2. manifestUrl = agent.url + "/.well-known/cosmos-logos.json"
#     3. Find capability with verb === "x-mcp" → get its path
#     4. mcpUrl = agent.url + capability.path
#
#   Files implementing mcpServers body:
#     turtleshell-web:  ui/src/lib/athena/chat-client.ts
#     iris portal:      reactforce/turtleshell/.../Chatbot.tsx
#     turtleshell-ios:  Network/ChatService.swift (McpServerEntry struct)
#
#   iOS sealed envelope format:
#     iOS uses CryptoKit (ChaChaPoly + Curve25519 ECDH with Ed25519→X25519
#     birational map). The body includes "format":"apple-cryptokit" so the
#     backend knows to use the CryptoKit-compatible decryption path.
#     Both Athena and Poseidon must support this format.
#
# ═══════════════════════════════════════════════════════════════════════
#
# PREREQUISITES
#
#   - Node.js (v22+), npm
#   - Xcode with iOS Simulator
#   - Salesforce CLI (sf) for portal deployments
#   - GitHub CLI (gh) with both root-of-trust and alchemisthomer accounts
#   - All cosmos-logos repos cloned under the cosmos-logos parent directory
#   - olympus-616/iris and olympus-616/olympus-grid cloned as siblings
#   - ~/.turtleshell/manifest.json present (created by installer)
#
# ═══════════════════════════════════════════════════════════════════════

set -euo pipefail

# ── Paths ─────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
COSMOS_DIR="$(dirname "$SCRIPT_DIR")"
OLYMPUS_DIR="$(dirname "$COSMOS_DIR")/olympus-616"
MANIFEST="$HOME/.turtleshell/manifest.json"
LOG_DIR="/tmp/cosmicturtle"

mkdir -p "$LOG_DIR"

# ── Banner ────────────────────────────────────────────────────────────
echo ""
echo "  ═══════════════════════════════════════════════════"
echo "  ║     C O S M I C   T U R T L E                  ║"
echo "  ║     cosmos-logos development bootstrap          ║"
echo "  ═══════════════════════════════════════════════════"
echo ""

# ── Resolve version ───────────────────────────────────────────────────
CURRENT_VERSION=$(node -e "console.log(require('$COSMOS_DIR/turtleshell-web/ui/package.json').version)" 2>/dev/null || echo "1.7.0")

if [ -n "${1:-}" ]; then
  VERSION="$1"
else
  MAJOR=$(echo "$CURRENT_VERSION" | cut -d. -f1)
  MINOR=$(echo "$CURRENT_VERSION" | cut -d. -f2)
  PATCH=$(echo "$CURRENT_VERSION" | cut -d. -f3)
  PATCH=$((PATCH + 1))
  VERSION="${MAJOR}.${MINOR}.${PATCH}"
fi

echo "  Version: $CURRENT_VERSION → $VERSION"
echo ""

# ── Verify repos exist ───────────────────────────────────────────────
COSMOS_REPOS=(turtleshell-web turtleshell-offgrid turtleshell-ios thoth homework-buddy agora .github)
MISSING=()

for repo in "${COSMOS_REPOS[@]}"; do
  if [ ! -d "$COSMOS_DIR/$repo" ]; then
    MISSING+=("$repo")
  fi
done

if [ ! -d "$OLYMPUS_DIR/iris/reactforce/turtleshell" ]; then
  MISSING+=("olympus-616/iris")
fi

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "  ✗ Missing repos: ${MISSING[*]}"
  echo "  Clone them first."
  exit 1
fi

echo "  Repos:"
for repo in "${COSMOS_REPOS[@]}"; do
  branch=$(cd "$COSMOS_DIR/$repo" && git branch --show-current 2>/dev/null || echo "???")
  echo "    [✓] cosmos-logos/$repo ($branch)"
done
IRIS_BRANCH=$(cd "$OLYMPUS_DIR/iris" && git branch --show-current 2>/dev/null || echo "???")
echo "    [✓] olympus-616/iris ($IRIS_BRANCH)"
echo ""

# ── Kill stale processes on our ports ─────────────────────────────────
echo "  Clearing ports..."
for PORT in 5173 5174 717; do
  PIDS=$(lsof -ti TCP:$PORT -sTCP:LISTEN 2>/dev/null || true)
  if [ -n "$PIDS" ]; then
    echo "$PIDS" | xargs kill 2>/dev/null || true
    echo "    Killed stale process(es) on :$PORT"
  fi
done
sleep 1
echo ""

# ══════════════════════════════════════════════════════════════════════
# VERSION BUMP — All four surfaces
# ══════════════════════════════════════════════════════════════════════
echo "  Bumping all surfaces to v${VERSION}..."

# ── 1. turtleshell-web ───────────────────────────────────────────────
node -e "
  const fs = require('fs');
  const p = '$COSMOS_DIR/turtleshell-web/ui/package.json';
  const pkg = JSON.parse(fs.readFileSync(p, 'utf8'));
  pkg.version = '$VERSION';
  fs.writeFileSync(p, JSON.stringify(pkg, null, 2) + '\n');
"
sed -i '' "s|<span className=\"font-mono text-text-secondary\">[^<]*</span>|<span className=\"font-mono text-text-secondary\">${VERSION}</span>|" \
  "$COSMOS_DIR/turtleshell-web/ui/src/routes/Settings.tsx"
sed -i '' "s|version: '[^']*'|version: '${VERSION}'|" \
  "$COSMOS_DIR/turtleshell-web/ui/src/lib/download.ts"
echo "    [✓] turtleshell-web"

# ── 2. iris portal ───────────────────────────────────────────────────
IRIS_CHATBOT="$OLYMPUS_DIR/iris/reactforce/turtleshell/src/plugins/turtleshell/src/components/Chatbot.tsx"
sed -i '' "s|const IRIS_CHAT_VERSION = \"[^\"]*\"|const IRIS_CHAT_VERSION = \"v${VERSION}\"|" "$IRIS_CHATBOT"
echo "    [✓] iris portal"

# ── 3. turtleshell-offgrid ──────────────────────────────────────────
if [ -f "$MANIFEST" ]; then
  node -e "
    const fs = require('fs');
    const m = JSON.parse(fs.readFileSync('$MANIFEST', 'utf8'));
    m.version = '$VERSION';
    fs.writeFileSync('$MANIFEST', JSON.stringify(m, null, 2) + '\n');
  "
fi
sed -i '' "s|version: '[0-9]*\.[0-9]*\.[0-9]*'|version: '${VERSION}'|g" \
  "$COSMOS_DIR/turtleshell-offgrid/status/server.js"
echo "    [✓] turtleshell-offgrid"

# ── 4. turtleshell-ios ──────────────────────────────────────────────
PBXPROJ="$COSMOS_DIR/turtleshell-ios/TurtleShell.ai/TurtleShell.ai.xcodeproj/project.pbxproj"
sed -i '' "s|MARKETING_VERSION = [^;]*;|MARKETING_VERSION = ${VERSION};|g" "$PBXPROJ"
echo "    [✓] turtleshell-ios"

echo ""

# ══════════════════════════════════════════════════════════════════════
# START SERVICES
# ══════════════════════════════════════════════════════════════════════

# ── 1. turtleshell-web (port 5173, HTTPS) ────────────────────────────
echo "  Starting turtleshell-web on :5173..."
cd "$COSMOS_DIR/turtleshell-web/ui"
if [ ! -d node_modules ]; then npm install --silent 2>/dev/null; fi
npm run dev > "$LOG_DIR/web.log" 2>&1 &
WEB_PID=$!
echo "    PID $WEB_PID → $LOG_DIR/web.log"

# ── 2. iris portal (port 5174, HTTP) ─────────────────────────────────
echo "  Starting iris portal on :5174..."
cd "$OLYMPUS_DIR/iris"
npm run turtleshell > "$LOG_DIR/iris.log" 2>&1 &
IRIS_PID=$!
echo "    PID $IRIS_PID → $LOG_DIR/iris.log"

# ── 3. turtleshell-offgrid (port 717, HTTP) ─────────────────────────
echo "  Starting turtleshell-offgrid on :717..."
cd "$COSMOS_DIR/turtleshell-offgrid/status"
node server.js > "$LOG_DIR/offgrid.log" 2>&1 &
OFFGRID_PID=$!
echo "    PID $OFFGRID_PID → $LOG_DIR/offgrid.log"

# ── 4. turtleshell-ios (Simulator) ──────────────────────────────────
echo "  Building turtleshell-ios for Simulator..."
XCODEPROJ="$COSMOS_DIR/turtleshell-ios/TurtleShell.ai/TurtleShell.ai.xcodeproj"
IOS_PID=""
if [ -d "$XCODEPROJ" ]; then
  BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -c "Booted" || echo "0")
  if [ "$BOOTED" = "0" ]; then
    SIM_ID=$(xcrun simctl list devices available -j 2>/dev/null | \
      python3 -c "
import sys, json
d = json.load(sys.stdin)['devices']
devs = [v for k, vs in d.items() for v in vs if v['isAvailable'] and 'iPhone' in v.get('name','')]
print(devs[0]['udid'] if devs else '')
" 2>/dev/null)
    if [ -n "$SIM_ID" ]; then
      xcrun simctl boot "$SIM_ID" 2>/dev/null
      echo "    Booted simulator: $SIM_ID"
    fi
  fi
  open -a Simulator 2>/dev/null

  (
    xcodebuild -project "$XCODEPROJ" \
      -scheme "TurtleShell.ai" \
      -destination "platform=iOS Simulator,name=iPhone 17 Pro Max" \
      -derivedDataPath "$COSMOS_DIR/turtleshell-ios/build" \
      build > "$LOG_DIR/ios-build.log" 2>&1 && \
    xcrun simctl install booted \
      "$COSMOS_DIR/turtleshell-ios/build/Build/Products/Debug-iphonesimulator/TurtleShell.ai.app" && \
    xcrun simctl terminate booted ai.turtleshell.TurtleShell-ai 2>/dev/null; \
    xcrun simctl launch booted ai.turtleshell.TurtleShell-ai
  ) &
  IOS_PID=$!
  echo "    Build PID $IOS_PID → $LOG_DIR/ios-build.log"
else
  echo "    ✗ Xcode project not found — skipping"
fi
echo ""

# ── Wait for servers to bind ─────────────────────────────────────────
echo "  Waiting for servers..."
sleep 4

# ── Verify connectivity ──────────────────────────────────────────────
echo ""
echo "  Connectivity check:"

check_port() {
  local name="$1" port="$2" proto="${3:-http}"
  if lsof -iTCP:$port -sTCP:LISTEN >/dev/null 2>&1; then
    echo "    [✓] $name → ${proto}://localhost:${port}"
  else
    echo "    [✗] $name → port $port NOT listening"
  fi
}

check_port "turtleshell-web"      5173 "https"
check_port "iris portal"          5174 "http"
check_port "turtleshell-offgrid"  717  "http"

if lsof -iTCP:3451 -sTCP:LISTEN >/dev/null 2>&1; then
  echo "    [✓] Ares fleet → http://localhost:3451"
else
  echo "    [~] Ares fleet → not running (offgrid API proxy will 502)"
fi

SIM_BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep "Booted" | head -1 | sed 's/.*(\(.*\)) (Booted)/\1/' || true)
if [ -n "$SIM_BOOTED" ]; then
  SIM_NAME=$(xcrun simctl list devices booted 2>/dev/null | grep "Booted" | head -1 | sed 's/    \(.*\) (.*/\1/')
  echo "    [✓] iOS Simulator → $SIM_NAME"
else
  echo "    [~] iOS Simulator → no device booted"
fi

echo ""

# ── Write cleanup script ─────────────────────────────────────────────
cat > "$LOG_DIR/cleanup.sh" <<CLEANUP
#!/bin/bash
echo "Stopping Cosmic Turtle services..."
kill $WEB_PID $IRIS_PID $OFFGRID_PID ${IOS_PID:-0} 2>/dev/null
echo "All services stopped."
CLEANUP
chmod +x "$LOG_DIR/cleanup.sh"

# ── Summary ──────────────────────────────────────────────────────────
echo "  ═══════════════════════════════════════════════════"
echo "  ║  All surfaces running at v${VERSION}"
echo "  ║"
echo "  ║  turtleshell-web      https://localhost:5173"
echo "  ║  iris portal          http://localhost:5174"
echo "  ║  turtleshell-offgrid  http://localhost:717"
echo "  ║  turtleshell-ios      Simulator"
echo "  ║"
echo "  ║  Logs:    $LOG_DIR/"
echo "  ║  Cleanup: $LOG_DIR/cleanup.sh"
echo "  ═══════════════════════════════════════════════════"
echo ""

# ══════════════════════════════════════════════════════════════════════
# LAUNCH DEVELOPMENT AGENT
# ══════════════════════════════════════════════════════════════════════

PROMPT="You are the Cosmic Turtle — the development agent for the cosmos-logos organization.

Your working directory is: ${COSMOS_DIR}

You have full read and write access across all cosmos-logos repositories:

TurtleShell Applications:
  - turtleshell-web      — Web app (Vite + React + TypeScript + Tailwind) — running at https://localhost:5173
  - turtleshell-offgrid  — Off-Grid dashboard + reverse proxy (Node/Express) — running at http://localhost:717
  - turtleshell-ios      — iOS app (Swift/SwiftUI/CryptoKit) — running in Simulator

Iris Portal:
  - olympus-616/iris/reactforce/turtleshell — Salesforce Experience Cloud portal — running at http://localhost:5174

All four surfaces are at v${VERSION}.

Cosmos-Logos Agents:
  - thoth                — Sovereign writing agent (Python/FastAPI)
  - homework-buddy       — AI homework tutor (Laravel/PHP)
  - agora                — Group collaboration (Angular/Node)

Protocol:
  - .github              — Org-level config, manifesto, architecture docs
  - All agents use cosmos-logos v1.0.3 protocol (Ed25519 sealed envelopes)

Git conventions (MUST follow):
  - Create feature branch: git newthought <label>
  - Commit and push: git add <files> && git savethought <label>
  - Return to main: git mainbrain && git pull && git cleanthoughts
  - Main branch: brain/1.7.x.x
  - NEVER use raw git branch, git commit, or git push
  - Origin remote points to cosmos-logos GitHub org
  - GitHub auth: root-of-trust for cosmos-logos repos, alchemisthomer for olympus-616 repos

CI/CD:
  - turtleshell-web: push to brain/1.7.x.x auto-deploys to turtleshell.ai via Netlify
  - PRs get Netlify preview URLs commented automatically

Deployment (after merge):
  - turtleshell-offgrid: rebuild web bundle (cd turtleshell-web/ui && npm run build && cp -r dist/* ../turtleshell-offgrid/status/web/) then restart server
  - iris portal scratch org: cd olympus-616/iris && npm run publishTurtleshell, then cd olympus-616/olympus-grid && sf project deploy start --source-dir force-app/ui/portal/default/staticresources/turtleshell --source-dir force-app/ui/portal/default/staticresources/turtleshell.resource-meta.xml --target-org dev_enterprise
  - iris portal alpha org: cd olympus-616/iris && npm run deployAlpha
  - Open orgs: cd olympus-616/olympus-grid && sf org open --target-org dev_enterprise (or alpha-org)

Version Surface Map (for future bumps):
  turtleshell-web:
    - ui/package.json                          → \"version\" field
    - ui/src/routes/Settings.tsx               → About section display
    - ui/src/lib/download.ts                   → DOWNLOAD.version constant
  iris portal:
    - reactforce/turtleshell/.../Chatbot.tsx   → IRIS_CHAT_VERSION constant
  turtleshell-offgrid:
    - ~/.turtleshell/manifest.json             → \"version\" field (read by getNodeInfo())
    - status/server.js                         → fallback version strings
  turtleshell-ios:
    - project.pbxproj                          → MARKETING_VERSION (all build configs)
    - Views/HomeView.swift                     → reads AppInfo.version dynamically

Port Assignments (do not change):
  5173  turtleshell-web      (Vite HTTPS, HMR)
  5174  iris portal          (Vite HTTP, HMR)
  717   turtleshell-offgrid  (Node HTTP, restart to see changes)
  3451  Ares API gateway     (fleet service, proxied by offgrid /v1/*)

Hot Reload Behavior:
  - turtleshell-web (5173): Vite HMR — edits to ui/src/ appear instantly
  - iris portal (5174): Vite HMR — edits to reactforce/turtleshell/src/ appear instantly
  - turtleshell-offgrid (717): No HMR — kill and restart node server.js after edits
  - turtleshell-ios: No HMR — xcodebuild + simctl install + simctl launch after edits

MCP Integration:
  - Agents with capability verb 'x-mcp' (e.g., Poseidon) are MCP tool servers
  - When connected, pass mcpServers array in POST body to /v1/athena/chat
  - mcpServers: [{ namespace, url (agent.url + cap.path), manifestUrl (agent.url + /.well-known/cosmos-logos.json), verified: true }]
  - iOS uses 'apple-cryptokit' format for sealed envelopes (ChaChaPoly + X25519 via Ed25519 birational map)

You are the shell that protects. Build well."

BOOT_COMMAND="Start the Cosmic Turtle development session:

1. Read CLAUDE.md in .github/ for org-level conventions
2. Briefly report the status of each running app (web, offgrid, iris portal, iOS)
3. Ask what the user wants to work on

The Cosmic Turtle is awake. All shells are online."

cd "$COSMOS_DIR"
claude --dangerously-skip-permissions --append-system-prompt "$PROMPT" "$BOOT_COMMAND"

# ── Cleanup on exit ───────────────────────────────────────────────────
echo ""
echo "  Cosmic Turtle going to sleep..."
bash "$LOG_DIR/cleanup.sh"
