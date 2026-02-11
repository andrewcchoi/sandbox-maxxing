# Firewall Issues

Package installation failures and firewall blocking legitimate traffic.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Network Issues](network.md)

---

## Package Installation Fails

**Symptoms:**
- `npm install` hangs or fails
- `uv add <package>` fails with connection error
- `cargo build` can't fetch dependencies

**Cause:** Strict firewall mode blocking package registries.

**Solutions:**

**Identify Blocked Domain:**

Look at error message:
```
Could not connect to registry.npmjs.org
Failed to fetch https://files.pythonhosted.org
```

**Add to Allowlist:**

Edit `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...

  # ===CATEGORY:project_specific===
  # Python packages
  "pypi.org"
  "files.pythonhosted.org"

  # Node.js packages
  "registry.npmjs.org"

  # Rust crates
  "crates.io"
  "static.crates.io"

  # Ruby gems
  "rubygems.org"
  # ===END_CATEGORY===
)
```

**Restart Firewall:**
```bash
sudo /usr/local/bin/init-firewall.sh
```

**Common Package Registry Domains:**

| Language     | Domains to Whitelist                  |
| ------------ | ------------------------------------- |
| Python       | `pypi.org`, `files.pythonhosted.org`  |
| Node.js      | `registry.npmjs.org`, `yarnpkg.com`   |
| Rust         | `crates.io`, `static.crates.io`       |
| Ruby         | `rubygems.org`, `api.rubygems.org`    |
| Go           | `proxy.golang.org`, `sum.golang.org`  |
| Java/Maven   | `repo.maven.org`, `repo1.maven.org`   |
| PHP/Composer | `packagist.org`, `repo.packagist.org` |
| .NET/NuGet   | `nuget.org`, `api.nuget.org`          |

**Temporary Workaround:**

For testing purposes, temporarily use permissive mode:
```bash
# Edit .devcontainer/init-firewall.sh
FIREWALL_MODE="permissive"

# Rebuild container
```

⚠️ Remember to restore strict mode and whitelist needed domains afterward.

---

## npm Registry Blocked by Firewall (Issue #32)

**Symptoms:**
- Cannot install npm packages
- `npm install` fails with network errors
- Claude Code updates fail with registry connection errors
- `npm ERR! network request to https://registry.npmjs.org failed`

**Cause:**
The firewall is blocking access to the npm registry, preventing package installations and Claude Code updates.

**Solution:**
The npm registry domains are included in the firewall allowlist by default since version 2.2.1:

In `.devcontainer/init-firewall.sh`:
```bash
ALLOWED_DOMAINS=(
  # ... existing domains ...

  # ===CATEGORY:npm_registry===
  # NPM package registry (Issue #32)
  "registry.npmjs.org"
  "npmjs.org"
  "*.npmjs.org"
  # ===END_CATEGORY===
)
```

**If you're using an older version:**

1. Add the npm registry domains to your allowlist manually
2. Restart the firewall:
```bash
sudo /usr/local/bin/init-firewall.sh
```

3. Test npm access:
```bash
npm ping
npm install --dry-run
```

**Verify the fix:**
```bash
# Should succeed without errors
curl -fsSL https://claude.ai/install.sh | bash
```

---

## Firewall Verification Fails

**Symptoms:**
```
ERROR: Firewall verification failed - unable to reach https://api.github.com
```

**Cause:** GitHub IPs may have changed, or DNS resolution failed during firewall setup.

**Solutions:**

**1. Retry Firewall Initialization:**
```bash
sudo /usr/local/bin/init-firewall.sh
```

**2. Check DNS Resolution:**
```bash
nslookup api.github.com
# Should return IP addresses
```

**3. Manual GitHub IP Update:**

If GitHub IPs change frequently:
```bash
# Fetch latest GitHub IPs
curl -s https://api.github.com/meta | jq '.web + .api + .git'

# Or temporarily add static IP
# (not recommended long-term)
```

**4. Use Permissive Mode Temporarily:**

If firewall keeps failing verification, use permissive mode until fixed:
```bash
FIREWALL_MODE="permissive"
```

---

**Next:** [Permission Errors](permissions.md) | [Back to Main](../TROUBLESHOOTING.md)
