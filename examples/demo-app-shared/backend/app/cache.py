"""
Redis caching utilities for the blogging platform.
"""

import os
import json
import redis

# Redis connection from environment
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")

# Create Redis client
redis_client = redis.from_url(REDIS_URL, decode_responses=True)

# Cache TTL (1 hour)
CACHE_TTL = 3600


def get_post_cache_key(post_id: int) -> str:
    """Generate cache key for post content."""
    return f"post:{post_id}:content"


def get_view_count_key(post_id: int) -> str:
    """Generate key for view counter."""
    return f"post:{post_id}:views"


def cache_post(post_id: int, post_data: dict):
    """Cache post content."""
    key = get_post_cache_key(post_id)
    redis_client.setex(key, CACHE_TTL, json.dumps(post_data))


def get_cached_post(post_id: int) -> dict | None:
    """Get cached post content."""
    key = get_post_cache_key(post_id)
    cached = redis_client.get(key)
    if cached:
        return json.loads(cached)
    return None


def invalidate_post_cache(post_id: int):
    """Invalidate post cache."""
    key = get_post_cache_key(post_id)
    redis_client.delete(key)


def increment_view_count(post_id: int) -> int:
    """Increment and return view count."""
    key = get_view_count_key(post_id)
    return redis_client.incr(key)


def get_view_count(post_id: int) -> int:
    """Get current view count."""
    key = get_view_count_key(post_id)
    count = redis_client.get(key)
    return int(count) if count else 0


def sync_view_count_to_db(post_id: int, count: int):
    """Sync view count from Redis to database (called periodically)."""
    # This would be called by the API when updating view counts
    pass
