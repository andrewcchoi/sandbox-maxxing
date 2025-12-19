# Security Policy

## Supported Versions

We currently support the following versions with security updates:

| Version | Supported          |
| ------- | ------------------ |
| 2.2.x   | :white_check_mark: |
| 2.1.x   | :white_check_mark: |
| 2.0.x   | :white_check_mark: |
| < 2.0   | :x:                |

## Reporting a Vulnerability

We take security vulnerabilities seriously. If you discover a security issue in the Claude Code Sandbox Plugin, please report it responsibly.

### Reporting Process

1. **Do NOT** create a public GitHub issue for security vulnerabilities
2. **Do NOT** share the vulnerability publicly until it has been addressed

Instead, please report security issues through one of these channels:

#### Preferred: GitHub Security Advisory

1. Go to the [Security tab](https://github.com/andrewcchoi/sandbox-maxxing/security)
2. Click "Report a vulnerability"
3. Fill out the security advisory form with:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)

#### Alternative: Email

If you cannot use GitHub Security Advisories, email the maintainer directly:
- Email: [Provide your security contact email or use GitHub private vulnerability reporting]
- Subject: "[SECURITY] Description of Issue"

### What to Include

When reporting a vulnerability, please include:

1. **Description**: Clear description of the vulnerability
2. **Impact**: What could an attacker do with this vulnerability?
3. **Reproduction**: Step-by-step instructions to reproduce
4. **Environment**:
   - Plugin version
   - Operating system
   - Docker version
   - Claude Code version
5. **Proof of Concept**: Code or commands that demonstrate the issue (if applicable)
6. **Suggested Fix**: If you have ideas on how to fix it (optional)

### What to Expect

After reporting a vulnerability:

1. **Acknowledgment**: Within 48 hours, we'll acknowledge receipt
2. **Assessment**: Within 7 days, we'll provide an initial assessment
3. **Updates**: We'll keep you informed as we work on a fix
4. **Resolution**: We aim to fix critical vulnerabilities within 30 days
5. **Disclosure**: Once fixed, we'll coordinate disclosure with you

### Security Update Process

When a security vulnerability is fixed:

1. We'll release a patch version (e.g., 2.2.1)
2. We'll publish a security advisory on GitHub
3. We'll update the CHANGELOG with security fix details
4. We'll credit the reporter (unless they prefer to remain anonymous)

## Security Best Practices

When using the Claude Code Sandbox Plugin, follow these security best practices:

### 1. Mode Selection

Choose the appropriate security mode for your use case:

- **Basic Mode**: Use only for trusted code and quick prototyping
- **Intermediate Mode**: Use for general development with no sensitive data
- **Advanced Mode**: Use for production-like environments and sensitive work
- **YOLO Mode**: Use only if you understand the security implications

See [docs/features/security-model.md](docs/features/security-model.md) for detailed security model documentation.

### 2. Firewall Configuration

- Use **strict firewall mode** (Advanced/YOLO) when working with untrusted code
- Regularly review and update allowed domain lists
- Never disable firewall for production-like environments
- Test firewall rules after making changes

### 3. Secrets Management

- **Never** hardcode secrets in Dockerfiles or docker-compose files
- Use VS Code inputs for development credentials
- Use Docker secrets for production deployments
- Use build secrets for private registry authentication
- Read-only mount cloud CLI credentials when possible

See [docs/features/SECRETS.md](docs/features/SECRETS.md) for comprehensive secrets management guide.

### 4. Container Security

- Run containers as non-root user (default in all modes)
- Keep base images updated (`docker pull` regularly)
- Scan images for vulnerabilities (`docker scan` or `trivy`)
- Minimize installed packages (use appropriate mode)
- Drop unnecessary Linux capabilities

### 5. Network Security

- Isolate containers on dedicated networks
- Don't expose unnecessary ports to host
- Use Docker's internal networking (not localhost)
- Regularly audit network connectivity

### 6. Regular Updates

- Keep the plugin updated: `claude plugins update`
- Update base images regularly
- Monitor security advisories for dependencies
- Review and update firewall allowlists

## Known Security Considerations

### Container Isolation

**What it protects against:**
- Accidental host modification
- Process isolation
- Filesystem isolation

**What it does NOT protect against:**
- Kernel exploits (use VMs for high-security scenarios)
- Determined attackers with container escape exploits
- Network-based attacks (without firewall)

### Network Firewall

**Basic/Intermediate modes:**
- No firewall restrictions
- Relies solely on container isolation
- Suitable for trusted code only

**Advanced/YOLO strict modes:**
- Whitelist-based firewall
- Prevents unauthorized network access
- Protects against malicious dependencies
- Requires manual domain additions

### Threat Model

See [docs/features/security-model.md](docs/features/security-model.md) for comprehensive threat model documentation.

## Scope

### In Scope

Security vulnerabilities in:
- Plugin code and skill implementations
- Template generation logic
- Firewall configuration
- Secrets handling
- Docker configuration generation
- Command injection vectors
- Path traversal issues
- Arbitrary code execution in plugin

### Out of Scope

The following are not considered security vulnerabilities:

- Issues in upstream dependencies (report to upstream)
- Docker daemon vulnerabilities (report to Docker)
- Kernel vulnerabilities (report to kernel maintainers)
- VS Code vulnerabilities (report to Microsoft)
- User misconfiguration of generated configs
- Container escape exploits in Docker itself
- Network security of allowed domains

## Security Research

We welcome security research on the Claude Code Sandbox Plugin. When conducting security research:

1. **Respect user privacy**: Don't attempt to access other users' data
2. **Test responsibly**: Use your own test environments
3. **Report findings**: Follow responsible disclosure
4. **Don't cause harm**: Don't delete data or disrupt services

### Allowed Research Activities

- Testing plugin code for vulnerabilities
- Analyzing template generation for security issues
- Testing firewall bypass techniques
- Analyzing secrets handling
- Testing command injection vectors

### Not Allowed

- Attacking other users or their environments
- Disrupting plugin infrastructure
- Attempting to access private data
- Automated vulnerability scanning without permission

## Hall of Fame

We'll recognize security researchers who responsibly disclose vulnerabilities:

<!-- Security researchers will be listed here after responsible disclosure -->

*No vulnerabilities have been reported yet.*

## Questions?

For security-related questions that are not vulnerabilities:

1. Check [docs/features/security-model.md](docs/features/security-model.md) for security architecture
2. Use [GitHub Discussions](https://github.com/andrewcchoi/sandbox-maxxing/discussions) for public questions
3. Open a regular GitHub issue for feature requests

---

**Last Updated:** 2025-12-16
**Version:** 3.0.0
