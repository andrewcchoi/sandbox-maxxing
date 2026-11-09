# Git Worktree Issues

Creating and managing git worktrees in containers.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Container Issues](container.md)

---

## Issue: "fatal: could not create leading directories"

**Symptoms:**
- Cannot create git worktrees inside the container
- Error: `fatal: could not create leading directories of '../my-worktree'`
- Worktree commands fail even though git works normally

**Cause:**
Your project folder structure doesn't support worktrees. The devcontainer mounts the parent folder (`..`), but if your repo is directly in a shared projects folder (e.g., `D:\projects\my-repo\`), the parent contains other projects and worktrees can't be created as siblings.

**Solution:**
Restructure your folders on the host to use a project-specific parent:

```bash
# Current structure (doesn't support worktrees):
D:\projects\my-repo\

# Recommended structure (supports worktrees):
D:\projects\my-project\
  └── my-repo\

# How to restructure:
mkdir D:\projects\my-project
move D:\projects\my-repo D:\projects\my-project\my-repo
```

After restructuring:
1. Open `D:\projects\my-project\my-repo\` in VS Code
2. Reopen in container
3. Create worktrees: `git worktree add ../feature-branch main`
4. Worktrees appear at `/workspace/feature-branch/`

---

## Issue: "dubious ownership" or "detected dubious ownership in repository"

**Symptoms:**
- Git commands fail with ownership warnings
- `fatal: detected dubious ownership in repository at '/workspace/my-repo'`
- Happens in worktrees or after creating new worktrees

**Cause:**
Git's security check detects that the repository is owned by a different user (host user) than the container user.

**Solution 1: Add to postStartCommand (automatic)**

The template already includes this fix. Verify it's in `.devcontainer/devcontainer.json`:

```json
"postStartCommand": "git config --global --add safe.directory '*' && sudo /usr/local/bin/init-firewall.sh && echo 'DevContainer ready!'"
```

**Solution 2: Manual fix (if needed)**

Inside the container:
```bash
git config --global --add safe.directory '*'
```

This tells git to trust all repositories, which is safe inside an isolated container.

---

## Issue: Worktrees not visible on host

**Symptoms:**
- Created worktree in container with `git worktree add ../feature`
- Worktree exists at `/workspace/feature/` in container
- Cannot see worktree folder on host filesystem

**Cause:**
Worktree was created outside the mounted parent folder, or the parent mount is incorrect.

**Verification:**
```bash
# Inside container
pwd                           # Should be /workspace/my-repo
git worktree add ../feature
ls /workspace/                # Should show both my-repo/ and feature/
```

On host, check:
- `D:\projects\my-project\` should contain both `my-repo\` and `feature\`

If not visible, verify your folder structure matches the recommended pattern.

---

## Issue: Cannot switch between worktrees in VS Code

**Symptoms:**
- Worktrees created successfully
- Want to open different worktree in same container
- VS Code doesn't provide easy way to switch

**Solution:**
Each worktree should be opened as a separate VS Code window with its own container:

```bash
# On host
code D:\projects\my-project\feature-branch\

# In VS Code: "Reopen in Container"
# New container starts with working directory at /workspace/feature-branch/
```

Alternatively, use the terminal to navigate:
```bash
# Inside container
cd /workspace/feature-branch/
# Work on feature branch

cd /workspace/my-repo/
# Switch back to main repo
```

---

**Next:** [Nuclear Option](reset.md) | [Back to Main](../TROUBLESHOOTING.md)
