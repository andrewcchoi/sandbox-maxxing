# DevContainer Setup Options

This guide explains the two ways to create a DevContainer with this plugin: **Interactive Setup** and **YOLO Mode**.

## Quick Comparison

| Feature                   | Interactive Setup (`/devcontainer:setup`) | YOLO Mode (`/devcontainer:yolo`)     |
| ------------------------- | ----------------------------------------- | ------------------------------------- |
| **Questions Asked**       | 2-3                                       | 0 (instant)                          |
| **Project Type Selection**| Yes (Python/Node, Go, Ruby, Rust, Java)   | Python 3.12 + Node 20 (base)         |
| **Firewall Customization**| Yes (interactive domain selection)        | Disabled (Docker isolation only)     |
| **Setup Time**            | 2-3 minutes                               | <30 seconds                          |
| **Best For**              | Custom requirements, security needs       | Quick start, sensible defaults       |
| **Base Image**            | Base + optional language partial          | Base only (multi-language)           |
| **Network Security**      | Optional strict firewall with allowlist   | No firewall (container isolation)    |

## Interactive Setup

**Command:** `/devcontainer:setup`

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
You: /devcontainer:setup

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

## YOLO Mode

**Command:** `/devcontainer:yolo`

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
You: /devcontainer:yolo

Claude: Creating DevContainer (YOLO mode)...
        - Project: my-app
        - Language: Python 3.12 + Node 20
        - Firewall: Disabled
        ✓ Done in 18 seconds

        Next: Open in VS Code → 'Reopen in Container'
```

## Language Support

Both options use the same base image (Python 3.12 + Node 20) with different approaches:

### Base Image Includes

- **Python:** 3.12 with uv, pip, pytest, black, mypy
- **Node:** 20 LTS with npm, yarn, pnpm
- **System tools:** git, vim, zsh, fzf, gh CLI
- **Database clients:** psql, mysql, redis-cli
- **DevOps tools:** Docker-in-Docker capabilities
- **Firewall tools:** iptables, ipset (if firewall enabled)

### Language Partials (Interactive Setup Only)

When you select a language in interactive mode, a partial is **appended** to the base Dockerfile:

| Language | What Gets Added |
|----------|-----------------|
| Go       | Go 1.22, gopls, delve, staticcheck, golint |
| Ruby     | Ruby 3.3, bundler, rake, rspec, rubocop |
| Rust     | Rust toolchain, Cargo, rustfmt, clippy, rust-analyzer |
| Java     | OpenJDK 21, Maven, Gradle |

**YOLO mode** uses only the base image - if you need additional language tools, use interactive setup.

## Firewall Behavior

### No Firewall (YOLO Mode Default)

- Relies on Docker container isolation
- All outbound network traffic allowed
- Fastest setup, no configuration needed
- Suitable for trusted code and local development

### Strict Firewall (Interactive Setup Option)

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

## Migration from v4.2 → v4.3

### Removed Commands

- `/devcontainer:basic` → Use `/devcontainer:yolo` (closest equivalent)
- `/devcontainer:advanced` → Use `/devcontainer:setup` with firewall enabled

### Key Changes

**v4.2 and earlier:**
- 3 separate commands (basic, advanced, yolo)
- Each command copied templates without customization
- Modes differed only by firewall script

**v4.3:**
- 2 commands: `setup` (interactive) and `yolo` (instant)
- Project type selection adds language-specific tools
- Firewall customization via domain category selection
- More flexible, less confusing

### Upgrade Path

If you're used to the old modes:

| Old Command | New Equivalent |
|-------------|----------------|
| `/devcontainer:basic` | `/devcontainer:yolo` |
| `/devcontainer:advanced` with Python | `/devcontainer:setup` → Python/Node → Yes → Select categories |
| `/devcontainer:advanced` with Go | `/devcontainer:setup` → Go → Yes → Select categories |
| `/devcontainer:yolo` | Still exists, now means "instant defaults" |

## Technical Details

### Dockerfile Build Process

**Interactive Setup:**
```bash
# Copy base dockerfile
cp base.dockerfile .devcontainer/Dockerfile

# Append language partial if selected
cat partials/go.dockerfile >> .devcontainer/Dockerfile  # example

# Generate firewall script from selections
# (or copy disabled.sh if firewall not wanted)
```

**YOLO Mode:**
```bash
# Copy templates as-is
cp base.dockerfile .devcontainer/Dockerfile
cp init-firewall/disabled.sh .devcontainer/init-firewall.sh
# No modifications
```

### Files Created

Both modes create the same file structure:

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

## See Also

- [Customization Guide](CUSTOMIZATION.md) - Modify templates and add services
- [Security Model](security-model.md) - Firewall architecture and domain management
- [Troubleshooting](TROUBLESHOOTING.md) - Common issues and solutions

---

**Last Updated:** 2025-12-23
**Version:** 4.3.1
