#!/usr/bin/env bash
# PSC Setup Orchestrator
# Interactive installer for all PSC dependencies and integrations.
# Safe to re-run — each component checks its own state first.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"

# ── helpers ───────────────────────────────────────────────────────────────────

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

ok()   { echo -e "  ${GREEN}[ok]${NC}  $*"; }
warn() { echo -e "  ${YELLOW}[!]${NC}   $*"; }
fail() { echo -e "  ${RED}[x]${NC}   $*"; }
info() { echo -e "  ${DIM}[..]${NC}  $*"; }
hdr()  { echo -e "\n${BOLD}$*${NC}"; }

# ── component status checks ───────────────────────────────────────────────────

check_hooks() {
  grep -q '"bash \.claude/hooks/' "$SETTINGS" 2>/dev/null && echo "pending" || echo "done"
}

check_node() {
  node --version &>/dev/null || { echo "missing"; return; }
  local v; v=$(node --version | sed 's/v//')
  local major; major=$(echo "$v" | cut -d. -f1)
  [ "$major" -ge 18 ] && echo "ok ($v)" || echo "old ($v — need 18+)"
}

check_node_deps() {
  [ -f "$PROJECT_ROOT/mcp-servers/obsidian/node_modules/.package-lock.json" ] \
    && echo "done" || echo "pending"
}

check_python() {
  for cmd in python3 python; do
    if $cmd --version &>/dev/null 2>&1; then
      local v; v=$($cmd --version 2>&1 | awk '{print $2}')
      echo "ok ($v)"; return
    fi
  done
  echo "missing"
}

check_obsidian() {
  grep -q '"obsidian"' "$SETTINGS" 2>/dev/null && echo "done" || echo "pending"
}

check_uiux() {
  local dest="$PROJECT_ROOT/.claude/skills/ui-ux-pro-max-skill"
  if [ -d "$dest/.git" ]; then
    local branch; branch=$(git -C "$dest" rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
    echo "cloned ($branch)"
  else
    echo "not cloned"
  fi
}

# ── installers ────────────────────────────────────────────────────────────────

install_hooks() {
  hdr "Patching hook paths..."
  bash "$SCRIPT_DIR/install.sh"
}

install_node_check() {
  hdr "Checking Node.js..."
  local status; status=$(check_node)
  if [[ "$status" == missing ]]; then
    fail "Node.js not found. Install from https://nodejs.org (v18 or later)"
    return 1
  elif [[ "$status" == old* ]]; then
    fail "Node.js version too old: $status. Upgrade to v18+."
    return 1
  else
    ok "Node.js $status"
  fi
}

install_node_deps() {
  hdr "Installing MCP server dependencies..."
  if ! node --version &>/dev/null; then
    fail "Node.js not found — skipping (install Node.js first)"
    return 1
  fi
  if [ -d "$PROJECT_ROOT/mcp-servers/obsidian" ]; then
    info "npm install in mcp-servers/obsidian..."
    npm install --silent --prefix "$PROJECT_ROOT/mcp-servers/obsidian"
    ok "mcp-servers/obsidian dependencies installed"
  else
    warn "mcp-servers/obsidian not found — skipping"
  fi
}

install_python() {
  hdr "Checking Python (instinct CLI)..."
  local status; status=$(check_python)
  if [[ "$status" == missing ]]; then
    warn "Python not found. Install Python 3.6+ to enable continuous learning."
    warn "Download: https://www.python.org/downloads/"
    warn "After installing, re-run: bash scripts/setup.sh"
    return 1
  fi
  ok "Python $status"
  if [ -f "$PROJECT_ROOT/scripts/requirements.txt" ]; then
    info "Installing Python requirements..."
    local python_cmd="python3"
    python3 --version &>/dev/null 2>&1 || python_cmd="python"
    $python_cmd -m pip install -r "$PROJECT_ROOT/scripts/requirements.txt" -q
    ok "Python requirements installed"
  fi
}

install_obsidian() {
  hdr "Obsidian MCP setup..."
  if [ ! -f "$PROJECT_ROOT/mcp-servers/obsidian/setup.js" ]; then
    fail "mcp-servers/obsidian/setup.js not found"
    return 1
  fi
  node "$PROJECT_ROOT/mcp-servers/obsidian/setup.js"
}

install_uiux() {
  hdr "UI/UX Pro Max skill setup..."

  local dest="$PROJECT_ROOT/.claude/skills/ui-ux-pro-max-skill"
  local repo="https://github.com/nextlevelbuilder/ui-ux-pro-max-skill"
  local venv="$PROJECT_ROOT/.claude/skills/.venv"

  # Step 1: Clone or update the repo
  if [ -d "$dest/.git" ]; then
    info "Repo already cloned — pulling latest..."
    git -C "$dest" pull --quiet && ok "ui-ux-pro-max-skill updated" || warn "git pull failed (continuing)"
  else
    info "Cloning $repo ..."
    if ! git clone --quiet "$repo" "$dest"; then
      fail "git clone failed — check your internet connection and try again"
      return 1
    fi
    ok "ui-ux-pro-max-skill cloned to .claude/skills/ui-ux-pro-max-skill/"
  fi

  # Step 2: Python venv for AI generation scripts
  local python_cmd=""
  for cmd in python3 python; do
    $cmd --version &>/dev/null 2>&1 && { python_cmd="$cmd"; break; }
  done

  if [ -z "$python_cmd" ]; then
    warn "Python not found — skipping venv setup (AI generation scripts will not work)"
    warn "Install Python 3.10+ then re-run: bash scripts/setup.sh"
  else
    info "Setting up Python venv at .claude/skills/.venv ..."
    $python_cmd -m venv "$venv" && ok "venv created" || { warn "venv creation failed — continuing"; }

    if [ -d "$venv" ]; then
      local pip="$venv/bin/pip"
      [ -f "$venv/Scripts/pip" ] && pip="$venv/Scripts/pip"  # Windows path

      info "Installing base venv requirements..."
      "$pip" install --quiet rank-bm25 && ok "rank-bm25 installed (BM25 search engine)"

      # Step 3: Optional AI generation deps (needs GOOGLE_API_KEY)
      echo ""
      read -rp "  Install AI generation tools? (google-genai + pillow — needs GOOGLE_API_KEY) (y/N): " AI_CHOICE
      if [[ "${AI_CHOICE:-N}" =~ ^[yY] ]]; then
        "$pip" install --quiet google-genai pillow && ok "google-genai + pillow installed"
        if [ -z "${GOOGLE_API_KEY:-}" ]; then
          warn "GOOGLE_API_KEY is not set — AI generation will not work until you add it to your environment"
        else
          ok "GOOGLE_API_KEY detected"
        fi
      else
        warn "Skipped AI generation tools — run 'bash scripts/setup.sh' to install later"
      fi
    fi
  fi

  ok "UI/UX tools ready. Skills available: banner-design, design, ui-ux-pro-max, and more."
}

# ── main ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  PSC Setup${NC}"
echo -e "  ${DIM}Project Santa Claus — dependency installer${NC}"
echo ""

# Build component list with live status
HOOKS_STATUS=$(check_hooks)
NODE_STATUS=$(check_node)
NODE_DEPS_STATUS=$(check_node_deps)
PYTHON_STATUS=$(check_python)
OBSIDIAN_STATUS=$(check_obsidian)
UIUX_STATUS=$(check_uiux)

status_label() {
  case "$1" in
    ok*|done|cloned*) echo -e "${GREEN}$1${NC}" ;;
    missing|old*|not\ cloned) echo -e "${RED}$1${NC}" ;;
    *) echo -e "${YELLOW}$1${NC}" ;;
  esac
}

echo -e "  ${BOLD}Component                  Status${NC}"
echo    "  ─────────────────────────────────────────────────────────"
echo -e "  [1] Core hooks           $(status_label "$HOOKS_STATUS")  — patch hook paths for this machine"
echo -e "  [2] Node.js check        $(status_label "$NODE_STATUS")  — verify Node.js 18+"
echo -e "  [3] Node.js deps         $(status_label "$NODE_DEPS_STATUS")  — install MCP server packages"
echo -e "  [4] Python / instincts   $(status_label "$PYTHON_STATUS")  — continuous learning CLI"
echo -e "  [5] Obsidian MCP         $(status_label "$OBSIDIAN_STATUS")  — vault + Omnisearch integration"
echo -e "  [6] UI/UX Pro Max        $(status_label "$UIUX_STATUS")  — design skills (clones external repo)"
echo ""

# Prompt
read -rp "  Install all? (Y/n) or enter numbers to skip (e.g. '4 5'): " CHOICE
CHOICE="${CHOICE:-Y}"

SKIP=()
if [[ "$CHOICE" =~ ^[nN] ]]; then
  read -rp "  Which components do you want? (e.g. '1 2 3'): " WANT
  for i in 1 2 3 4 5 6; do
    [[ " $WANT " == *" $i "* ]] || SKIP+=("$i")
  done
else
  # Parse skip numbers from input like "3 4"
  for word in $CHOICE; do
    [[ "$word" =~ ^[1-6]$ ]] && SKIP+=("$word")
  done
fi

RESULTS=()
run_component() {
  local num="$1" name="$2"
  if [[ " ${SKIP[*]:-} " == *" $num "* ]]; then
    warn "Skipped: $name  (run 'bash scripts/setup.sh' to install later)"
    RESULTS+=("SKIP: $name")
    return
  fi
  shift 2
  if "$@"; then
    RESULTS+=("OK:   $name")
  else
    RESULTS+=("FAIL: $name")
  fi
}

run_component 1 "Core hooks"         install_hooks
run_component 2 "Node.js check"      install_node_check
run_component 3 "Node.js deps"       install_node_deps
run_component 4 "Python / instincts" install_python
run_component 5 "Obsidian MCP"       install_obsidian
run_component 6 "UI/UX Pro Max"      install_uiux

# Summary
echo ""
hdr "Summary"
for r in "${RESULTS[@]}"; do
  case "$r" in
    OK*)   ok  "${r#OK:   }" ;;
    SKIP*) warn "${r#SKIP: }" ;;
    FAIL*) fail "${r#FAIL: }" ;;
  esac
done

echo ""
info "Re-run any component individually: bash scripts/setup.sh"
info "Restart Claude Code to load any new MCP servers or hooks."
echo ""
