#!/usr/bin/env bash
# PSC Setup Orchestrator
# Installer for all PSC dependencies and integrations.
# Safe to re-run -- each component checks its own state first.
#
# Usage:
#   bash scripts/setup.sh              # interactive menu
#   bash scripts/setup.sh --all        # run all non-interactive components
#   bash scripts/setup.sh --skip 4 5   # run all except listed numbers
#   bash scripts/setup.sh --only 1 2 3 # run only listed numbers
#   bash scripts/setup.sh --status     # show status table and exit

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SETTINGS="$PROJECT_ROOT/.claude/settings.json"

# Detect interactive terminal
[ -t 0 ] && INTERACTIVE=1 || INTERACTIVE=0

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

# ── arg parsing ───────────────────────────────────────────────────────────────

MODE="interactive"  # interactive | all | skip | only | status
declare -a ARG_NUMS=()

while [[ $# -gt 0 ]]; do
  case "$1" in
    --all)    MODE="all";    shift ;;
    --status) MODE="status"; shift ;;
    --skip)
      MODE="skip"
      shift
      while [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; do
        ARG_NUMS+=("$1"); shift
      done
      ;;
    --only)
      MODE="only"
      shift
      while [[ $# -gt 0 && "$1" =~ ^[0-9]+$ ]]; do
        ARG_NUMS+=("$1"); shift
      done
      ;;
    *) shift ;;
  esac
done

# Non-interactive terminal with no flags: default to --all
if [[ "$MODE" == "interactive" && "$INTERACTIVE" -eq 0 ]]; then
  MODE="all"
fi

# ── component status checks ───────────────────────────────────────────────────

check_hooks() {
  # pending if settings.json is missing or still has unresolved {{PSC_ROOT}} placeholders
  if [ ! -f "$SETTINGS" ]; then
    echo "pending"
  elif grep -q '{{PSC_ROOT}}' "$SETTINGS" 2>/dev/null; then
    echo "pending"
  else
    echo "done"
  fi
}

check_node() {
  node --version &>/dev/null || { echo "missing"; return; }
  local v; v=$(node --version | sed 's/v//')
  local major; major=$(echo "$v" | cut -d. -f1)
  [ "$major" -ge 18 ] && echo "ok ($v)" || echo "old ($v, need 18+)"
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
    fail "Node.js not found -- skipping (install Node.js first)"
    return 1
  fi
  if [ -d "$PROJECT_ROOT/mcp-servers/obsidian" ]; then
    info "npm install in mcp-servers/obsidian..."
    npm install --silent --prefix "$PROJECT_ROOT/mcp-servers/obsidian"
    ok "mcp-servers/obsidian dependencies installed"
  else
    warn "mcp-servers/obsidian not found -- skipping"
  fi
}

# Try to add a newly installed Python to PATH for the current session
_python_refresh_path() {
  # Windows: check standard and AppData install paths
  if [[ "$OSTYPE" == "msys"* || "$OSTYPE" == "cygwin"* || -n "${WINDIR:-}" ]]; then
    local appdata="${LOCALAPPDATA:-$USERPROFILE/AppData/Local}"
    # Standard python.org installer location
    for dir in "$appdata/Programs/Python"/Python3*/; do
      [ -f "${dir}python.exe" ] && export PATH="$dir:${dir}Scripts:$PATH" && return 0
    done
    # Windows Apps location (winget installs here)
    local winapps="$appdata/Microsoft/WindowsApps"
    [ -f "$winapps/python3.exe" ] && export PATH="$winapps:$PATH" && return 0
    [ -f "$winapps/python.exe"  ] && export PATH="$winapps:$PATH" && return 0
  fi
  # macOS Homebrew
  [ -f "/opt/homebrew/bin/python3" ] && export PATH="/opt/homebrew/bin:$PATH" && return 0
  [ -f "/usr/local/bin/python3" ]    && export PATH="/usr/local/bin:$PATH"    && return 0
  return 1
}

_python_install_deps() {
  [ -f "$PROJECT_ROOT/scripts/requirements.txt" ] || return 0
  local python_cmd=""
  for cmd in python3 python; do
    command -v "$cmd" &>/dev/null && { python_cmd="$cmd"; break; }
  done
  [ -z "$python_cmd" ] && return 1
  info "Installing Python requirements..."
  $python_cmd -m pip install -r "$PROJECT_ROOT/scripts/requirements.txt" -q
  ok "Python requirements installed"
}

_python_manual_instructions() {
  warn "Automatic installation failed. Install Python manually, then re-run: bash scripts/setup.sh --only 4"
  warn ""
  warn "  Windows : winget install Python.Python.3"
  warn "            or https://www.python.org/downloads/"
  warn "  macOS   : brew install python3"
  warn "            or https://www.python.org/downloads/"
  warn "  Linux   : sudo apt install python3 python3-pip"
  warn "            sudo dnf install python3 python3-pip"
  warn "            sudo pacman -S python python-pip"
}

_python_install_windows() {
  command -v winget &>/dev/null || { warn "winget not available"; return 1; }
  info "Installing Python 3.13 via winget..."
  winget install Python.Python.3.13 --silent \
    --accept-package-agreements --accept-source-agreements 2>&1 | grep -v "^$" || true
}

_python_install_macos() {
  if command -v brew &>/dev/null; then
    info "Installing Python via Homebrew..."
    brew install python3
  else
    info "Homebrew not found -- installing Homebrew first (this may take a few minutes)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Load brew into current session
    for brew_path in "/opt/homebrew/bin/brew" "/usr/local/bin/brew"; do
      [ -f "$brew_path" ] && eval "$("$brew_path" shellenv)" && break
    done
    command -v brew &>/dev/null || { warn "Homebrew install failed"; return 1; }
    brew install python3
  fi
}

_python_install_linux() {
  if command -v apt-get &>/dev/null; then
    info "Installing Python via apt..."
    sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip
  elif command -v dnf &>/dev/null; then
    info "Installing Python via dnf..."
    sudo dnf install -y python3 python3-pip
  elif command -v pacman &>/dev/null; then
    info "Installing Python via pacman..."
    sudo pacman -S --noconfirm python python-pip
  elif command -v zypper &>/dev/null; then
    info "Installing Python via zypper..."
    sudo zypper install -y python3 python3-pip
  elif command -v apk &>/dev/null; then
    info "Installing Python via apk..."
    sudo apk add python3 py3-pip
  else
    warn "No supported package manager found (tried apt, dnf, pacman, zypper, apk)"
    return 1
  fi
}

install_python() {
  hdr "Python / instinct CLI..."
  local status; status=$(check_python)

  if [[ "$status" != "missing" ]]; then
    ok "Python $status"
    _python_install_deps || true
    return 0
  fi

  info "Python not found -- attempting automatic installation..."

  local installed=0
  case "$(uname -s)" in
    MINGW*|MSYS*|CYGWIN*)  _python_install_windows && installed=1 ;;
    Darwin)                 _python_install_macos   && installed=1 ;;
    Linux)                  _python_install_linux   && installed=1 ;;
    *)
      warn "Unknown platform: $(uname -s)"
      ;;
  esac

  if [[ "$installed" -eq 0 ]]; then
    _python_manual_instructions
    return 1
  fi

  # Refresh PATH so the new Python is visible in this session
  _python_refresh_path || true

  # Verify install succeeded
  if ! check_python | grep -q "^ok"; then
    warn "Python was installed but is not yet in PATH."
    warn "Restart your terminal and re-run: bash scripts/setup.sh --only 4"
    return 1
  fi

  ok "Python $(check_python)"
  _python_install_deps || true
}

install_obsidian() {
  hdr "Obsidian MCP setup..."
  if [[ "$INTERACTIVE" -eq 0 ]]; then
    warn "Obsidian setup requires an interactive terminal."
    warn "Run it manually: bash scripts/setup.sh --only 5"
    warn "Or use /obsidian-setup from Claude Code."
    return 0
  fi
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

  if [ -d "$dest/.git" ]; then
    info "Repo already cloned -- pulling latest..."
    git -C "$dest" pull --quiet && ok "ui-ux-pro-max-skill updated" || warn "git pull failed (continuing)"
  else
    info "Cloning $repo ..."
    if ! git clone --quiet "$repo" "$dest"; then
      fail "git clone failed -- check your internet connection and try again"
      return 1
    fi
    ok "ui-ux-pro-max-skill cloned to .claude/skills/ui-ux-pro-max-skill/"
  fi

  local python_cmd=""
  for cmd in python3 python; do
    $cmd --version &>/dev/null 2>&1 && { python_cmd="$cmd"; break; }
  done

  if [ -z "$python_cmd" ]; then
    warn "Python not found -- skipping venv setup (AI generation scripts will not work)"
    warn "Install Python 3.10+ then re-run: bash scripts/setup.sh --only 6"
    return 0
  fi

  info "Setting up Python venv at .claude/skills/.venv ..."
  $python_cmd -m venv "$venv" && ok "venv created" || { warn "venv creation failed -- continuing"; return 0; }

  local pip="$venv/bin/pip"
  [ -f "$venv/Scripts/pip" ] && pip="$venv/Scripts/pip"

  info "Installing base venv requirements..."
  "$pip" install --quiet rank-bm25 && ok "rank-bm25 installed"

  # AI generation tools require interactive confirmation or GOOGLE_API_KEY set
  local install_ai=0
  if [[ "$INTERACTIVE" -eq 1 ]]; then
    echo ""
    read -rp "  Install AI generation tools? (google-genai + pillow, needs GOOGLE_API_KEY) (y/N): " AI_CHOICE
    [[ "${AI_CHOICE:-N}" =~ ^[yY] ]] && install_ai=1
  elif [ -n "${GOOGLE_API_KEY:-}" ]; then
    info "GOOGLE_API_KEY detected -- installing AI generation tools"
    install_ai=1
  else
    warn "Skipping AI generation tools (not interactive and GOOGLE_API_KEY not set)"
    warn "Set GOOGLE_API_KEY and re-run: bash scripts/setup.sh --only 6"
  fi

  if [[ "$install_ai" -eq 1 ]]; then
    "$pip" install --quiet google-genai pillow && ok "google-genai + pillow installed"
    if [ -z "${GOOGLE_API_KEY:-}" ]; then
      warn "GOOGLE_API_KEY is not set -- AI generation will not work until you add it to your environment"
    else
      ok "GOOGLE_API_KEY detected"
    fi
  fi

  ok "UI/UX tools ready."
}

# ── main ──────────────────────────────────────────────────────────────────────

echo ""
echo -e "${BOLD}  PSC Setup${NC}"
echo -e "  ${DIM}Project Santa Clause -- dependency installer${NC}"
echo ""

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
echo -e "  [1] Core hooks           $(status_label "$HOOKS_STATUS")  -- patch hook paths for this machine"
echo -e "  [2] Node.js check        $(status_label "$NODE_STATUS")  -- verify Node.js 18+"
echo -e "  [3] Node.js deps         $(status_label "$NODE_DEPS_STATUS")  -- install MCP server packages"
echo -e "  [4] Python / instincts   $(status_label "$PYTHON_STATUS")  -- continuous learning CLI"
echo -e "  [5] Obsidian MCP         $(status_label "$OBSIDIAN_STATUS")  -- vault + Omnisearch integration (interactive)"
echo -e "  [6] UI/UX Pro Max        $(status_label "$UIUX_STATUS")  -- design skills (clones external repo)"
echo ""

if [[ "$MODE" == "status" ]]; then
  exit 0
fi

# Build SKIP list from mode + args
SKIP=()

case "$MODE" in
  all)
    : # nothing to skip
    ;;
  skip)
    SKIP=("${ARG_NUMS[@]:-}")
    ;;
  only)
    for i in 1 2 3 4 5 6; do
      [[ " ${ARG_NUMS[*]:-} " == *" $i "* ]] || SKIP+=("$i")
    done
    ;;
  interactive)
    read -rp "  Install all? (Y/n) or enter numbers to skip (e.g. '4 5'): " CHOICE
    CHOICE="${CHOICE:-Y}"
    if [[ "$CHOICE" =~ ^[nN] ]]; then
      read -rp "  Which components do you want? (e.g. '1 2 3'): " WANT
      for i in 1 2 3 4 5 6; do
        [[ " $WANT " == *" $i "* ]] || SKIP+=("$i")
      done
    else
      for word in $CHOICE; do
        [[ "$word" =~ ^[1-6]$ ]] && SKIP+=("$word")
      done
    fi
    ;;
esac

RESULTS=()
run_component() {
  local num="$1" name="$2"
  if [[ " ${SKIP[*]:-} " == *" $num "* ]]; then
    warn "Skipped: $name  (re-run with --only $num to install later)"
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
info "Re-run a single component: bash scripts/setup.sh --only <number>"
info "Restart Claude Code to load any new MCP servers or hooks."
echo ""
