"""
Basic Streamlit App - Claude Code Sandbox Plugin Demo
Shows PostgreSQL and Redis connectivity in the devcontainer.
"""

import streamlit as st
import psycopg2
import redis
import os
from urllib.parse import quote

# Configuration - Build DATABASE_URL from individual env vars (allows override of each component)
POSTGRES_USER = os.getenv("POSTGRES_USER", "sandbox_user")
POSTGRES_PASSWORD = os.getenv("POSTGRES_PASSWORD", "devpassword")
POSTGRES_HOST = os.getenv("POSTGRES_HOST", "postgres")
POSTGRES_PORT = os.getenv("POSTGRES_PORT", "5432")
POSTGRES_DB = os.getenv("POSTGRES_DB", "sandbox_dev")
# URL-encode credentials to prevent injection attacks from special characters (@, :, /, etc.)
DATABASE_URL = os.getenv("DATABASE_URL", f"postgresql://{quote(POSTGRES_USER, safe='')}:{quote(POSTGRES_PASSWORD, safe='')}@{POSTGRES_HOST}:{POSTGRES_PORT}/{POSTGRES_DB}")
REDIS_URL = os.getenv("REDIS_URL", "redis://redis:6379")

st.title("🚀 Claude Code Sandbox - Connection Test")
st.markdown("**Quick validation that your devcontainer setup works!**")

st.divider()

# PostgreSQL Connection Test
st.subheader("PostgreSQL Connection")

if st.button("Test PostgreSQL"):
    try:
        conn = psycopg2.connect(DATABASE_URL)
        cursor = conn.cursor()
        cursor.execute("SELECT version();")
        version = cursor.fetchone()[0]
        cursor.close()
        conn.close()
        st.success(f"✅ Connected successfully!")
        st.code(version, language="text")
    except Exception as e:
        st.error(f"❌ Connection failed: {str(e)}")

st.divider()

# Redis Connection Test
st.subheader("Redis Connection")

if st.button("Test Redis"):
    try:
        r = redis.from_url(REDIS_URL)
        r.set("test_key", "Hello from Streamlit!")
        value = r.get("test_key").decode("utf-8")
        r.delete("test_key")
        st.success(f"✅ Connected successfully!")
        st.code(f"Set and retrieved: {value}", language="text")
    except Exception as e:
        st.error(f"❌ Connection failed: {str(e)}")

st.divider()

# Success Message
st.info("""
**✨ Next Steps:**
1. If both tests pass, your sandbox is working!
2. Explore the full demo app at `examples/demo-app/`
3. See `docs/DEVELOPMENT.md` for more information
""")
