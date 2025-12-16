# Release Notes - v1.0.0

## Overview

Initial stable release of Claude Code Sandbox plugin.

## Features

### Interactive Setup Wizard
- **Basic Mode**: Auto-detection with sensible defaults
- **Advanced Mode**: Customization with guided choices
- **Pro Mode**: Step-by-step with detailed education

### Troubleshooting Assistant
- Diagnoses container, network, and service issues
- Provides systematic fix procedures
- Verifies solutions work

### Security Auditor
- Scans configurations for security issues
- Checks firewall, credentials, ports, permissions
- Generates comprehensive security reports

### Templates
- Python (FastAPI + PostgreSQL + Redis)
- Node.js (Express + MongoDB + Redis)
- Fullstack (React + FastAPI + PostgreSQL)

### Security Features
- Strict firewall mode with domain whitelisting
- Permissive mode for development convenience
- Network isolation
- Non-root user configuration

## Installation

```bash
claude plugins add https://github.com/andrewcchoi/windows-sandbox
```

## Quick Start

```bash
cd your-project
claude
/sandbox:setup --basic
```

## Breaking Changes

None (initial release).

## Known Issues

None currently.

## Contributors

- Claude Code Sandbox Team

## What's Next

See CHANGELOG.md [Unreleased] section for planned features.
