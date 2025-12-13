"""
Tests for the blogging platform API.
"""

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.api import app
from app.models import Base
from app.database import get_db

# Test database URL
TEST_DATABASE_URL = "sqlite:///./test.db"

# Create test engine and session
engine = create_engine(TEST_DATABASE_URL, connect_args={"check_same_thread": False})
TestingSessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)


def override_get_db():
    """Override database dependency for testing."""
    db = TestingSessionLocal()
    try:
        yield db
    finally:
        db.close()


# Override the dependency
app.dependency_overrides[get_db] = override_get_db

# Create test client
client = TestClient(app)


@pytest.fixture(autouse=True)
def setup_database():
    """Setup and teardown test database."""
    Base.metadata.create_all(bind=engine)
    yield
    Base.metadata.drop_all(bind=engine)


def test_read_root():
    """Test the root endpoint."""
    response = client.get("/")
    assert response.status_code == 200
    assert response.json()["status"] == "ok"


def test_list_posts_empty():
    """Test listing posts when there are none."""
    response = client.get("/posts")
    assert response.status_code == 200
    assert response.json() == []


def test_create_post():
    """Test creating a new post."""
    post_data = {
        "title": "Test Post",
        "content": "This is a test post content.",
        "author": "Test Author"
    }
    response = client.post("/posts", json=post_data)
    assert response.status_code == 201
    data = response.json()
    assert data["title"] == post_data["title"]
    assert data["content"] == post_data["content"]
    assert data["author"] == post_data["author"]
    assert "id" in data
    assert data["view_count"] == 0


def test_read_post():
    """Test reading a specific post."""
    # Create a post first
    post_data = {
        "title": "Test Post",
        "content": "Content here",
        "author": "Author"
    }
    create_response = client.post("/posts", json=post_data)
    post_id = create_response.json()["id"]

    # Read the post
    response = client.get(f"/posts/{post_id}")
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == post_data["title"]
    assert data["id"] == post_id


def test_read_nonexistent_post():
    """Test reading a post that doesn't exist."""
    response = client.get("/posts/99999")
    assert response.status_code == 404


def test_update_post():
    """Test updating a post."""
    # Create a post
    post_data = {
        "title": "Original Title",
        "content": "Original content",
        "author": "Original Author"
    }
    create_response = client.post("/posts", json=post_data)
    post_id = create_response.json()["id"]

    # Update the post
    update_data = {
        "title": "Updated Title",
        "content": "Updated content"
    }
    response = client.put(f"/posts/{post_id}", json=update_data)
    assert response.status_code == 200
    data = response.json()
    assert data["title"] == "Updated Title"
    assert data["content"] == "Updated content"
    assert data["author"] == "Original Author"  # Unchanged


def test_delete_post():
    """Test deleting a post."""
    # Create a post
    post_data = {
        "title": "To be deleted",
        "content": "This will be deleted",
        "author": "Author"
    }
    create_response = client.post("/posts", json=post_data)
    post_id = create_response.json()["id"]

    # Delete the post
    response = client.delete(f"/posts/{post_id}")
    assert response.status_code == 204

    # Verify it's gone
    get_response = client.get(f"/posts/{post_id}")
    assert get_response.status_code == 404


def test_list_multiple_posts():
    """Test listing multiple posts."""
    # Create multiple posts
    for i in range(3):
        post_data = {
            "title": f"Post {i}",
            "content": f"Content {i}",
            "author": f"Author {i}"
        }
        client.post("/posts", json=post_data)

    # List all posts
    response = client.get("/posts")
    assert response.status_code == 200
    data = response.json()
    assert len(data) == 3
