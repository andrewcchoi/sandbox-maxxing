# YOLO Mode DevContainer Configuration

## ⚠️ WARNING ⚠️

This configuration is in **YOLO MODE** - full control with NO restrictions.

### Security Notice
- **Firewall**: DISABLED
- **Network Access**: UNRESTRICTED
- **Container Capabilities**: NET_ADMIN, SYS_PTRACE enabled
- **Security Options**: apparmor and seccomp unconfined

**This configuration is for development only. Do not use in production.**

## Configuration Summary

- **Mode**: YOLO (Full Control)
- **Base Image**: python:3.12-slim (official)
- **Language**: Python 3.12
- **Firewall**: Disabled
- **Services**: None
- **Total Capabilities**: Maximum

## Quick Start

```bash
# Pull images
docker compose pull

# Start container
docker compose up -d

# Open in VS Code
code .
# Then: Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

## Installed Tools

- Python 3.12 with pip
- Git, curl, wget
- Build tools (gcc, g++, make)
- Database clients (psql, mysql, redis-cli, sqlite3)
- Network tools (iptables, dig, ip)
- Text editors (vim, nano)
- Claude Code CLI
- ZSH shell

## Network Access

**ALL outbound connections are allowed** (no firewall restrictions).

## Next Steps

1. Review the configuration files
2. Customize as needed (you have full control)
3. Start the container and begin development

## Security Recommendations

For production or security-sensitive work, consider:
- Use **Advanced Mode** with strict firewall
- Enable specific domain allowlists
- Remove unnecessary capabilities
- Enable security options (apparmor, seccomp)

Run `/sandbox:audit` to perform a security audit of this configuration.
