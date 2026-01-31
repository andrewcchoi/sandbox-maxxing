"""
Redis caching utilities for the blogging platform.
"""

import os
import json
import redis
import logging

logger = logging.getLogger(__name__)

# Redis connection from environment
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")

# Cache TTL (1 hour)
CACHE_TTL = 3600

# Create Redis client with error handling
try:
    redis_client = redis.from_url(REDIS_URL, decode_responses=True, socket_connect_timeout=5)
    redis_client.ping()  # Test connection
    logger.info("Redis connection established")
except (redis.ConnectionError, redis.TimeoutError) as e:
    logger.warning(f"Redis connection failed: {e}. Cache operations will be disabled.")
    redis_client = None


def get_post_cache_key(post_id: int) -> str:
    """Generate cache key for post content."""
    return f"post:{post_id}:content"


def get_view_count_key(post_id: int) -> str:
    """Generate key for view counter."""
    return f"post:{post_id}:views"


def cache_post(post_id: int, post_data: dict):
    """Cache post content with error handling."""
    if redis_client is None:
        return  # Silently skip caching if Redis unavailable
    try:
        key = get_post_cache_key(post_id)
        redis_client.setex(key, CACHE_TTL, json.dumps(post_data))
    except (redis.ConnectionError, redis.TimeoutError) as e:
        logger.warning(f"Failed to cache post {post_id}: {e}")


def get_cached_post(post_id: int) -> dict | None:
    """Get cached post content with error handling."""
    if redis_client is None:
        return None  # Cache miss if Redis unavailable
    try:
        key = get_post_cache_key(post_id)
        cached = redis_client.get(key)
        if cached:
            return json.loads(cached)
    except (redis.ConnectionError, redis.TimeoutError, json.JSONDecodeError) as e:
        logger.warning(f"Failed to get cached post {post_id}: {e}")
    return None


def invalidate_post_cache(post_id: int):
    """Invalidate post cache with error handling."""
    if redis_client is None:
        return  # Silently skip if Redis unavailable
    try:
        key = get_post_cache_key(post_id)
        redis_client.delete(key)
    except (redis.ConnectionError, redis.TimeoutError) as e:
        logger.warning(f"Failed to invalidate cache for post {post_id}: {e}")


def increment_view_count(post_id: int) -> int:
    """Increment and return view count with error handling."""
    if redis_client is None:
        return 0  # Return 0 if Redis unavailable
    try:
        key = get_view_count_key(post_id)
        return redis_client.incr(key)
    except (redis.ConnectionError, redis.TimeoutError) as e:
        logger.warning(f"Failed to increment view count for post {post_id}: {e}")
        return 0


def get_view_count(post_id: int) -> int:
    """Get current view count with error handling."""
    if redis_client is None:
        return 0  # Return 0 if Redis unavailable
    try:
        key = get_view_count_key(post_id)
        count = redis_client.get(key)
        return int(count) if count else 0
    except (redis.ConnectionError, redis.TimeoutError, ValueError) as e:
        logger.warning(f"Failed to get view count for post {post_id}: {e}")
        return 0


def sync_view_count_to_db(post_id: int, count: int):
    """Sync view count from Redis to database (called periodically)."""
    # This would be called by the API when updating view counts
    pass
