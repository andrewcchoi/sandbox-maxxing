# Demo Blog Application - Shared Components

This directory contains the **shared application code** for the full-stack demo blog application used across multiple sandbox examples. It demonstrates realistic development patterns and validates sandbox connectivity.

## Purpose

Provides reusable backend and frontend implementations that:
- Demonstrate realistic full-stack development patterns
- Validate sandbox connectivity (PostgreSQL, Redis)
- Support testing across different sandbox configurations
- Serve as a reference implementation for full-stack projects

## Structure

```
demo-app-shared/
├── backend/                    # Python FastAPI backend
│   ├── app/
│   │   ├── __init__.py
│   │   ├── api.py             # FastAPI routes
│   │   ├── models.py          # SQLAlchemy models
│   │   ├── database.py        # Database connection
│   │   └── cache.py           # Redis caching utilities
│   ├── alembic/               # Database migrations
│   ├── tests/
│   │   ├── test_api.py        # API endpoint tests
│   │   └── test_cache.py      # Cache functionality tests
│   ├── requirements.txt
│   ├── pytest.ini
│   └── run.sh
├── frontend/                   # React + Vite frontend
│   ├── src/
│   │   ├── components/        # React components
│   │   ├── App.jsx
│   │   └── main.jsx
│   ├── public/
│   ├── package.json
│   ├── vite.config.js
│   ├── jest.config.js
│   └── run.sh
├── run-tests.sh               # Run all tests (bash)
└── run-tests.ps1              # Run all tests (PowerShell)
```

## Backend (FastAPI)

### Tech Stack
- **FastAPI** 0.109.0 - Modern Python web framework
- **SQLAlchemy** 2.0.25 - Database ORM
- **PostgreSQL** - Primary database
- **Redis** 5.0.1 - Caching and session storage
- **Alembic** 1.13.1 - Database migrations
- **pytest** 7.4.4 - Testing framework

### Features
- RESTful API for blog posts (CRUD operations)
- PostgreSQL database with SQLAlchemy ORM
- Redis caching for view counts and post content
- Comprehensive pytest test suite
- Database migrations with Alembic

### Running the Backend

```bash
cd backend
pip install -r requirements.txt  # or: uv pip install -r requirements.txt
uvicorn app.api:app --host 0.0.0.0 --port 8000 --reload
```

### API Endpoints
- `GET /posts` - List all posts
- `POST /posts` - Create a new post
- `GET /posts/{id}` - Get a specific post (increments view count)
- `PUT /posts/{id}` - Update a post
- `DELETE /posts/{id}` - Delete a post
- `GET /health` - Health check endpoint
- `GET /docs` - OpenAPI documentation (Swagger UI)

## Frontend (React + Vite)

### Tech Stack
- **React** 18.2.0 - UI framework
- **Vite** 5.0.11 - Build tool and dev server
- **axios** 1.6.5 - HTTP client
- **Jest** 29.7.0 - Testing framework
- **React Testing Library** 14.1.2 - Component testing

### Features
- Modern React SPA with hooks
- Blog post management (create, read, update, delete)
- Real-time view counter with Redis caching
- Component tests with React Testing Library
- Hot module replacement for development

### Running the Frontend

```bash
cd frontend
npm install
npm run dev
```

### Available Scripts
- `npm run dev` - Start development server (port 5173)
- `npm run build` - Production build
- `npm run preview` - Preview production build
- `npm test` - Run Jest tests

## Running Tests

### All Tests (Backend + Frontend)

```bash
# Bash
./run-tests.sh

# PowerShell
./run-tests.ps1

# With coverage
./run-tests.sh --coverage
```

### Backend Tests Only

```bash
cd backend
pytest
pytest --cov=app  # with coverage
```

### Frontend Tests Only

```bash
cd frontend
npm test
npm test -- --coverage  # with coverage
```

## Configuration

### Environment Variables

The application expects these environment variables (provided by DevContainer):

| Variable | Default | Description |
|----------|---------|-------------|
| `POSTGRES_HOST` | `postgres` | Database hostname |
| `POSTGRES_PORT` | `5432` | Database port |
| `POSTGRES_USER` | `sandbox_user` | Database username |
| `POSTGRES_PASSWORD` | `devpassword` | Database password |
| `POSTGRES_DB` | `sandbox_dev` | Database name |
| `REDIS_HOST` | `redis` | Redis hostname |
| `REDIS_PORT` | `6379` | Redis port |

### Database Connection

The backend uses this connection string:
```python
DATABASE_URL = f"postgresql://{POSTGRES_USER}:{POSTGRES_PASSWORD}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}"
```

## Usage with Sandbox Examples

This shared code is copied into the sandbox examples:

- [demo-app-sandbox-basic](../demo-app-sandbox-basic/README.md) - Minimal configuration
- [demo-app-sandbox-advanced](../demo-app-sandbox-advanced/README.md) - Domain allowlist configuration
- [demo-app-sandbox-yolo](../demo-app-sandbox-yolo/README.md) - Custom configuration

Each sandbox example adds its own DevContainer configuration while reusing this application code.

## Development Notes

- **Backend runs on port 8000** - Access at `http://localhost:8000`
- **Frontend runs on port 5173** - Access at `http://localhost:5173`
- **API docs available** at `http://localhost:8000/docs` (Swagger UI)
- **Database migrations** managed via Alembic in `backend/alembic/`
- **Redis cache** automatically used for post views and content

## See Also

- [Examples Overview](../README.md)
- [Demo App Basic](../demo-app-sandbox-basic/README.md)
- [Demo App Advanced](../demo-app-sandbox-advanced/README.md)
- [Demo App YOLO](../demo-app-sandbox-yolo/README.md)

---

**Last Updated:** 2026-01-02
**Version:** 4.6.0
