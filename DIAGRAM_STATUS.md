# Diagram Status Dashboard

> **Auto-generated:** 2026-02-07
> **Plugin Version:** 4.13.0
> **Total Diagrams:** 12

---

## 📊 Overall Status

| Metric | Count | Status |
|--------|-------|--------|
| **Mermaid Sources (.mmd)** | 12 | ✅ Complete |
| **SVG Outputs (.svg)** | 12 | ✅ Complete |
| **Orphaned SVGs** | 0 | ✅ Clean |
| **Missing SVGs** | 0 | ✅ Clean |
| **Version Consistency** | 5/5 | ✅ Synced |
| **Documentation Files** | 45+ | ✅ Complete |

---

## 📑 Diagram Inventory

### 1. Plugin Architecture
**File:** `plugin-architecture.mmd` → `svg/plugin-architecture.svg`
**Type:** Component Hierarchy
**Status:** ✅ Active

**Purpose:** Shows the component hierarchy of the sandboxxer plugin

**Components Documented:**
- Commands: 8 (quickstart, yolo-docker-maxxing, yolo-linux-maxxing, troubleshoot, linux-troubleshoot, audit, health, deploy-to-azure)
- Skills: 3 (sandboxxer-troubleshoot, sandboxxer-audit, sandboxxer-linux-troubleshoot)
- Agents: 3 (devcontainer-generator, devcontainer-validator, interactive-troubleshooter)
- Hooks: 1 (PreToolUse for Docker safety)
- Shared Resources: Templates, data catalogs, language partials

**Used In:**
- ✅ `/README.md` (line 37, 602)
- ✅ `/docs/ARCHITECTURE.md`
- ✅ `/docs/diagrams/README.md` (line 32)

**Sync Status:** ✅ All references valid

---

### 2. Quickstart Setup Flow
**File:** `quickstart-flow.mmd` → `svg/quickstart-flow.svg`
**Type:** Interactive Workflow
**Status:** ✅ Active

**Purpose:** Interactive setup workflow showing the `/quickstart` command process

**Workflow Steps:**
1. User runs `/quickstart`
2. Project type selection (9 options shown in diagram)
3. Network restrictions decision
4. Optional firewall configuration with domain categories
5. DevContainer file generation

**Used In:**
- ✅ README.md (line ~233 - after Slash Commands table)
- ✅ docs/features/SETUP-OPTIONS.md (line ~17 - after Interactive Setup Features table)
- ✅ docs/diagrams/README.md (line 51 - diagram gallery)

**Sync Status:** ✅ Properly embedded in all documented locations

---

### 3. File Generation Process
**File:** `file-generation.mmd` → `svg/file-generation.svg`
**Type:** Data Flow Diagram
**Status:** ✅ Active

**Purpose:** Shows how templates are processed to generate DevContainer files

**Flow:**
- Input: Templates, data catalogs, language partials
- Processing: Copy templates, append partials, replace placeholders, configure firewall
- Output: .devcontainer/ directory with Dockerfile, devcontainer.json, docker-compose.yml, init-firewall.sh

**Used In:**
- ✅ `/docs/ARCHITECTURE.md`
- ✅ `/docs/diagrams/README.md` (line 68)

**Sync Status:** ✅ All references valid

---

### 4. Mode Selection
**File:** `mode-selection.mmd` → `svg/mode-selection.svg`
**Type:** Decision Tree
**Status:** ✅ Active

**Purpose:** Decision tree for selecting the appropriate Docker Compose mode

**Modes Documented:**
- Standard Bind Mount (`docker-compose.yml`) - Linux default, direct file editing
- Volume Mode (`docker-compose.volume.yml`) - Windows/macOS, fast I/O with volume
- Prebuilt Mode (`docker-compose.prebuilt.yml`) - CI/CD with pre-built images
- Profiles Mode (`docker-compose-profiles.yml`) - Backend/frontend service isolation

**Used In:**
- ✅ `/docs/features/SETUP-OPTIONS.md`
- ✅ `/docs/diagrams/README.md` (line 86)

**Sync Status:** ✅ All references valid

---

### 5. Security Layers
**File:** `security-layers.mmd` → `svg/security-layers.svg`
**Type:** Layered Architecture
**Status:** ✅ Active

**Purpose:** Visualizes the 3-layer security model

**Layers:**
- Layer 1: Container Isolation - Namespaces, cgroups, capabilities, read-only filesystem
- Layer 2: Network Isolation - Firewall modes (disabled/strict), iptables + ipset, domain allowlist
- Layer 3: Secret Management - VS Code inputs, Docker secrets, host mounts

**Used In:**
- ✅ `/docs/features/SECURITY-MODEL.md`
- ✅ `/docs/diagrams/README.md` (line 103)

**Sync Status:** ✅ All references valid

---

### 6. Troubleshooting Flow
**File:** `troubleshooting-flow.mmd` → `svg/troubleshooting-flow.svg`
**Type:** Decision Tree
**Status:** ✅ Active

**Purpose:** Decision tree for diagnosing and resolving common sandbox issues

**Categories:**
- Container issues (startup, crashes, build errors)
- Network issues (connectivity, DNS, firewall)
- Service connection problems (PostgreSQL, Redis)
- Firewall blocking
- Permission errors
- VS Code DevContainer issues

**Used In:**
- ✅ `/docs/features/TROUBLESHOOTING.md`
- ✅ `/docs/diagrams/README.md` (line 123)

**Sync Status:** ✅ All references valid

---

### 7. Azure Deployment Flow
**File:** `azure-deployment-flow.mmd` → `svg/azure-deployment-flow.svg`
**Type:** Multi-Step Pipeline
**Status:** ✅ Active

**Purpose:** Multi-step Azure Container Apps deployment pipeline

**Phases:**
1. Pre-flight validation (Docker, DevContainer, Azure CLI)
2. Authentication (interactive or service principal)
3. Configuration (subscription, environment, region, scaling)
4. Infrastructure generation (azure.yaml, Bicep modules)
5. Deployment process (provision, build, push, deploy)
6. Post-deployment verification

**Used In:**
- ✅ `/commands/deploy-to-azure.md`
- ✅ `/docs/features/AZURE-DEPLOYMENT.md`
- ✅ `/docs/diagrams/README.md` (line 143)

**Sync Status:** ✅ All references valid

---

### 8. Secrets Flow
**File:** `secrets-flow.mmd` → `svg/secrets-flow.svg`
**Type:** Decision Tree
**Status:** ✅ Active

**Purpose:** Secret type decision tree and method selection

**Secret Types:**
- Development - VS Code input variables
- Build-time - Docker build secrets (not in layers)
- Runtime Production - Docker runtime secrets (tmpfs)
- Cloud CLI - Host config mounts (read-only)

**Includes:** Secret lifecycle (creation → storage → distribution → usage → rotation → revocation) and anti-patterns to avoid

**Used In:**
- ✅ `/docs/features/SECRETS.md`
- ✅ `/docs/diagrams/README.md` (line 163)

**Sync Status:** ✅ All references valid

---

### 9. Firewall Resolution
**File:** `firewall-resolution.mmd` → `svg/firewall-resolution.svg`
**Type:** Sequence Diagram
**Status:** ✅ Active

**Purpose:** Sequence diagram showing how firewall processes domain allowlists

**Process:**
1. init-firewall.sh reads ALLOWED_DOMAINS
2. DNS resolution (domain → IP addresses)
3. ipset creation (IPs added to hash:net)
4. iptables rule application
5. Verification tests
6. Runtime enforcement

**Used In:**
- ✅ `/docs/features/SECURITY-MODEL.md`
- ✅ `/docs/diagrams/README.md` (line 183)

**Sync Status:** ✅ All references valid

---

### 10. Security Audit Flow
**File:** `security-audit-flow.mmd` → `svg/security-audit-flow.svg`
**Type:** Step-by-Step Process
**Status:** ✅ Active

**Purpose:** 12-step security audit workflow from `/sandboxxer:audit`

**Audit Steps:**
1. Scan configuration files
2. Firewall configuration audit
3. Credentials and secrets audit
4. Port exposure audit
5. Container permissions audit
6. Volume and mount audit
7. Network isolation audit
8. Dependency security
9. Lifecycle hooks security
10. Dev Container features audit
11. Dotfiles security
12. Environment variables security

**Used In:**
- ✅ `/skills/sandboxxer-audit/SKILL.md`
- ✅ `/docs/diagrams/README.md` (line 209)

**Sync Status:** ✅ All references valid

---

### 11. Service Connectivity
**File:** `service-connectivity.mmd` → `svg/service-connectivity.svg`
**Type:** Network Architecture
**Status:** ✅ Active

**Purpose:** Docker network topology and correct/incorrect connection patterns

**Shows:**
- Docker bridge network architecture
- Correct patterns: Using service names (postgres:5432, redis:6379)
- Incorrect patterns: Using localhost or 127.0.0.1
- Docker DNS resolution process
- Common troubleshooting issues

**Used In:**
- ✅ `/docs/features/TROUBLESHOOTING.md`
- ✅ `/docs/diagrams/README.md` (line 228)

**Sync Status:** ✅ All references valid

---

### 12. CI/CD Integration
**File:** `cicd-integration.mmd` → `svg/cicd-integration.svg`
**Type:** Pipeline Sequence
**Status:** ✅ Active

**Purpose:** GitHub Actions / Azure DevOps pipeline sequence

**Pipeline Stages:**
1. Setup: Service principal creation, repository secrets
2. Development: Code push triggers pipeline
3. CI/CD execution: Authentication, provision, build
4. Build & Deploy: Container build, ACR push, deployment
5. Post-deployment: Health checks, smoke tests, rollback
6. Monitoring: Logs and metrics

**Used In:**
- ✅ `/docs/features/AZURE-DEPLOYMENT.md`
- ✅ `/docs/diagrams/README.md` (line 248)

**Sync Status:** ✅ All references valid

---

## ⚠️ Issues Found

### High Priority
1. **Quickstart Flow Diagram** - Claims "Used in: README.md, SETUP-OPTIONS.md" but not actually embedded
   - **Action Required:** Either add embeds or update "Used in" documentation

### Medium Priority
2. **Project Type Count** - Diagram shows 9 types, documentation varies (5-8)
   - **Action Required:** Reconcile project type documentation across all files

---

## 🔧 Maintenance Commands

### Validate Diagram Integrity
```bash
bash scripts/diagram-inventory.sh
```

### Check Version Consistency
```bash
bash scripts/version-checker.sh
```

### Run Full Health Check
```bash
bash scripts/doc-health-check.sh
```

### Regenerate All SVGs
```bash
cd docs/diagrams
for file in *.mmd; do
    npx -y @mermaid-js/mermaid-cli -i "$file" -o "svg/${file%.mmd}.svg" -b transparent
done
```

---

## 📈 Diagram Statistics

| Diagram Type | Count |
|--------------|-------|
| Decision Trees | 4 |
| Workflows/Flows | 3 |
| Architecture | 3 |
| Sequences | 1 |
| Pipelines | 1 |
| **Total** | **12** |

---

## 🎨 Color Coding Standards

All diagrams follow this color scheme:

| Component Type | Color | Hex Code | Usage |
|----------------|-------|----------|-------|
| Commands | Light Green | `#90EE90` | Slash commands |
| Skills | Sky Blue | `#87CEEB` | Workflow skills |
| Agents | Orange | `#FFB366` | Subagents |
| Hooks | Red | `#FF6B6B` | Event hooks |
| Shared Resources | Purple | `#DDA0DD` | Templates/data |
| Decision Points | Peach | `#FFE4B5` | User choices |
| Processing | Light Gray | `#f0f0f0` | Internal processing |

---

## 📝 Next Steps

1. **Immediate:**
   - Fix quickstart-flow.svg embedding in claimed locations
   - Reconcile project type counts across documentation

2. **Short-term:**
   - Add automated tests to verify diagram counts match documentation
   - Enhance diagram-inventory.sh with content validation

3. **Long-term:**
   - Add metadata to .mmd files (YAML frontmatter)
   - Implement bidirectional validation (docs match diagrams)
   - Create automated dashboard regeneration

---

**Last Updated:** 2026-02-07
**Generated By:** ULTRATHINK Enhanced Hybrid Audit Protocol
**Plugin Version:** 4.13.0
