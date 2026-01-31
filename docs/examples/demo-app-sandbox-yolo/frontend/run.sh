#!/usr/bin/env bash
# Start the React frontend development server
set -euo pipefail

cd "$(dirname "$0")"

echo "Starting React frontend with Vite..."
npm run dev
