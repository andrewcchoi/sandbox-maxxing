#!/bin/bash
# ============================================================================
# Frontend Setup Script - npm Platform Detection
# ============================================================================
# Detects Windows-specific node_modules and reinstalls for Linux
# Issue #107: Fixes esbuild platform mismatch errors when switching between
# Windows host and WSL2/Docker Linux container
# ============================================================================

set -e

echo "[Frontend Setup] Checking for platform-specific node_modules..."

# Check if node_modules exists
if [ ! -d "node_modules" ]; then
  echo "[Frontend Setup] No node_modules found, skipping platform detection"
  exit 0
fi

# Check for Windows-specific esbuild binaries
if [ -d "node_modules/@esbuild/win32-x64" ] || [ -d "node_modules/@esbuild/win32-arm64" ]; then
  echo "[Frontend Setup] ⚠️  Detected Windows node_modules!"
  echo "[Frontend Setup] Windows-specific binaries found (esbuild)"
  echo "[Frontend Setup] Removing node_modules and package-lock.json..."

  rm -rf node_modules package-lock.json

  echo "[Frontend Setup] Reinstalling dependencies for Linux..."
  npm install

  echo "[Frontend Setup] ✓ npm dependencies reinstalled for Linux platform"
else
  echo "[Frontend Setup] ✓ node_modules already compatible with Linux"
fi

exit 0
