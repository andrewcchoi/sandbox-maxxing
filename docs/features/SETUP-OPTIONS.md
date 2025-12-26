# DevContainer Setup Options

This guide explains how to create a DevContainer with this plugin using **Interactive Setup**.

## Interactive Setup Features

| Feature                    | Details                                             |
| -------------------------- | --------------------------------------------------- |
| **Questions Asked**        | 2-3 (minimal configuration)                         |
| **Project Type Selection** | Yes (Python/Node, Go, Ruby, Rust, Java)             |
| **Firewall Customization** | Yes (optional, interactive domain selection)        |
| **Setup Time**             | 2-3 minutes                                         |
| **Base Image**             | Base + optional language partial                    |
| **Network Security**       | Optional strict firewall with allowlist or disabled |

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
  ○ Java (adds JDK, Maven, Gradle)
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

## YOLO Vibe Maxxing Mode

**Command:** `/sandboxxer:yolo-vibe-maxxing`

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
You: /sandboxxer:yolo-vibe-maxxing

Claude: Creating DevContainer (YOLO Vibe Maxxing mode)...
        - Project: my-app
        - Language: Python 3.12 + Node 20
        - Firewall: Disabled
        ✓ Done in 18 seconds

        Next: Open in VS Code → 'Reopen in Container'
```

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
| Java     | OpenJDK 21, Maven, Gradle                             |

**YOLO Vibe Maxxing mode** uses only the base image - if you need additional language tools, use interactive setup.

## Firewall Behavior

### No Firewall (YOLO Vibe Maxxing Mode Default)

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

**YOLO Vibe Maxxing Mode:**
```bash
# Copy templates as-is
cp base.dockerfile .devcontainer/Dockerfile
cp init-firewall/disabled.sh .devcontainer/init-firewall.sh
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

## See Also

- [Customization Guide](CUSTOMIZATION.md) - Modify templates and add services
- [Security Model](SECURITY-MODEL.md) - Firewall architecture and domain management
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions

---

**Last Updated:** 2025-12-25
**Version:** 4.6.0
