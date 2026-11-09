# Network Issues

Common network connectivity and DNS resolution problems in Docker containers.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Container Issues](container.md) | [Firewall Issues](firewall.md) | [Service Connectivity](services.md)

---

## Can't Reach External Websites

**Symptoms:**
- `curl https://api.github.com` fails
- `ping google.com` fails (if ping installed)
- DNS resolution errors

**Diagnostic Commands:**
```bash
# Inside container

# Test DNS resolution
nslookup google.com

# Test connectivity to known site
curl https://api.github.com/zen

# Check firewall rules
sudo iptables -L OUTPUT -v -n

# Check firewall mode
echo $FIREWALL_MODE
```

**Solutions:**

**1. Check Firewall Mode:**
```bash
echo $FIREWALL_MODE
# If "strict", firewall is actively blocking
```

**2. Verify Domain is Whitelisted:**

Check if the domain you need is in `/usr/local/bin/init-firewall.sh` or `.devcontainer/init-firewall.sh`:
```bash
cat /usr/local/bin/init-firewall.sh | grep -A 100 "ALLOWED_DOMAINS"
```

**3. Add Domain to Allowlist:**

Edit `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...
  "api.yourservice.com"
  "cdn.yourservice.com"
)
```

**4. Restart Firewall:**
```bash
sudo /usr/local/bin/init-firewall.sh
```

**5. Temporarily Use Permissive Mode (Testing Only):**

Edit `.devcontainer/init-firewall.sh`:
```bash
FIREWALL_MODE="permissive"
```

Rebuild container. ⚠️ Remember to restore strict mode after testing.

---

## DNS Resolution Failures

**Symptoms:**
```
Could not resolve host: api.github.com
```

**Solutions:**

**1. Check Docker DNS:**
```bash
# Inside container
cat /etc/resolv.conf

# Should show Docker's DNS server (usually 127.0.0.11)
```

**2. Restart Docker (Host):**
```bash
# Mac/Windows: Restart Docker Desktop
# Linux:
sudo systemctl restart docker
```

**3. Check Host DNS:**

Ensure your host machine can resolve DNS. If host DNS is broken, containers will also fail.

---

**Next:** [Service Connectivity](services.md) | [Firewall Issues](firewall.md) | [Back to Main](../TROUBLESHOOTING.md)
