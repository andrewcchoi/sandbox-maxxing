# Master Template Files

This directory contains comprehensive master template files with ALL possible configurations. Generator scripts strip sections based on requirements to create mode-specific templates.

## Files

### 1. devcontainer.json.master
Comprehensive devcontainer configuration with all options.

**Sections (37 total):**
- `build` - Build configuration
- `base_image` - Base Docker image ARG
- `image` - Pre-built image reference
- `ptrace` - SYS_PTRACE capability for debugging
- `lifecycle` - postStartCommand, postCreateCommand
- `extensions_*` - VS Code extensions for various languages (git, javascript, python, go, rust, cpp, java, ruby, php, docker, yaml)
- `settings_*` - Language-specific VS Code settings
- `features` - Dev Container features
- `ports` - Port forwarding configuration
- `ports_*` - Port groups (backend, frontend, database, cache, other)
- `ports_attributes_*` - Port attributes for each group
- `env_*` - Environment variables for various languages (node, python, go, rust, docker)

**Placeholders:**
- `{{PROJECT_NAME}}` - Project name
- `{{IMAGE_NAME}}` - Docker image name (for image mode)
- `{{NETWORK_NAME}}` - Docker network name
- `{{FIREWALL_MODE}}` - Firewall mode (strict/permissive/disabled)
- `{{BASE_IMAGE}}` - Base Docker image (for build mode)

### 2. Dockerfile.master
Comprehensive Dockerfile with all packages and languages.

**Sections (14 total):**
- `packages_python` - Python 3 + pip + venv
- `packages_build` - Build tools (gcc, g++, make, cmake)
- `packages_go` - Go language toolchain
- `packages_rust` - Rust language toolchain
- `packages_java` - Java JDK + Maven + Gradle
- `packages_ruby` - Ruby + bundler
- `packages_php` - PHP + Composer
- `packages_database` - Database clients (psql, mysql, sqlite, redis)
- `packages_docker` - Docker CLI
- `npm_config` - NPM global configuration
- `claude_code` - Claude Code CLI installation
- `python_packages` - Common Python packages (pytest, black, etc.)
- `node_packages` - Common Node packages (typescript, eslint, etc.)

**Build Args:**
- `BASE_IMAGE` - Base Docker image (default: node:20-bookworm-slim)
- `TZ` - Timezone (default: America/Los_Angeles)
- `CLAUDE_CODE_VERSION` - Claude Code version (default: latest)
- `GIT_DELTA_VERSION` - git-delta version (default: 0.18.2)
- `ZSH_IN_DOCKER_VERSION` - ZSH installer version (default: 1.2.0)

**Always Included:**
- Core utilities (git, vim, nano, curl, wget, etc.)
- ZSH with Powerlevel10k theme
- git-delta for enhanced diffs
- GitHub CLI (gh)
- Firewall tools (iptables, ipset, iproute2, dnsutils)
- Node user (uid/gid 1000)

### 3. init-firewall.master.sh
Complete firewall script with all domain categories.

**Categories (10 total):**
- `version_control` - GitHub, GitLab, Bitbucket
- `package_registries` - npm, PyPI, RubyGems, Crates.io, Go modules, Packagist, Maven
- `ai_providers` - Anthropic, OpenAI, Groq
- `analytics_telemetry` - Sentry, Statsig
- `vscode` - VS Code marketplace and updates
- `cdn` - jsDelivr, unpkg, cdnjs
- `container_registries` - Docker Hub, GHCR, GCR, Quay
- `cloud_providers` - AWS S3, Google Cloud Storage, Azure Blob
- `language_tools` - Go downloads, Rust installer
- `custom` - User-defined domains

**Modes:**
- `strict` - Whitelist only (default)
- `permissive` - Allow all traffic
- `disabled` - Skip firewall configuration

## Usage

Generator scripts should:
1. Read the master template
2. Strip unwanted sections using markers:
   - `# ===SECTION_START:name===` / `# ===SECTION_END:name===` (Dockerfile, shell)
   - `// ===SECTION_START:name===` / `// ===SECTION_END:name===` (JSON)
   - `# ===CATEGORY_START:name===` / `# ===CATEGORY_END:name===` (firewall categories)
3. Replace placeholders with actual values
4. Write to output location

## Section Marker Format

### Dockerfile and Shell Scripts
```bash
# ===SECTION_START:section_name===
content to be conditionally included
# ===SECTION_END:section_name===
```

### JSON/JSONC Files
```json
// ===SECTION_START:section_name===
"key": "value",
// ===SECTION_END:section_name===
```

## Example: Creating Basic Template

To create a basic template with only Node.js support:

1. Keep these sections in Dockerfile.master:
   - Base packages (always included)
   - `npm_config`
   - `claude_code`
   - `node_packages`

2. Remove these sections:
   - `packages_python`
   - `packages_build`
   - `packages_go`
   - `packages_rust`
   - `packages_java`
   - `packages_ruby`
   - `packages_php`
   - `packages_database`
   - `packages_docker`
   - `python_packages`

3. Keep these sections in devcontainer.json.master:
   - `build`
   - `lifecycle`
   - `extensions_git`
   - `extensions_javascript`
   - `settings_javascript`
   - `env_node`

4. Remove language-specific sections for unused languages

## Validation

All master templates are validated:
- **Dockerfile.master**: Valid Dockerfile syntax
- **devcontainer.json.master**: Valid JSONC (JSON with Comments)
- **init-firewall.master.sh**: Valid bash syntax
- **Line endings**: Unix (LF) format

## Maintenance

When adding new features:
1. Add to master template with appropriate section markers
2. Update this README with the new section name
3. Update generator scripts to handle the new section
4. Test with all sandbox modes (Basic, Intermediate, Advanced, YOLO)
