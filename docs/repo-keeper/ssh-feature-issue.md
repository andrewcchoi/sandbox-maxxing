# GitHub Issue: SSH Support Within Containers

**Repository:** andrewcchoi/sandbox-maxxing
**Title:** `[FEATURE] Implement SSH support within containers`
**Assignee:** andrewcchoi
**Labels:** enhancement, security, advanced-mode

---

## Feature Description

Add comprehensive SSH support for sandbox containers, enabling:
- **Inbound SSH Server** - Run SSH server in container for remote access into the container
- **SSH Agent Forwarding** - Forward host SSH agent into container for seamless Git authentication

## Problem / Use Case

### Current Limitations
1. No way to SSH into running containers from external machines
2. SSH agent forwarding not configured by default
3. Users must manually set up SSH for remote development scenarios

### Use Cases This Enables
1. **Remote Development** - SSH into container from external terminals
2. **VS Code Remote-SSH** - Connect VS Code via SSH (alternative to Dev Containers extension)
3. **Headless Operation** - Run containers on remote servers and SSH in
4. **CI/CD Access** - Allow automation to connect into containers
5. **Git Authentication** - Use host SSH keys for private repo access without copying keys into container

## Proposed Solution

### Part 1: Inbound SSH Server
- Add OpenSSH server installation to Dockerfiles (optional, mode-dependent)
- Configure SSH key-based authentication (no password auth)
- Expose SSH port (22 or custom) in docker-compose
- Modify firewall scripts to allow inbound SSH connections
- Add user's public key mounting/configuration

### Part 2: SSH Agent Forwarding
- Configure SSH_AUTH_SOCK forwarding in devcontainer.json
- Add documentation for host-side SSH agent setup
- Support both macOS and Linux host configurations

### Security Considerations
- Key-based auth only (no passwords)
- Configurable allowed keys
- Firewall rules for source IP restriction (advanced mode)
- Clear documentation on security implications

## Mode Applicability

- [ ] Basic - Not applicable (too complex for auto-config)
- [x] Intermediate - SSH agent forwarding only (safe, useful)
- [x] Advanced - Full SSH support with explicit configuration
- [x] YOLO - Full SSH support, user manages security
- [ ] All modes
- [ ] New mode needed

## Files Expected to Change

| Category | Files |
|----------|-------|
| Dockerfiles | `templates/master/Dockerfile.master`, mode-specific |
| DevContainer | `templates/master/devcontainer.json.master` |
| Firewall | `templates/firewall/init-firewall.*.sh` |
| Compose | `templates/compose/docker-compose.*.yml` |
| Secrets | `data/secrets.json`, `docs/features/SECRETS.md` |
| Documentation | Mode READMEs, TROUBLESHOOTING.md |

## Checklist

- [x] I have searched existing issues to ensure this is not a duplicate
- [x] I have considered the security implications
- [x] I have identified which modes this applies to

---

## To Create This Issue

Run this command from your local machine (with `gh` CLI installed):

```bash
gh issue create \
  --repo andrewcchoi/sandbox-maxxing \
  --title "[FEATURE] Implement SSH support within containers" \
  --assignee andrewcchoi \
  --label "enhancement,security,advanced-mode" \
  --body-file docs/repo-keeper/ssh-feature-issue.md
```

Or manually create at: https://github.com/andrewcchoi/sandbox-maxxing/issues/new
