#!/bin/bash
# ═══════════════════════════════════════════════════════
# COSMIC TURTLE — cosmos-logos Development Agent
# ═══════════════════════════════════════════════════════
# The Cosmic Turtle carries the world on its back.
# Bootstraps all TurtleShell apps + cosmos-logos agents,
# then launches a focused development agent for the cosmos-logos org.
#
# Usage: ./cosmicturtle.sh
# ═══════════════════════════════════════════════════════

REPOS_DIR="$(cd "$(dirname "$0")" && pwd)"
COSMOS_DIR="$REPOS_DIR/cosmos-logos"

echo ""
echo "  ═══════════════════════════════════════════════"
echo "  ║     C O S M I C   T U R T L E              ║"
echo "  ║     cosmos-logos dev agent                  ║"
echo "  ═══════════════════════════════════════════════"
echo ""

# ── Verify repos exist ────────────────────────────────
REPOS=(turtleshell-web turtleshell-offgrid turtleshell-ios thoth homework-buddy agora)
MISSING=()

for repo in "${REPOS[@]}"; do
  if [ ! -d "$COSMOS_DIR/$repo" ]; then
    MISSING+=("$repo")
  fi
done

if [ ${#MISSING[@]} -gt 0 ]; then
  echo "  Missing repos: ${MISSING[*]}"
  echo "  Clone them into $COSMOS_DIR first."
  echo ""
  exit 1
fi

echo "  Repos:"
for repo in "${REPOS[@]}"; do
  branch=$(cd "$COSMOS_DIR/$repo" && git branch --show-current 2>/dev/null || echo "???")
  echo "    [✓] $repo ($branch)"
done
echo ""

# ── 1. Start turtleshell-web dev server ───────────────
echo "  Starting turtleshell-web (Vite)..."
cd "$COSMOS_DIR/turtleshell-web/ui"
if [ ! -d node_modules ]; then npm install --silent 2>/dev/null; fi
npm run dev > /tmp/cosmicturtle-web.log 2>&1 &
WEB_PID=$!
echo "    PID: $WEB_PID → log: /tmp/cosmicturtle-web.log"

# Wait for Vite to bind
sleep 2
WEB_URL=$(grep -oE 'https?://localhost:[0-9]+' /tmp/cosmicturtle-web.log | head -1)
if [ -z "$WEB_URL" ]; then WEB_URL="https://localhost:5173"; fi
echo "    URL: $WEB_URL"
echo ""

# ── 2. Start turtleshell-offgrid status server ────────
echo "  Starting turtleshell-offgrid (Node)..."
cd "$COSMOS_DIR/turtleshell-offgrid/status"
if [ ! -d node_modules ]; then npm install --silent 2>/dev/null; fi
PORT=6160 node server.js > /tmp/cosmicturtle-offgrid.log 2>&1 &
OFFGRID_PID=$!
echo "    PID: $OFFGRID_PID → log: /tmp/cosmicturtle-offgrid.log"
echo "    URL: http://localhost:6160/nodestatus"
echo ""

# ── 3. Start iOS Simulator ───────────────────────────
echo "  Starting turtleshell-ios (Xcode Simulator)..."
XCODEPROJ="$COSMOS_DIR/turtleshell-ios/TurtleShell.ai/TurtleShell.ai.xcodeproj"
if [ -d "$XCODEPROJ" ]; then
  # Boot a simulator if none running
  BOOTED=$(xcrun simctl list devices booted 2>/dev/null | grep -c "Booted")
  if [ "$BOOTED" = "0" ]; then
    # Find an iPhone simulator
    SIM_ID=$(xcrun simctl list devices available -j 2>/dev/null | \
      python3 -c "import sys,json; d=json.load(sys.stdin)['devices']; devs=[v for k,v in d.items() if 'iPhone' in k for v in v if v['isAvailable']]; print(devs[0]['udid'] if devs else '')" 2>/dev/null)
    if [ -n "$SIM_ID" ]; then
      xcrun simctl boot "$SIM_ID" 2>/dev/null
      echo "    Booted simulator: $SIM_ID"
    fi
  fi
  open -a Simulator 2>/dev/null
  # Build and run in background
  xcodebuild -project "$XCODEPROJ" \
    -scheme "TurtleShell.ai" \
    -destination "platform=iOS Simulator,name=iPhone 16" \
    -derivedDataPath "$COSMOS_DIR/turtleshell-ios/build" \
    build > /tmp/cosmicturtle-ios-build.log 2>&1 &
  IOS_PID=$!
  echo "    Build PID: $IOS_PID → log: /tmp/cosmicturtle-ios-build.log"
else
  echo "    Xcode project not found — skipping"
  IOS_PID=""
fi
echo ""

# ── 4. Write cleanup script ──────────────────────────
cat > /tmp/cosmicturtle-cleanup.sh <<CLEANUP
#!/bin/bash
kill $WEB_PID $OFFGRID_PID $IOS_PID 2>/dev/null
echo "Cosmic Turtle servers stopped."
CLEANUP
chmod +x /tmp/cosmicturtle-cleanup.sh

echo "  ───────────────────────────────────────────────"
echo "  All apps running. Cleanup: /tmp/cosmicturtle-cleanup.sh"
echo "  ───────────────────────────────────────────────"
echo ""

# ── 5. Launch Development Agent ─────────────────────────────
PROMPT="You are the Cosmic Turtle — the development agent for the cosmos-logos organization.

Your working directory is: ${COSMOS_DIR}

You have full read and write access across all cosmos-logos repositories:

TurtleShell Applications:
  - turtleshell-web      — Web app (Vite + React + TypeScript + Tailwind) — running at $WEB_URL
  - turtleshell-offgrid  — Off-Grid dashboard + reverse proxy (Node/Express) — running at http://localhost:6160
  - turtleshell-ios      — iOS app (Swift/SwiftUI/CryptoKit) — building in Simulator

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

CI/CD:
  - turtleshell-web: push to brain/1.7.x.x auto-deploys to turtleshell.ai via Netlify
  - PRs get Netlify preview URLs commented automatically

You are the shell that protects. Build well."

BOOT_COMMAND="Start the Cosmic Turtle development session:

1. Read CLAUDE.md in .github/ for org-level conventions
2. Briefly report the status of each running app (web, offgrid, iOS)
3. Ask what the user wants to work on

The Cosmic Turtle is awake. All shells are online."

cd "$COSMOS_DIR"
claude --dangerously-skip-permissions --append-system-prompt "$PROMPT" "$BOOT_COMMAND"

# ── Cleanup on exit ───────────────────────────────────
echo ""
echo "  Cosmic Turtle going to sleep..."
bash /tmp/cosmicturtle-cleanup.sh
