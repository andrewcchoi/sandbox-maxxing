"""
FastAPI routes for the blogging platform.
"""

import os
from contextlib import asynccontextmanager
from fastapi import FastAPI, HTTPException, Depends
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel, Field
from sqlalchemy.orm import Session
from typing import List

from app.database import get_db, init_db
from app.models import Post
from app import cache


# Lifespan context manager (replaces deprecated @app.on_event)
@asynccontextmanager
async def lifespan(app: FastAPI):
    """Manage application lifecycle - startup and shutdown tasks."""
    # Startup: Initialize database
    init_db()
    yield
    # Shutdown: Cleanup tasks (if needed)


app = FastAPI(title="Blogging Platform API", version="1.0.0", lifespan=lifespan)

# CORS middleware - configure allowed origins via environment variable
# SECURITY: Never use allow_origins=["*"] with allow_credentials=True in production
ALLOWED_ORIGINS = os.getenv("CORS_ALLOWED_ORIGINS", "http://localhost:5173,http://localhost:3000").split(",")

app.add_middleware(
    CORSMiddleware,
    allow_origins=ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


# Pydantic models for request/response
class PostCreate(BaseModel):
    title: str = Field(..., min_length=1, max_length=255, description="Post title")
    content: str = Field(..., min_length=1, max_length=50000, description="Post content")
    author: str = Field(..., min_length=1, max_length=100, description="Post author name")


class PostUpdate(BaseModel):
    title: str | None = Field(None, min_length=1, max_length=255, description="Post title")
    content: str | None = Field(None, min_length=1, max_length=50000, description="Post content")
    author: str | None = Field(None, min_length=1, max_length=100, description="Post author name")


class PostResponse(BaseModel):
    id: int
    title: str
    content: str
    author: str
    view_count: int
    created_at: str
    updated_at: str

    class Config:
        from_attributes = True


@app.get("/")
def read_root():
    """Health check endpoint."""
    return {"status": "ok", "message": "Blogging Platform API"}


@app.get("/posts", response_model=List[PostResponse])
def list_posts(skip: int = 0, limit: int = 100, db: Session = Depends(get_db)):
    """List all posts."""
    posts = db.query(Post).order_by(Post.created_at.desc()).offset(skip).limit(limit).all()
    return [post.to_dict() for post in posts]


@app.post("/posts", response_model=PostResponse, status_code=201)
def create_post(post: PostCreate, db: Session = Depends(get_db)):
    """Create a new post."""
    db_post = Post(
        title=post.title,
        content=post.content,
        author=post.author,
    )
    db.add(db_post)
    try:
        db.commit()
        db.refresh(db_post)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    # Cache the post
    cache.cache_post(db_post.id, db_post.to_dict())

    return db_post.to_dict()


@app.get("/posts/{post_id}", response_model=PostResponse)
def read_post(post_id: int, db: Session = Depends(get_db)):
    """Get a specific post and increment view count."""
    # Try cache first
    cached = cache.get_cached_post(post_id)
    if cached:
        # Increment view count in Redis
        views = cache.increment_view_count(post_id)
        cached["view_count"] = views
        return cached

    # Not in cache, get from database
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    # Increment view count
    views = cache.increment_view_count(post_id)
    post.view_count = views
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        # Non-critical error - continue without persisting view count to DB
        pass

    # Cache the post
    post_dict = post.to_dict()
    cache.cache_post(post_id, post_dict)

    return post_dict


@app.put("/posts/{post_id}", response_model=PostResponse)
def update_post(post_id: int, post_update: PostUpdate, db: Session = Depends(get_db)):
    """Update a post."""
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    # Update fields
    if post_update.title is not None:
        post.title = post_update.title
    if post_update.content is not None:
        post.content = post_update.content
    if post_update.author is not None:
        post.author = post_update.author

    try:
        db.commit()
        db.refresh(post)
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    # Invalidate cache
    cache.invalidate_post_cache(post_id)

    return post.to_dict()


@app.delete("/posts/{post_id}", status_code=204)
def delete_post(post_id: int, db: Session = Depends(get_db)):
    """Delete a post."""
    post = db.query(Post).filter(Post.id == post_id).first()
    if not post:
        raise HTTPException(status_code=404, detail="Post not found")

    db.delete(post)
    try:
        db.commit()
    except Exception as e:
        db.rollback()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")

    # Invalidate cache
    cache.invalidate_post_cache(post_id)

    return None
