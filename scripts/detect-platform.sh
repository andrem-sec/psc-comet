#!/usr/bin/env bash
# Cross-platform OS and path detection utility

set -euo pipefail

detect_os() {
    case "$(uname -s)" in
        Linux*)   echo "linux" ;;
        Darwin*)  echo "macos" ;;
        CYGWIN*)  echo "windows" ;;
        MINGW*)   echo "windows" ;;
        MSYS*)    echo "windows" ;;
        *)        echo "unknown" ;;
    esac
}

detect_arch() {
    uname -m
}

get_path_separator() {
    local os="${1:-$(detect_os)}"
    case "$os" in
        windows) echo '\\' ;;
        *)       echo "/" ;;
    esac
}

normalize_path() {
    local path="$1"
    echo "${path//\\//}"
}

to_windows_path() {
    local path="$1"
    echo "${path//\//\\}"
}

get_home_dir() {
    if [ -n "${HOME:-}" ]; then
        echo "$HOME"
    elif [ -n "${USERPROFILE:-}" ]; then
        normalize_path "$USERPROFILE"
    else
        echo "~"
    fi
}

get_project_root() {
    if git rev-parse --show-toplevel >/dev/null 2>&1; then
        git rev-parse --show-toplevel
    else
        pwd
    fi
}

export -f detect_os 2>/dev/null || true
export -f detect_arch 2>/dev/null || true
export -f get_path_separator 2>/dev/null || true
export -f normalize_path 2>/dev/null || true
export -f to_windows_path 2>/dev/null || true
export -f get_home_dir 2>/dev/null || true
export -f get_project_root 2>/dev/null || true

export DETECTED_OS="$(detect_os)"
export DETECTED_ARCH="$(detect_arch)"
export PATH_SEP="$(get_path_separator)"
export NORMALIZED_HOME="$(get_home_dir)"
export PROJECT_ROOT="$(get_project_root)"

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    echo "OS: $DETECTED_OS"
    echo "Architecture: $DETECTED_ARCH"
    echo "Path Separator: $PATH_SEP"
    echo "Home Directory: $NORMALIZED_HOME"
    echo "Project Root: $PROJECT_ROOT"
fi
