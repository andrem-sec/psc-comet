# Cross-Platform Path Handling

Project Santa Clause supports Windows, Linux, and macOS through automatic platform detection.

## Platform Detection

All scripts use `scripts/detect-platform.sh` for OS and path detection:

```bash
# Source the utility in your scripts
source "$(dirname "$0")/detect-platform.sh"

# Available variables after sourcing:
# $DETECTED_OS      - "windows", "linux", "macos", or "unknown"
# $DETECTED_ARCH    - "x86_64", "arm64", etc.
# $PATH_SEP         - "\" on Windows, "/" elsewhere
# $NORMALIZED_HOME  - Home directory with forward slashes
# $PROJECT_ROOT     - Git root or current directory
```

## Path Normalization

Always normalize paths when working with file references:

```bash
# Normalize path (convert backslashes to forward slashes)
NORMALIZED_PATH="$(normalize_path "$SOME_PATH")"

# Convert to Windows path if needed
WINDOWS_PATH="$(to_windows_path "$UNIX_PATH")"

# Get home directory portably
HOME_DIR="$(get_home_dir)"
```

## Supported Environments

- **Windows**: Git Bash, MSYS2, MINGW, Cygwin
- **Linux**: All distributions
- **macOS**: All versions

## Hook Compatibility

All hooks automatically detect the OS and adjust path handling:
- `observe-instinct.sh` - Uses normalized paths
- `stop-check-console-log.sh` - Cross-platform file scanning
- `bootstrap-phase8.sh` - Platform-aware Python installation

## Testing

Test platform detection:

```bash
bash scripts/detect-platform.sh
```

Output example (Windows):
```
OS: windows
Architecture: x86_64
Path Separator: \
Home Directory: /c/Users/YourName
Project Root: C:/Users/YourName/project_santa_clause
```

## Common Issues

### Issue: Paths with backslashes fail in bash scripts
**Solution**: Always use `normalize_path` before passing paths to bash commands

### Issue: Python can't find files on Windows
**Solution**: Use forward slashes in Python (they work on all platforms)

### Issue: Hook fails to find scripts directory
**Solution**: Hooks use `$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)` which works everywhere

## Implementation Notes

- All internal path handling uses forward slashes (Unix-style)
- Only convert to backslashes when displaying to Windows users
- Git Bash on Windows handles forward slashes natively
- Python's `pathlib` handles both slashes automatically
