# Examples

Two example applications demonstrating the Claude Code Sandbox plugin's capabilities.

## Prerequisites

The examples require PostgreSQL and Redis services. Start them using the provided docker-compose file:

```bash
# From the examples/ directory
cd examples
docker compose up -d

# Verify services are running
docker compose ps

# View logs if needed
docker compose logs postgres
docker compose logs redis

# Stop services when done
docker compose down
```

**Service URLs:**
- PostgreSQL: `postgresql://sandbox_user:devpassword@localhost:5432/sandbox_dev`
- Redis: `redis://localhost:6379`

## Learning Path

### 1. Start Here: Basic Streamlit Demo

**Location:** `basic-streamlit/`

**Purpose:** Quick 30-second validation that your sandbox works.

**What it shows:**
- PostgreSQL connection test
- Redis connection test
- Visual success/failure indicators

**Run:**
```bash
pip install -r basic-streamlit/requirements.txt
streamlit run basic-streamlit/app.py
```

### 2. Full Demo: Blogging Platform

**Location:** `demo-app/`

**Purpose:** Production-ready patterns and architecture.

**What it shows:**
- FastAPI backend with async SQLAlchemy
- React frontend with Vite
- PostgreSQL persistence
- Redis caching and counters
- Full CRUD operations
- Comprehensive tests

**Run Backend:**
```bash
cd demo-app/backend
pip install -r requirements.txt
./run.sh
```

**Run Frontend:**
```bash
cd demo-app/frontend
npm install
./run.sh
```

## Architecture

```
examples/
├── basic-streamlit/          # Quick validation
│   ├── app.py                # Streamlit app (~50 lines)
│   ├── requirements.txt
│   └── README.md
│
└── demo-app/                 # Full-stack demo
    ├── backend/              # FastAPI + PostgreSQL + Redis
    │   ├── app/
    │   │   ├── models.py     # SQLAlchemy models
    │   │   ├── api.py        # FastAPI routes
    │   │   ├── cache.py      # Redis caching
    │   │   └── database.py   # DB connection
    │   ├── tests/            # pytest tests
    │   └── requirements.txt
    │
    └── frontend/             # React + Vite
        ├── src/
        │   ├── components/   # React components
        │   ├── api/          # API client
        │   └── App.jsx       # Main app
        └── package.json
```

## Next Steps

- ✅ Run basic example to verify setup
- ✅ Explore full demo for production patterns
- 📖 Read `docs/DEVELOPMENT.md` for contribution guidelines
- 🔒 Check `docs/SECURITY.md` for security best practices

## About

**Note**: I am not actively accepting pull requests or feature requests for this project. However, you are more than welcome to fork this repository and make your own improvements!

This project was created with [Claude](https://claude.ai) using the [Superpowers](https://github.com/obra/superpowers) plugin.
