# npm Platform Detection and Auto-Fix

## Problem

When developing on Windows and running code in a WSL2/Docker Linux container, `node_modules` installed on the Windows host contains platform-specific binaries (like `@esbuild/win32-x64`). When the workspace is mounted into a Linux container, these Windows binaries fail with errors like:

```
Error: You installed esbuild for another platform than the one you're currently using.
Specifically the "@esbuild/win32-x64" package is present but this platform
needs the "@esbuild/linux-x64" package instead.
```

## Solution

The DevContainer automatically detects and fixes platform mismatches during container creation.

### How It Works

1. **Detection**: The `setup-frontend.sh` script runs during `postCreateCommand`
2. **Check**: Looks for Windows-specific binaries in `node_modules/@esbuild/`
3. **Fix**: If found, removes `node_modules` and `package-lock.json`, then reinstalls for Linux
4. **Skip**: If `node_modules` is already compatible, does nothing

### Implementation

**Script**: `.devcontainer/setup-frontend.sh`
```bash
#!/bin/bash
# Detects Windows-specific node_modules and reinstalls for Linux

if [ -d "node_modules/@esbuild/win32-x64" ] || [ -d "node_modules/@esbuild/win32-arm64" ]; then
  echo "[Frontend Setup] ⚠️  Detected Windows node_modules!"
  rm -rf node_modules package-lock.json
  npm install
  echo "[Frontend Setup] ✓ npm dependencies reinstalled for Linux platform"
fi
```

**DevContainer Hook**: Added to `devcontainer.json`
```json
{
  "postCreateCommand": ".devcontainer/setup-claude-credentials.sh && .devcontainer/setup-frontend.sh"
}
```

### When It Runs

- **Container creation**: First time the DevContainer is built
- **Container rebuild**: After running "Rebuild Container" in VS Code
- **Never**: During normal container starts (only on creation)

### Manual Fix

If you need to manually fix platform mismatches:

```bash
# Inside the container
cd /workspace
rm -rf node_modules package-lock.json
npm install
```

## Related Issues

- **Issue #107**: Automate npm installation and Ollama deployment on container build
- **Windows/WSL2 Development**: Common when switching between host and container environments

## Benefits

- **Zero manual intervention**: Works automatically on container creation
- **Cross-platform workflow**: Seamlessly switch between Windows host and Linux container
- **Prevents build errors**: No more esbuild platform mismatch errors
- **Fast rebuilds**: Detection is instant, only reinstalls when needed

## Supported Package Managers

Currently supports:
- npm (detects `package-lock.json`)

Future support planned for:
- yarn (detect `yarn.lock`)
- pnpm (detect `pnpm-lock.yaml`)

## Troubleshooting

### Script not running
- Check `postCreateCommand` in `.devcontainer/devcontainer.json`
- Verify `.devcontainer/setup-frontend.sh` exists and is executable
- Look for errors in DevContainer creation logs

### Still getting platform errors
- Manually remove `node_modules` and reinstall inside container
- Check if other packages have platform-specific binaries
- Verify you're running commands inside the container, not on the host

### Performance concerns
- The script only reinstalls when Windows binaries are detected
- Uses npm's cache for faster installs
- Runs once during container creation, not on every start
