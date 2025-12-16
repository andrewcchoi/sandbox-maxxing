# Basic Streamlit Demo

## Purpose

Quick visual validation that your Claude Code sandbox is working correctly. Tests connectivity to PostgreSQL and Redis services in under 30 seconds.

## What It Demonstrates

- ✅ PostgreSQL connection using service name (`postgres:5432`)
- ✅ Redis connection using service name (`redis:6379`)
- ✅ Environment variables from devcontainer.json
- ✅ Simple UI for manual validation

## How to Run

### Inside the DevContainer

1. Install dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run the app:
   ```bash
   streamlit run app.py
   ```

3. Open your browser to the URL shown (typically `http://localhost:8501`)

4. Click the test buttons to verify connections

## What Success Looks Like

- Both "Test PostgreSQL" and "Test Redis" buttons show ✅ green checkmarks
- PostgreSQL displays version information
- Redis successfully sets and retrieves a test key

## Troubleshooting

**"Connection failed" errors:**
1. Ensure Docker services are running: `docker compose ps`
2. Check services are healthy: `docker compose ps` (look for "healthy" status)
3. Restart services: `docker compose restart postgres redis`

**Port already in use:**
- Streamlit default port is 8501
- Change with: `streamlit run app.py --server.port 8502`

## Next Steps

Once both tests pass:
- ✨ Your sandbox setup is working!
- 📚 Explore the full demo apps:
  - Shared: `examples/demo-app-shared/`
  - Basic mode: `examples/demo-app-sandbox-basic/`
  - Advanced mode: `examples/demo-app-sandbox-advanced/`
  - Pro mode: `examples/demo-app-sandbox-pro/`
- 📖 Read the development guide: `docs/DEVELOPMENT.md`
