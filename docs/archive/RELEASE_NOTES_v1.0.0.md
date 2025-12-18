# Release Notes - v1.0.0

## Overview

Initial stable release of Claude Code Sandbox plugin.

## Features

### Interactive Setup Wizard
- **Basic Mode**: Auto-detection with sensible defaults
- **Intermediate Mode**: Balanced control and convenience
- **Advanced Mode**: Customization with guided choices
- **YOLO Mode**: Step-by-step with full control

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
claude plugins add https://github.com/andrewcchoi/sandbox-maxxing
```

## Quick Start

```bash
cd your-project
claude
/sandbox:basic
```

## Breaking Changes

None (initial release).

## Known Issues

None currently.

## Contributors

- Sandbox Team

## What's Next

See CHANGELOG.md [Unreleased] section for planned features.
