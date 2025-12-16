# Plugin Testing Guide

## Overview

This directory contains manual test cases for the Claude Code Sandbox plugin.

## Test Structure

Each test file follows this format:
1. **Setup** - Prerequisites and initial state
2. **Test Steps** - Step-by-step actions
3. **Expected Results** - What should happen
4. **Cleanup** - How to reset state

## Running Tests

Execute tests in order:
1. `test-setup-basic.md` - Basic mode setup wizard
2. `test-setup-advanced.md` - Advanced mode customization
3. `test-setup-yolo.md` - YOLO mode with full guidance
4. `test-troubleshoot.md` - Troubleshooting assistant
5. `test-security.md` - Security auditor

## Test Environment

- Fresh directory for each test
- Docker Desktop running
- VS Code with DevContainers extension
- Claude Code CLI installed
