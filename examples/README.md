# Examples

Two example applications demonstrating the Claude Code Sandbox plugin's capabilities.

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
