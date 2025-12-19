# Sandbox Mode Comparison Guide

This guide helps you choose the right sandbox mode for your project and understand the differences between Basic, Intermediate, Advanced, and YOLO modes.

## Quick Reference Table

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| **Target Audience** | Beginners, rapid prototyping | Regular developers, team projects | Security-conscious, production prep | Experts, custom environments |
| **Setup Time** | 1-2 minutes | 3-5 minutes | 8-12 minutes | 15-30 minutes |
| **Questions Asked** | 2-3 | 5-8 | 10-15 | 15-20+ |
| **Base Images** | sandbox-templates (latest, claude-code) | Official images (python:3.12-slim) | Security-hardened official | Any (including nightly/experimental) |
| **Firewall** | None (container isolation) | Permissive (no restrictions) | Strict (customizable allowlist) | Optional or fully custom |
| **VS Code Extensions** | 5-8 essential | 10-15 curated | 20+ comprehensive | User-controlled |
| **Dockerfile Complexity** | Single-stage | Single-stage with build args | Multi-stage optimized | Fully custom |
| **Auto-Detection** | Yes | Partial | No | No |
| **Service Defaults** | PostgreSQL + Redis | User choice | User choice | User choice |
| **Network Security** | High (default DROP) | Medium (expanded whitelist) | Maximum (minimal whitelist) | User-controlled |
| **Customization** | Minimal | Moderate | High | Complete |
| **Production Ready** | No | Development/staging | Yes | Depends on config |
| **Learning Curve** | Easy | Easy-Moderate | Moderate-Hard | Expert |
| **Maintenance** | Low | Low-Medium | Medium-High | High |

### MCP Server Configuration

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| MCP Servers | 2 | 5 | 8 | 11+ |
| filesystem | ✓ | ✓ | ✓ | ✓ |
| memory | ✓ | ✓ | ✓ | ✓ |
| sqlite | - | ✓ | ✓ | ✓ |
| fetch | - | ✓ | ✓ | ✓ |
| github | - | ✓ | ✓ | ✓ |
| postgres | - | - | ✓ | ✓ |
| docker | - | - | ✓ | ✓ |
| brave-search | - | - | ✓ | ✓ |
| puppeteer | - | - | - | ✓ |
| slack | - | - | - | ✓ |
| google-drive | - | - | - | ✓ |

See [MCP Configuration Guide](MCP.md) for details.

### VS Code Extensions

| Category | Basic | Intermediate | Advanced | YOLO |
|----------|-------|--------------|----------|------|
| Essential | 3 | 5 | 7 | 7 |
| Language | 2+ | 4+ | 4+ | 6+ |
| Themes | 1 | 3 | 5 | 9 |
| Productivity | 0 | 2 | 4 | 4 |
| Fun | 1 | 3 | 4 | 7 |
| **Total** | **6-8** | **15-20** | **22-28** | **35+** |

See [Extensions Reference](EXTENSIONS.md) for details.

### Variables Configuration

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| Build ARGs | 5 (BASE_IMAGE, TZ, versions) | 8 (+ messaging, DB options) | 12+ (+ cloud, API configs) | Custom |
| Runtime ENVs | 6 (NODE_ENV, paths) | 12 (+ service configs) | 20+ (comprehensive) | Custom |
| VS Code Inputs | 0 | 2-3 (DB creds) | 5+ (all services) | Custom |
| .env Template | Minimal | Standard | Comprehensive | Full |
| Secret Mounts | 0 | 0 | 5+ | Custom |

See [Variables Guide](VARIABLES.md) for details.

### Secrets Management

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| Secret Handling | Development defaults | VS Code inputs | Docker secrets + inputs | All methods |
| Git Authentication | None | VS Code input | VS Code input + SSH | All methods |
| Database Credentials | Hardcoded defaults | Optional input override | Required inputs | Custom |
| API Keys | None | GitHub token (optional) | All APIs (required) | Custom |
| Cloud Credentials | None | None | Host mounts | Custom |
| Build Secrets | None | None | NPM, PyPI, gems | Custom |
| SSL/TLS Certificates | None | None | Docker secrets | Custom |

See [Secrets Management Guide](SECRETS.md) for details.

## Mode Details

### Basic Mode - Zero Configuration Development

**Philosophy**: Get started in minutes with sensible defaults.

**Best For**:
- First-time DevContainer users
- Rapid prototyping and proof-of-concepts
- Solo developers wanting quick setup
- Learning projects and tutorials
- Short-lived development environments

**Setup Experience**:
```
You: /sandbox:basic

Claude: I detected a Python FastAPI project. Setting up with:
        - Base: docker/sandbox-templates:claude-code
        - Database: PostgreSQL 16
        - Cache: Redis 7
        - Firewall: Strict (essential domains only)

        Generating configs... Done!
        Run: docker compose up -d
```

**What You Get**:
- **Base Image**: `docker/sandbox-templates:latest` or `claude-code` (329-366 MB)
- **Dockerfile**: Single-stage, pre-configured for Claude Code
- **Services**: PostgreSQL + Redis (can disable if not needed)
- **VS Code Extensions**:
  - Python: `ms-python.python`, `ms-python.vscode-pylance`
  - General: `ms-vscode.makefile-tools`, `eamodio.gitlens`
  - Docker: `ms-azuretools.vscode-docker`
- **Firewall Categories**:
  - Anthropic services (claude.ai, api.anthropic.com)
  - Version control (github.com, gitlab.com)
  - Container registries (docker.io, ghcr.io)
  - Linux repos (ubuntu.com, security.ubuntu.com)
  - VS Code (marketplace.visualstudio.com)
  - Package managers: npm, Python, Ruby, Rust, Go, Maven
- **Network Mode**: Strict firewall with DROP default policy
- **Questions**: 2-3 maximum

**Limitations**:
- Limited customization options
- Fixed service choices (PostgreSQL/Redis or none)
- No control over base image beyond official options
- Not suitable for production deployments
- May include unnecessary tools for simple projects

**When to Upgrade**:
- Need different database (MySQL, MongoDB)
- Want to customize Python/Node versions
- Need additional VS Code extensions
- Require cloud platform access (GCP, Azure)
- Project growing beyond prototype stage

---

### Intermediate Mode - Balanced Control

**Philosophy**: Convenience with flexibility where it matters.

**Best For**:
- Regular development work
- Team projects with standardization
- Projects needing specific versions
- Multi-language stacks
- Long-term development environments

**Setup Experience**:
```
You: /sandbox:intermediate

Claude: What's your primary language?
        • Python • Node.js • Ruby • Go • PHP

You: Python

Claude: Python version?
        • 3.13 (latest) • 3.12 (stable, recommended) • 3.11 (LTS)

You: 3.12

Claude: What database?
        • PostgreSQL • MySQL • MongoDB • None

You: PostgreSQL

Claude: Need Redis cache? [Y/n]
        Redis provides fast in-memory caching, recommended for web apps.

You: y

Claude: Firewall mode?
        • Strict (blocks all except whitelist)
        • Expanded (includes cloud platforms)

You: Expanded
```

**What You Get**:
- **Base Image**: Official Docker images (e.g., `python:3.12-slim-bookworm`)
- **Dockerfile**: Single-stage with build arguments:
  ```dockerfile
  ARG PYTHON_VERSION=3.12
  ARG NODE_VERSION=20
  FROM python:${PYTHON_VERSION}-slim-bookworm
  ```
- **Services**: Your choice (PostgreSQL, MySQL, MongoDB, Redis, RabbitMQ)
- **VS Code Extensions**: 10-15 curated for your stack
  - Python: Base + Black, Pylint, Jupyter
  - Node: ESLint, Prettier, npm IntelliSense
  - Database: SQLTools for PostgreSQL/MySQL
  - General: REST Client, YAML, Docker Compose
- **Firewall Categories**: All from Basic PLUS:
  - Cloud platforms (GCP, Azure, Oracle)
  - Development tools (Kubernetes, Hashicorp, Anaconda)
  - Analytics/telemetry (Statsig, Sentry)
  - Content delivery (CDNs, mirrors)
  - Schema configuration (JSON Schema Store)
  - All package managers (PHP, .NET, Dart, Elixir, Perl, etc.)
- **Network Mode**: Strict with expanded whitelist (100+ domains)
- **Questions**: 5-8 with explanations

**Configuration Options**:
- Language runtime versions (via build args)
- Service selection and versions
- VS Code extension preferences
- Firewall strictness level
- Optional dev tools (IPython, debugging, profiling)

**Advantages Over Basic**:
- Version control without rebuilding images
- More service options
- Suitable for team sharing (everyone uses same base)
- Better VS Code integration
- Cloud platform access

**Limitations**:
- Not optimized for production
- Still using pre-built patterns
- Limited security customization
- May include more than minimal needs

**When to Upgrade**:
- Preparing for production deployment
- Need maximum security hardening
- Want multi-stage build optimization
- Require minimal attack surface
- Need custom security policies

---

### Advanced Mode - Security-First Minimal

**Philosophy**: Production-ready with minimal attack surface.

**Best For**:
- Security-conscious development
- Production preparation
- Compliance requirements (SOC2, HIPAA)
- Sensitive data handling
- Client projects requiring security review
- Open-source projects with security focus

**Setup Experience**:
```
You: /sandbox:advanced

Claude: This mode creates security-hardened configurations.

        **Step 1: Base Configuration**

        Project name? [my-project]
        This will be used for container, network, and volume names.

You: secure-api

Claude: **Step 2: Base Image Selection**

        For security, we'll use hardened official images with:
        - Minimal system packages
        - Security updates
        - Non-root user
        - Small attack surface

        Primary language?
        • Python 3.12 (python:3.12-slim-bookworm - 132MB)
        • Node.js 20 LTS (node:20-bookworm-slim - 175MB)
        • Go 1.22 (golang:1.22-bookworm - 321MB)

[10 more detailed questions with security explanations...]
```

**What You Get**:
- **Base Image**: Security-hardened official images (slim variants)
- **Dockerfile**: Multi-stage optimized:
  ```dockerfile
  # Stage 1: Builder
  FROM python:3.12-slim-bookworm AS builder
  RUN pip install --user --no-cache-dir -r requirements.txt

  # Stage 2: Runtime (minimal)
  FROM python:3.12-slim-bookworm
  COPY --from=builder /root/.local /root/.local
  # Only runtime dependencies, no build tools
  ```
- **Services**: Minimal required services only
- **VS Code Extensions**: 20+ comprehensive including:
  - Full language support
  - Security scanners (Snyk, Security)
  - Code quality (SonarLint)
  - Documentation tools
  - Database management
- **Firewall**: Minimal whitelist (30-40 domains)
  - Anthropic services
  - Version control
  - Container registries
  - Essential Linux repos
  - VS Code marketplace
  - Only npm and Python package managers (no others by default)
  - NO cloud platforms (add explicitly if needed)
  - NO analytics/telemetry
  - NO CDNs (use local mirrors)
- **Network Mode**: Maximum security with explicit additions required
- **Questions**: 10-15 with security rationale

**Security Features**:
- Non-root user enforcement
- Minimal Linux capabilities
- Read-only filesystem options
- Resource limits (CPU, memory)
- Health checks
- Security scanning integration
- Secrets management patterns
- Network segmentation

**Advanced Configuration**:
```yaml
# docker-compose.yml includes security hardening
services:
  app:
    cap_drop: [ALL]
    cap_add: [NET_ADMIN, NET_RAW]  # Only for firewall
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/tmp
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 2G
```

**Advantages**:
- Production-ready configuration
- Minimal attack surface
- Security best practices built-in
- Audit-friendly
- Optimized image sizes
- Clear security model

**Limitations**:
- More complex setup
- Requires security knowledge
- May need manual firewall additions
- Higher maintenance overhead
- Less convenient for rapid iteration

**When to Use YOLO Instead**:
- Need experimental features
- Want complete control
- Testing nightly builds
- Custom security requirements
- Research/experimental projects

---

### YOLO Mode - Maximum Flexibility

**Philosophy**: You know what you're doing. We'll get out of your way.

**Best For**:
- Expert DevContainer users
- Custom/experimental environments
- Research and development
- Testing bleeding-edge features
- Environments with unique requirements
- When none of the other modes fit

**Setup Experience**:
```
You: /sandbox:yolo

Claude: YOLO mode - You're in control!

        This mode allows:
        - Any base image (including nightly/experimental)
        - Optional firewall (can disable entirely)
        - Custom everything
        - Full VS Code extension control

        ⚠️  Warning: YOLO mode provides maximum flexibility but minimal
        safety rails. Ensure you understand the security implications.

[15-20+ questions with full customization options...]

Claude: Base image source?
        • Official Docker (python, node, etc.)
        • Docker sandbox-templates (latest, claude-code, nightly)
        • Custom registry (specify full path)
        • Local Dockerfile (you provide)

You: sandbox-templates

Claude: sandbox-templates tag?
        • latest (stable)
        • claude-code (optimized)
        • nightly (unstable, latest features)
        • 0.1.0-alpha.1 (specific alpha)
        • cagent (agent-focused)
        • Custom tag

You: nightly

Claude: Firewall?
        • Disabled (allow all traffic)
        • Custom whitelist (you provide domains)
        • Strict (minimal whitelist, you'll add more)
        • Expanded (full whitelist)

You: Disabled
```

**What You Get**:
- **Base Image**: Anything:
  - `docker/sandbox-templates:nightly`
  - `docker/sandbox-templates:cagent`
  - Custom registries (internal, experimental)
  - Your own Dockerfile
- **Dockerfile**: You choose:
  - Use template as-is
  - Multi-stage custom
  - Your own from scratch
- **Services**: Any combination, any versions
- **VS Code Extensions**: Full control (or none)
- **Firewall**:
  - Can disable completely
  - Can use empty whitelist
  - Can provide custom domain list
  - Can mix mode defaults with custom
- **Network Mode**: Your choice
- **Questions**: As many as needed for full customization

**What's Different**:
- Access to experimental/nightly images
- Can disable safety features
- Can use non-standard configurations
- Can test unreleased features
- Full control over every aspect

**Example Use Cases**:

1. **Testing Nightly Features**:
   ```
   Base: docker/sandbox-templates:nightly
   Firewall: Disabled (testing needs full access)
   Extensions: Minimal (testing environment itself)
   ```

2. **Custom Internal Setup**:
   ```
   Base: internal-registry.company.com/dev:latest
   Firewall: Custom corporate whitelist
   Extensions: Company-standard set
   Services: Internal auth + custom DB
   ```

3. **Research Environment**:
   ```
   Base: docker/sandbox-templates:gemini
   Firewall: Disabled (need full internet access)
   Extensions: Full AI tooling
   Services: Ollama + ChromaDB + PostgreSQL
   ```

4. **Minimalist Setup**:
   ```
   Base: alpine:latest
   Firewall: Strict minimal (5 domains)
   Extensions: None
   Services: None
   ```

**Risks and Warnings**:
- Nightly images may be unstable
- Disabled firewall exposes to internet
- Experimental features may break
- No security guarantees
- You're responsible for hardening
- May not work with future plugin versions

**When to Use YOLO**:
- You have specific requirements none of the other modes meet
- You're testing experimental features
- You need to disable safety features temporarily
- You're an expert and know the risks
- You're doing research requiring unusual configurations

**When NOT to Use YOLO**:
- Production environments (use Advanced instead)
- Sensitive data (use Advanced instead)
- Team projects (use Intermediate instead)
- Learning projects (use Basic instead)
- When you're unsure (use Intermediate instead)

---

## Decision Tree

```
START: What's your primary goal?
│
├─ "Get started quickly" → BASIC
│   └─ "But I need MySQL not PostgreSQL" → INTERMEDIATE
│
├─ "Normal development work" → INTERMEDIATE
│   ├─ "With production deployment later" → ADVANCED
│   └─ "With team using same setup" → INTERMEDIATE
│
├─ "Maximum security" → ADVANCED
│   └─ "But I need experimental features" → YOLO
│
├─ "Complete customization" → YOLO
│   └─ "But with security focus" → ADVANCED
│
└─ "I don't know" → BASIC (start here)
```

## Security Comparison

### Threat Model Coverage

| Threat | Basic | Intermediate | Advanced | YOLO |
|--------|-------|--------------|----------|------|
| Malicious dependency (data exfiltration) | Protected | Protected | Maximum protection | User-controlled |
| Compromised package manager | Protected | Protected | Maximum protection | User-controlled |
| Container escape | Mitigated | Mitigated | Maximum mitigation | User-controlled |
| Credential leakage | Detected | Detected | Prevented | User-controlled |
| Supply chain attack | Reduced risk | Reduced risk | Minimal risk | User-controlled |
| Network eavesdropping | N/A (firewall blocks) | N/A (firewall blocks) | N/A (firewall blocks) | Depends on config |
| Privilege escalation | Mitigated (non-root) | Mitigated (non-root) | Prevented (hardened) | User-controlled |

### Security Feature Matrix

| Feature | Basic | Intermediate | Advanced | YOLO |
|---------|-------|--------------|----------|------|
| Default DROP firewall | Yes | Yes | Yes | Optional |
| Non-root user | Yes | Yes | Yes | Optional |
| Minimal capabilities | No | No | Yes | Optional |
| Read-only filesystem | No | No | Yes | Optional |
| Resource limits | No | No | Yes | Optional |
| Multi-stage builds | No | No | Yes | Optional |
| Security scanning | No | No | Yes | Optional |
| Secrets management | Basic | Basic | Advanced | Optional |
| Network segmentation | Basic | Basic | Advanced | Optional |

### Firewall Domain Counts

- **Basic**: 40-50 essential domains (tight but functional)
- **Intermediate**: 100+ domains (convenient for most work)
- **Advanced**: 30-40 minimal domains (requires explicit additions)
- **YOLO**: 0 to unlimited (your choice)

## Configuration Complexity

### File Sizes (typical)

| Mode | devcontainer.json | Dockerfile | docker-compose.yml | init-firewall.sh | Total Lines |
|------|-------------------|------------|-------------------|-----------------|-------------|
| Basic | 80 lines | 50 lines | 60 lines | 100 lines | ~290 |
| Intermediate | 120 lines | 80 lines | 100 lines | 200 lines | ~500 |
| Advanced | 180 lines | 150 lines | 150 lines | 150 lines | ~630 |
| YOLO | Varies | Varies | Varies | Varies | ~200-1000+ |

### Maintainability

**Basic**:
- Update frequency: Low (rarely needs changes)
- Complexity: Very low
- Documentation needs: Minimal
- Team onboarding: Immediate

**Intermediate**:
- Update frequency: Low-Medium (version bumps via build args)
- Complexity: Low-Medium
- Documentation needs: Moderate
- Team onboarding: 1-2 hours

**Advanced**:
- Update frequency: Medium (security updates, optimizations)
- Complexity: Medium-High
- Documentation needs: High
- Team onboarding: 1-2 days

**YOLO**:
- Update frequency: High (you maintain everything)
- Complexity: Varies (depends on your config)
- Documentation needs: Critical (no defaults to fall back on)
- Team onboarding: Requires expert knowledge

## Use Case Examples

### Use Case 1: Solo Developer Learning FastAPI

**Scenario**: Building first FastAPI app, following tutorial, needs database.

**Recommended Mode**: **Basic**

**Rationale**:
- Tutorial likely uses PostgreSQL
- Don't want to spend time on DevContainer config
- Need it working quickly
- Will throw away after learning

**Setup**:
```bash
/sandbox:basic
# Auto-detects Python + FastAPI
# Creates PostgreSQL + Redis
# Ready in 90 seconds
```

---

### Use Case 2: Startup Building MVP

**Scenario**: 3-person team, React + Node.js + MongoDB, iterating fast.

**Recommended Mode**: **Intermediate**

**Rationale**:
- Team needs consistent environment
- Want MongoDB (not PostgreSQL default)
- Need to pin Node version (team standardization)
- May need AWS access later
- Not ready for production yet

**Setup**:
```bash
/sandbox:intermediate
# Choose: Node.js 20
# Choose: MongoDB
# Choose: Expanded firewall (for AWS)
# Share config with team
```

---

### Use Case 3: SaaS Company Production App

**Scenario**: Existing app, preparing for SOC2 audit, handling customer data.

**Recommended Mode**: **Advanced**

**Rationale**:
- Security is critical (customer data)
- Need audit trail
- Must document security measures
- Production deployment soon
- Compliance requirements

**Setup**:
```bash
/sandbox:advanced
# Answer security questions
# Review firewall whitelist
# Document choices for audit
# Use in staging and production
```

---

### Use Case 4: Research Project Testing AI Models

**Scenario**: PhD student testing Ollama + custom embeddings + experimental features.

**Recommended Mode**: **YOLO**

**Rationale**:
- Need Ollama (not in standard templates)
- Want nightly builds for latest features
- Need to download models (firewall would block)
- Experimental setup
- Solo project (no team coordination)

**Setup**:
```bash
/sandbox:yolo
# Base: docker/sandbox-templates:gemini
# Firewall: Disabled
# Services: Ollama + ChromaDB + PostgreSQL
# Extensions: Custom AI tooling
```

---

### Use Case 5: Open Source Python Library

**Scenario**: Public GitHub repo, accepting contributions, running CI/CD.

**Recommended Mode**: **Intermediate** or **Advanced**

**Rationale**:
- Contributors need easy setup (Intermediate)
- But security matters for trust (Advanced)
- Compromise: Start Intermediate, offer Advanced

**Setup**:
```bash
# In README.md
## Development Setup

### Quick Start (Recommended for Contributors)
/sandbox:intermediate

### Security-Focused Setup (For Maintainers)
/sandbox:advanced
```

---

### Use Case 6: Corporate Internal Tool

**Scenario**: Internal Python tool, custom corporate registry, specific compliance requirements.

**Recommended Mode**: **YOLO**

**Rationale**:
- Must use corporate registry
- Has specific firewall rules (corporate domains)
- Unique requirements don't fit modes
- Expert team maintaining it

**Setup**:
```bash
/sandbox:yolo
# Base: internal.company.com/python-dev:latest
# Firewall: Custom corporate whitelist
# Extensions: Company-standard set
# Document as company template
```

---

## Mode Migration Paths

### Upgrading: Basic → Intermediate

**When**: Project grows, need more control

**Steps**:
1. Note your current config (PostgreSQL version, etc.)
2. Run `/sandbox:intermediate`
3. Choose same services but with version control
4. Migrate data from old volumes to new
5. Test thoroughly

**Migration Time**: 30-60 minutes

---

### Upgrading: Intermediate → Advanced

**When**: Preparing for production, security review

**Steps**:
1. Audit current setup (what's actually needed?)
2. Document security requirements
3. Run `/sandbox:advanced`
4. Review firewall whitelist (add project-specific domains)
5. Test with strict firewall (may need iterations)
6. Update CI/CD to use new config
7. Document security measures

**Migration Time**: 4-8 hours (includes testing and documentation)

---

### Upgrading: Basic → Advanced

**When**: Prototype → Production, skipping intermediate

**Steps**:
1. List all current functionality
2. Document data that must be preserved
3. Review security requirements
4. Run `/sandbox:advanced`
5. Methodically test each feature (firewall may block)
6. Add domains as needed (one by one, document each)
7. Performance test
8. Security audit

**Migration Time**: 8-16 hours (big jump)

---

### Lateral Move: Any → YOLO

**When**: Standard modes don't meet unique requirements

**Steps**:
1. Export current config
2. Document what works and what doesn't
3. List exact customizations needed
4. Run `/sandbox:yolo`
5. Replicate working config
6. Add customizations
7. Extensive testing
8. Document everything (no defaults to rely on)

**Migration Time**: 2-4 hours (just configuration)

---

## FAQ

### Q: Can I start with YOLO and move to Advanced later?

**A**: Yes, but it's usually easier to go the other way. YOLO gives you complete freedom, which means you might configure things in non-standard ways. Moving to Advanced means fitting into a more opinionated structure. Better to start with Advanced and move to YOLO if you need more flexibility.

### Q: Why would I use Basic over Intermediate?

**A**: Speed. If you're prototyping or learning and the defaults work for you, Basic gets you running in under 2 minutes. Intermediate asks 5-8 questions which slows you down. Use Basic when you want to focus on your app, not the environment.

### Q: Is Advanced mode actually "production-ready"?

**A**: It's production-ready from a security standpoint, but you still need:
- Proper secrets management (not in docker-compose.yml)
- Monitoring and logging
- Backup strategy
- Scaling configuration
- Load balancing

Advanced mode gives you a secure foundation, not a complete production system.

### Q: What if I need a service not in the mode?

**A**:
- **Basic**: You can manually add to docker-compose.yml after generation
- **Intermediate**: Choose "Custom" when asked about services
- **Advanced**: You'll be asked about each service specifically
- **YOLO**: Full control, add anything

### Q: Can I mix mode features?

**A**: Not directly through the plugin, but you can:
1. Generate config in one mode
2. Manually copy features from another mode's example
3. Use YOLO mode and manually implement what you want

### Q: How do I add a firewall domain after setup?

**A**: Edit `.devcontainer/init-firewall.sh`:
```bash
# Find the section with iptables rules
iptables -A OUTPUT -d example.com -j ACCEPT
```

Then rebuild container: `docker compose down && docker compose up -d`

### Q: Which mode for Kubernetes development?

**A**: **Intermediate** (includes k8s.io domains) or **Advanced** (if you want minimal and will add k8s domains explicitly).

### Q: Which mode for GitHub Actions?

**A**: **Intermediate** or **Advanced**. Both work with CI/CD. Use Intermediate for convenience, Advanced for security-critical projects.

### Q: Can I change modes without losing data?

**A**: Yes, use Docker volumes:
1. Note volume names from current `docker-compose.yml`
2. Generate new config in different mode
3. Update new `docker-compose.yml` to use same volume names
4. Data persists across mode changes

### Q: What's the difference between Advanced and YOLO for security?

**A**:
- **Advanced**: Opinionated security (we choose hardening measures)
- **YOLO**: You choose everything (can be more secure if you know what you're doing, or less secure if you don't)

For most users wanting security: Use Advanced.

---

## Summary

**Choose Basic if**:
- First time with DevContainers
- Rapid prototyping
- Following tutorial
- Solo learning project
- Want to start coding immediately

**Choose Intermediate if**:
- Regular development work
- Team project
- Need specific versions
- Want some control
- Balancing convenience and flexibility

**Choose Advanced if**:
- Security is critical
- Production deployment
- Handling sensitive data
- Compliance requirements
- Want minimal attack surface

**Choose YOLO if**:
- Expert user
- Unique requirements
- Experimental features
- Research project
- None of the other modes fit

**Still unsure?** Start with Basic. You can always upgrade later.


---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
