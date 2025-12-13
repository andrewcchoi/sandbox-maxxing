"""
Basic Streamlit App - Claude Code Sandbox Plugin Demo
Shows PostgreSQL and Redis connectivity in the devcontainer.
"""

import streamlit as st
import psycopg2
import redis
import os

# Configuration
DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://sandbox_user:devpassword@postgres:5432/sandbox_dev")
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
