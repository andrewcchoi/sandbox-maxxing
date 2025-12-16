"""
Tests for Redis caching functionality.
"""

import pytest
from app import cache


def test_cache_key_generation():
    """Test cache key generation."""
    post_id = 123
    content_key = cache.get_post_cache_key(post_id)
    view_key = cache.get_view_count_key(post_id)

    assert content_key == "post:123:content"
    assert view_key == "post:123:views"


def test_cache_and_retrieve_post():
    """Test caching and retrieving post data."""
    post_id = 1
    post_data = {
        "id": post_id,
        "title": "Test Post",
        "content": "Test content",
        "author": "Test Author",
        "view_count": 0
    }

    # Cache the post
    cache.cache_post(post_id, post_data)

    # Retrieve from cache
    cached_data = cache.get_cached_post(post_id)
    assert cached_data is not None
    assert cached_data["title"] == "Test Post"
    assert cached_data["content"] == "Test content"


def test_invalidate_cache():
    """Test cache invalidation."""
    post_id = 2
    post_data = {"id": post_id, "title": "Test"}

    # Cache the post
    cache.cache_post(post_id, post_data)
    assert cache.get_cached_post(post_id) is not None

    # Invalidate cache
    cache.invalidate_post_cache(post_id)
    assert cache.get_cached_post(post_id) is None


def test_increment_view_count():
    """Test view count increment."""
    post_id = 3

    # First increment
    count1 = cache.increment_view_count(post_id)
    assert count1 == 1

    # Second increment
    count2 = cache.increment_view_count(post_id)
    assert count2 == 2

    # Get current count
    current = cache.get_view_count(post_id)
    assert current == 2


def test_get_view_count_nonexistent():
    """Test getting view count for nonexistent post."""
    count = cache.get_view_count(99999)
    assert count == 0
