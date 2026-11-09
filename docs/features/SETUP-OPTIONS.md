# DevContainer Setup Options

This guide explains how to create a DevContainer with this plugin using **Interactive Setup**.

## Interactive Setup Features

| Feature                    | Details                                             |
| -------------------------- | --------------------------------------------------- |
| **Questions Asked**        | 2-3 (minimal configuration)                         |
| **Project Type Selection** | Yes (9 options: Python/Node, Go, Ruby, Rust, C++ Clang, C++ GCC, PHP, PostgreSQL, Azure CLI) |
| **Firewall Customization** | Yes (optional, interactive domain selection)        |
| **Setup Time**             | 2-3 minutes                                         |
| **Base Image**             | Base + optional language partial                    |
| **Network Security**       | Optional strict firewall with allowlist or disabled |

![Quickstart Flow](../diagrams/svg/quickstart-flow.svg)

*Interactive quickstart workflow showing the complete setup process from project type selection through DevContainer generation.*

## Interactive Setup

**Command:** `/sandboxxer:quickstart`

**Philosophy:** Choose exactly what you need through an interactive flow.

### What You'll Be Asked

**Step 1: Project Type**
```
What type of project are you setting up?

  ● Python/Node (base only)
  ○ Go (adds Go toolchain, linters)
  ○ Ruby (adds Ruby, bundler, gems)
  ○ Rust (adds Cargo, rustfmt, clippy)
  ○ C++ Clang (adds Clang 17, CMake, debuggers)
  ○ C++ GCC (adds GCC, CMake, debuggers)
  ○ PHP (adds PHP 8.3, Composer)
  ○ PostgreSQL (adds PostgreSQL client tools)
  ○ Azure CLI (adds Azure CLI and tools)
```

**Step 2: Network Security**
```
Do you need network restrictions?

  ● No - Allow all outbound traffic (fastest)
  ○ Yes - Restrict to allowed domains only (more secure)
```

**Step 3 (if Yes): Domain Categories**
```
Which domain categories should be allowed?

  [x] Package managers (npm, PyPI, etc.)
  [x] Version control (GitHub, GitLab)
  [x] Container registries (Docker Hub, GHCR)
  [ ] Cloud platforms (AWS, GCP, Azure)
  [ ] Development tools (Kubernetes, HashiCorp)
  [ ] VS Code extensions
  [ ] Analytics/telemetry

  Custom domains: api.mycompany.com, cdn.example.com
```

### What You Get

- **Base image:** Python 3.12 + Node 20 + common dev tools (always included)
- **Language tools:** Appended based on your project type selection
- **Firewall:** Generated from your domain selections (or disabled if you chose "No")
- **Standard config:** devcontainer.json, docker-compose.yml, credential setup

### When to Use

- **Specific language requirements** - Need Go, Ruby, Rust, or Java tools
- **Security-focused projects** - Require network restrictions
- **Team environments** - Need to document firewall rules
- **Production preparation** - Want strict domain allowlists

### Example: Go Project with Firewall

```
You: /sandboxxer:quickstart

Claude: What type of project are you setting up?
You: Go

Claude: Do you need network restrictions?
You: Yes

Claude: Which domain categories should be allowed?
You: [x] Package managers, [x] Version control, [x] Container registries

Claude: Creating DevContainer...
        - Base: Python 3.12 + Node 20
        - Added: Go 1.22 toolchain, linters
        - Firewall: Strict mode with 45 allowed domains
        ✓ Done in 32 seconds
```

## YOLO Docker Maxxing Mode

**Command:** `/sandboxxer:yolo-docker-maxxing`

**Philosophy:** Zero questions, instant setup with sensible defaults.

### What You Get

No questions asked - creates a DevContainer with:

- **Base image:** Python 3.12 + Node 20 (multi-language base)
- **Firewall:** Disabled (relies on Docker container isolation)
- **Development tools:** All standard tools pre-installed
- **Services:** PostgreSQL + Redis via docker-compose
- **VS Code extensions:** Essential development extensions

### When to Use

- **Quick prototyping** - Need to start coding immediately
- **Learning projects** - Don't want setup complexity
- **Python/Node projects** - Base image covers your needs
- **Trusted code** - Working with known-safe dependencies
- **Local development** - Not concerned about network restrictions

### Example: Instant Setup

```
You: /sandboxxer:yolo-docker-maxxing

Claude: Creating DevContainer (YOLO Docker Maxxing mode)...
        - Project: my-app
        - Language: Python 3.12 + Node 20
        - Firewall: Disabled
        ✓ Done in 18 seconds

        Next: Open in VS Code → 'Reopen in Container'
```

## Native Linux/WSL2 Setup

**Command:** `/sandboxxer:yolo-linux-maxxing`

**Philosophy:** Native performance without Docker overhead, bubblewrap sandboxing.

### What You Get
- Bubblewrap sandboxing (process-level isolation)
- Native performance (no container overhead)
- Full Claude Code CLI
- Direct system tool integration

### When to Use
- Running Claude Code natively on Linux or WSL2
- Need maximum performance
- Docker unavailable or undesired
- Personal development machines

### Security Comparison

| Feature | Native Linux | Docker-based |
|---------|-------------|--------------|
| Process Sandboxing | Bubblewrap | Container |
| Network Isolation | No | Optional firewall |
| Filesystem Isolation | Partial | Full |
| Setup Complexity | Simple | Moderate |

For troubleshooting, use `/sandboxxer:linux-troubleshoot`.

## Language Support

The interactive setup uses a base image (Python 3.12 + Node 20) with optional language partials:

### Base Image Includes

- **Python:** 3.12 with uv, pip, pytest, black, mypy
- **Node:** 20 LTS with npm, yarn, pnpm
- **System tools:** git, vim, zsh, fzf, gh CLI
- **Database clients:** psql, mysql, redis-cli
- **DevOps tools:** Docker-in-Docker capabilities
- **Firewall tools:** iptables, ipset (if firewall enabled)

### Language Partials (Interactive Quickstart Setup Only)

When you select a language in interactive mode, a partial is **appended** to the base Dockerfile:

| Language | What Gets Added                                       |
| -------- | ----------------------------------------------------- |
| Go       | Go 1.22, gopls, delve, staticcheck, golint            |
| Ruby     | Ruby 3.3, bundler, rake, rspec, rubocop               |
| Rust     | Rust toolchain, Cargo, rustfmt, clippy, rust-analyzer |

**YOLO Docker Maxxing mode** uses only the base image - if you need additional language tools, use interactive setup.

## Firewall Behavior

### No Firewall (YOLO Docker Maxxing Mode Default)

- Relies on Docker container isolation
- All outbound network traffic allowed
- Fastest setup, no configuration needed
- Suitable for trusted code and local development

### Strict Firewall (Interactive Quickstart Setup Option)

- Whitelist-based: deny by default
- Domain categories map to ~10-100 domains each
- Custom domains can be added
- Uses iptables + ipset for enforcement
- Verification tests ensure firewall works

**Example domain counts by category:**
- Package managers (npm, PyPI): 15 domains
- Version control (GitHub, GitLab): 17 domains
- Container registries: 9 domains
- Cloud platforms (AWS, GCP, Azure): 25 domains
- Development tools: 12 domains

## Technical Details

### Dockerfile Build Process

**Interactive Quickstart Setup:**
```bash
# Copy base dockerfile
cp base.dockerfile .devcontainer/Dockerfile

# Append language partial if selected
cat partials/go.dockerfile >> .devcontainer/Dockerfile  # example

# Generate firewall script from selections
# (or copy disabled.sh if firewall not wanted)
```

**YOLO Docker Maxxing Mode:**
```bash
# Copy templates as-is
cp base.dockerfile .devcontainer/Dockerfile
cp init-firewall.sh .devcontainer/init-firewall.sh
# No modifications
```

### Files Created

Interactive Quickstart setup creates the following file structure:

```
.devcontainer/
  ├── Dockerfile               (base + optional partial)
  ├── devcontainer.json         (VS Code config)
  ├── init-firewall.sh          (disabled or strict)
  └── setup-claude-credentials.sh
docker-compose.yml              (services: postgres, redis)
data/
  └── allowable-domains.json    (domain registry)
```

## Docker Compose Mode Selection

The plugin generates `docker-compose.yml` by default, but you can manually switch to alternative modes for specific scenarios:

![Docker Compose Mode Selection](../diagrams/svg/mode-selection.svg)

*Decision tree for selecting the appropriate Docker Compose mode based on platform and requirements.*

### Available Modes

- **Standard Bind Mount** (`docker-compose.yml`) - Direct file editing, best for Linux
- **Volume Mode** (`docker-compose.volume.yml`) - Fast I/O on Windows/macOS using Docker volumes
- **Prebuilt Mode** (`docker-compose.prebuilt.yml`) - CI/CD pipelines with pre-built images
- **Profiles Mode** (`docker-compose-profiles.yml`) - Backend/frontend service isolation with selective startup

See the [docker-compose templates](../../skills/_shared/templates/) directory for all available variants.

## Troubleshooting

### Wrong Docker Compose Mode Selected

**Symptoms:**
- Slow file I/O on Windows/macOS
- File changes not reflecting in container
- Permission errors on Linux

**Solutions:**

**On Windows/macOS with slow I/O:**
```bash
# Switch to volume mode for better performance
cp docker-compose.volume.yml docker-compose.yml
docker compose down && docker compose up -d
```

**On Linux with volume mode:**
```bash
# Switch to bind mount for direct file editing
cp docker-compose.bindmount.yml docker-compose.yml
docker compose down && docker compose up -d
```

### Profile Selection Issues

**Symptoms:**
- All services start when you only need one profile
- Wrong services running for your workload

**Solutions:**

**Start only backend services:**
```bash
docker compose --profile backend up -d
```

**Start only frontend:**
```bash
docker compose --profile frontend up -d
```

**Start everything:**
```bash
docker compose --profile backend --profile frontend up -d
```

**Fix profile configuration in `docker-compose-profiles.yml`:**
```yaml
services:
  postgres:
    profiles: ["backend"]  # Only starts with backend profile
```

### Firewall Mode Not Suitable for Project

**Symptoms:**
- Too restrictive: Can't access needed services
- Too permissive: Security concerns for sensitive data

**Solutions:**

**Switch firewall mode in `devcontainer.json`:**

```json
// Strict mode (allowlist only)
"FIREWALL_MODE": "strict",
"ALLOWED_DOMAINS": "github.com,npmjs.org,yourdomain.com"

// Domain allowlist (preset categories)
"FIREWALL_MODE": "domain-allowlist",
"FIREWALL_PRESET": "backend"

// Disabled (no restrictions)
"FIREWALL_MODE": "disabled"
```

**Rebuild container after changing:**
```bash
docker compose down
docker compose build
docker compose up -d
```

### Prebuilt Mode Not Finding Image

**Symptoms:**
- `docker compose up` fails with "image not found"
- CI/CD pipeline can't pull image

**Solutions:**

1. **Build and push image first:**
   ```bash
   docker compose -f docker-compose.prebuilt.yml build
   docker compose -f docker-compose.prebuilt.yml push
   ```

2. **Verify image tag in `docker-compose.prebuilt.yml`:**
   ```yaml
   services:
     app:
       image: your-registry/your-app:latest  # Must match pushed image
   ```

3. **Authenticate to registry:**
   ```bash
   docker login your-registry.com
   ```

### Port Conflicts

**Symptoms:**
- "port is already allocated" error
- Services can't bind to ports

**Solutions:**

1. **Change ports in `docker-compose.yml`:**
   ```yaml
   services:
     app:
       ports:
         - "8001:8000"  # Change 8000 to 8001
   ```

2. **Find what's using the port:**
   ```bash
   # Linux/macOS
   lsof -i :8000

   # Windows
   netstat -ano | findstr :8000
   ```

3. **Use auto-assigned ports:**
   ```yaml
   services:
     app:
       ports:
         - "8000"  # Docker assigns random host port
   ```

## See Also

- [Customization Guide](CUSTOMIZATION.md) - Modify templates and add services
- [Security Model](SECURITY-MODEL.md) - Firewall architecture and domain management
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions

