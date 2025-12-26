# Windows Development Documentation

This directory contains documentation specific to developing and using the sandbox-maxxing plugin on Windows.

## Contents

### [polyglot-hooks.md](./polyglot-hooks.md)
Complete guide to cross-platform hook implementation using polyglot wrapper scripts. This technique allows hooks to work on both Windows and Unix-based systems without requiring separate configurations.

**Topics covered:**
- How polyglot wrappers work (CMD + bash in one file)
- Setting up Git Bash on Windows
- Writing cross-platform hook scripts
- Troubleshooting common Windows issues
- Testing hooks on Windows

## Quick Start for Windows Developers

If you're developing on Windows and want to use this plugin:

1. **Install Git for Windows** (if not already installed)
   - Download: https://git-scm.com/download/win
   - This provides Git Bash, which the hooks require

2. **Clone the repository**
   ```powershell
   git clone https://github.com/your-org/sandbox-maxxing.git
   cd sandbox-maxxing
   ```

3. **Ensure hooks are executable** (in Git Bash or WSL)
   ```bash
   chmod +x hooks/*.cmd hooks/*.sh
   ```

4. **Test the plugin**
   - Open the project in Claude Code
   - The hooks will automatically work on Windows via Git Bash

## Common Issues on Windows

### Hooks don't run
- **Check**: Is Git for Windows installed?
- **Check**: Is bash.exe at `C:\Program Files\Git\bin\bash.exe`?
- **Fix**: See [polyglot-hooks.md](./polyglot-hooks.md#troubleshooting)

### Line ending issues (CRLF vs LF)
- Git may convert line endings to CRLF on Windows
- Bash scripts require LF line endings
- **Fix**: Configure git:
  ```bash
  git config core.autocrlf input
  ```

### Permission errors
- Windows doesn't use Unix file permissions
- Executable bit is stored in git metadata
- **Fix**: Use Git Bash or WSL to set permissions

## Development Workflow on Windows

### Option 1: Native Windows + Git Bash
- Edit files in your favorite Windows editor
- Test hooks via Git Bash terminal
- Commit using Git for Windows

### Option 2: WSL (Windows Subsystem for Linux)
- Full Linux environment on Windows
- Native bash support
- Recommended for intensive plugin development

### Option 3: DevContainer
- Use VS Code Dev Containers
- Linux environment with full Docker support
- Best for testing DevContainer features

## Related Documentation

- **Main README**: [../../README.md](../../README.md)
- **Skills Documentation**: [../../skills/README.md](../../skills/README.md)
- **Hooks Overview**: See hooks/ directory in plugin root

## Contributing

When adding Windows-specific documentation:
1. Place it in this `docs/windows/` directory
2. Update this README to link to it
3. Test all examples on actual Windows machine
4. Include PowerShell and CMD examples where applicable

---

**Maintained by**: sandbox-maxxing contributors
**Platform**: Windows 10/11, Windows Server 2019+
**Requirements**: Git for Windows, PowerShell 5.1+

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
