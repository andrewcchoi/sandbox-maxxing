# Windows-Specific Issues

Windows, WSL2, and Docker Desktop specific problems and solutions.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Container Issues](container.md) | [Performance Issues](performance.md)

---

## Line Ending Problems (CRLF vs LF)

**Symptoms:**
- Shell scripts fail with `/bin/bash^M: bad interpreter`
- Docker build fails with syntax errors in shell scripts
- `init-firewall.sh` won't execute inside container

**Cause:** Windows Git may convert LF line endings to CRLF, which breaks shell scripts in Linux containers.

**Solutions:**

**1. Configure Git (Recommended - Prevents Future Issues):**
```bash
# Set global Git config to preserve LF line endings
git config --global core.autocrlf input

# Or for this repository only
cd /path/to/sandbox-maxxing
git config core.autocrlf input
```

**2. Use Repository `.gitattributes` File:**

The repository includes a `.gitattributes` file that enforces LF for shell scripts and Docker files. If you cloned before this was added:

```bash
# Re-normalize files after .gitattributes is present
git add --renormalize .
git checkout -- .
```

**3. Manual Fix (Single File):**
```bash
# Convert CRLF to LF
sed -i 's/\r$//' .devcontainer/init-firewall.sh

# Or using dos2unix if available
dos2unix .devcontainer/init-firewall.sh
```

**4. VS Code Settings:**

Add to `.vscode/settings.json`:
```json
{
  "files.eol": "\n"
}
```

---

## Docker Desktop WSL 2 Backend Issues

**Symptoms:**
- Very slow file operations
- Container takes long time to start
- High CPU usage from `vmmem` process

**Solutions:**

**1. Use WSL 2 Backend (Required for Best Performance):**
- Docker Desktop > Settings > General > "Use the WSL 2 based engine" (check)

**2. Store Project Files in WSL Filesystem:**
```bash
# Instead of /mnt/c/Users/... (slow Windows filesystem)
# Use ~/projects/... in WSL (fast native filesystem)

# Move project to WSL filesystem
cd ~
git clone https://github.com/andrewcchoi/sandbox-maxxing
cd sandbox-maxxing
code .
```

**3. Configure WSL Memory Limits:**

Create/edit `%USERPROFILE%\.wslconfig` on Windows:
```ini
[wsl2]
memory=8GB
processors=4
swap=2GB
```

Then restart WSL:
```powershell
# In PowerShell as Administrator
wsl --shutdown
```

---

## Corporate Proxy / SSL Certificate Issues

**Symptoms:**
- `SSL: CERTIFICATE_VERIFY_FAILED`
- `unable to get local issuer certificate`
- Package installation fails with SSL errors (pip, npm, curl)
- UV installation fails during Docker build

**Solutions:**

**1. Add Custom CA Certificate to Docker Image:**

If your corporate network uses a custom CA certificate:

```dockerfile
# Add to your Dockerfile
COPY corporate-ca.crt /usr/local/share/ca-certificates/
RUN update-ca-certificates
```

**2. Configure Proxy Environment Variables:**

Add to your `docker-compose.yml` or `.env`:

```yaml
# docker-compose.yml
services:
  app:
    environment:
      - HTTP_PROXY=http://proxy.company.com:8080
      - HTTPS_PROXY=http://proxy.company.com:8080
      - NO_PROXY=localhost,127.0.0.1,.company.com
```

Or in your `Dockerfile`:
```dockerfile
ARG HTTP_PROXY
ARG HTTPS_PROXY
ENV HTTP_PROXY=${HTTP_PROXY}
ENV HTTPS_PROXY=${HTTPS_PROXY}
```

Then build with proxy args:
```bash
docker build \
  --build-arg HTTP_PROXY=http://proxy.company.com:8080 \
  --build-arg HTTPS_PROXY=http://proxy.company.com:8080 \
  -t myimage .
```

**3. Configure pip to Use Proxy:**

Inside the container:
```bash
pip config set global.proxy http://proxy.company.com:8080
pip config set global.trusted-host pypi.org
pip config set global.trusted-host files.pythonhosted.org
```

**4. Disable SSL Verification (Last Resort - Not Recommended):**

Only use this for testing in controlled environments:
```bash
# For pip
uv add --trusted-host pypi.org --trusted-host files.pythonhosted.org package-name

# For npm
npm config set strict-ssl false

# For git
git config --global http.sslVerify false
```

**5. UV Installation Fallback:**

The repository's Python Dockerfile automatically falls back to pip if UV installation fails due to SSL/proxy issues. This is handled automatically - no action needed.

---

**Next:** [Linux/WSL2 Troubleshooting](linux.md) | [Back to Main](../TROUBLESHOOTING.md)
