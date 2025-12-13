#!/bin/bash
# Start the FastAPI backend server

cd "$(dirname "$0")"

echo "Starting FastAPI backend..."
uvicorn app.api:app --host 0.0.0.0 --port 8000 --reload
