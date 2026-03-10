# Tailscale Setup Guide

Tailscale enables secure remote access to your DevContainer from anywhere.

## What is Tailscale?

Tailscale creates a private network (tailnet) between your devices using WireGuard. No port forwarding, no VPN server setup required.

## Setup Steps

### 1. Get Auth Key

1. Visit https://login.tailscale.com/admin/settings/keys
2. Generate a new auth key
3. Copy the key (starts with `tskey-auth-`)

### 2. Start Tailscale in Container

```bash
# Start the Tailscale daemon
sudo tailscaled --state=/var/lib/tailscale/tailscaled.state &

# Authenticate with your key
sudo tailscale up --authkey=tskey-auth-YOUR_KEY_HERE

# Check status
tailscale status
```

### 3. Access from Another Device

Once connected, your container gets a Tailscale IP (e.g., 100.x.x.x):

```bash
# From another device on your tailnet
ssh node@100.x.x.x

# Or use VS Code Remote SSH
# Add to ~/.ssh/config:
Host my-devcontainer
    HostName 100.x.x.x
    User node
```

## Use Cases

### Remote Development
Access your DevContainer from laptop, tablet, or phone.

### Share with Team
Give team members secure access to your development environment.

### Multi-Machine Workflow
Run containers on powerful workstation, code from laptop.

## Security

- Tailscale uses WireGuard encryption
- Only devices you authorize can connect
- Auth keys can be ephemeral (auto-expire)
- Full audit logs in Tailscale admin console

## Troubleshooting

### "tailscaled: command not found"
Rebuild container - Tailscale is only in enhanced yolo-docker-maxxing.

### "Cannot start tailscaled"
Check if already running: `ps aux | grep tailscaled`

### "Permission denied"
Tailscale requires sudo for network operations.

## References

- [Tailscale docs](https://tailscale.com/kb/)
- [Auth keys documentation](https://tailscale.com/kb/1085/auth-keys/)
