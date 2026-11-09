# Service Connectivity

Connecting to databases, Redis, RabbitMQ, and other services in Docker networks.

**See also:** [Main Troubleshooting Guide](../TROUBLESHOOTING.md) | [Network Issues](network.md) | [Container Issues](container.md)

---

![Service Connectivity](../../diagrams/svg/service-connectivity.svg)

*Docker network topology showing correct and incorrect connection patterns. Use service names (postgres:5432, redis:6379) not localhost.*

## Can't Connect to PostgreSQL/Redis/RabbitMQ

**Symptoms:**
- Connection refused
- Connection timeout
- "Could not connect to server"

**Diagnostic Commands:**
```bash
# Check service status
docker compose ps

# Check service logs
docker compose logs postgres
docker compose logs redis

# Test connectivity (inside container)
nc -zv postgres 5432
nc -zv redis 6379

# Check networks
docker inspect <container-name> | grep Networks -A 5
```

**Common Mistakes:**

❌ **Using localhost:**
```python
# WRONG
DATABASE_URL = "postgresql://user:pass@localhost:5432/db"
```

✅ **Using service name:**
```python
# CORRECT
DATABASE_URL = "postgresql://user:pass@postgres:5432/db"
```

**Solutions:**

**1. Verify Service is Running:**
```bash
docker compose ps

# Look for "Up" and "healthy" status
# Example output:
# postgres   Up (healthy)
# redis      Up (healthy)
```

**2. Check Service Logs:**
```bash
docker compose logs postgres
# Look for startup errors or crashes
```

**3. Use Service Name in Connection Strings:**

Update your application configuration:
```bash
# PostgreSQL
POSTGRES_HOST=postgres  # NOT localhost

# Redis
REDIS_HOST=redis  # NOT localhost

# RabbitMQ
RABBITMQ_HOST=rabbitmq  # NOT localhost
```

**4. Verify Same Network:**
```bash
# Check both containers are on same network
docker network inspect <network-name>

# Should show both app and service containers
```

**5. Test Health Check:**
```bash
# PostgreSQL
docker exec -it <postgres-container> pg_isready -U sandbox_user

# Redis
docker exec -it <redis-container> redis-cli ping
```

---

## Service Shows "Unhealthy"

**Symptoms:**
```bash
docker compose ps
# Shows: postgres   Up (unhealthy)
```

**Diagnostic Commands:**
```bash
# Check health check configuration
docker compose config | grep -A 10 healthcheck

# View health check logs
docker inspect <container-name> | grep -A 20 Health
```

**Solutions:**

**1. Increase Health Check Timeouts:**

Edit `docker-compose.yml`:
```yaml
healthcheck:
  test: ["CMD-SHELL", "pg_isready -U sandbox_user -d sandbox_dev"]
  interval: 10s
  timeout: 5s
  retries: 5
  start_period: 30s  # Increase this for slow systems
```

**2. Fix Health Check Command:**

Ensure command matches service configuration:
```yaml
# PostgreSQL - match username and database
test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER} -d ${POSTGRES_DB}"]

# Redis - use correct auth
test: ["CMD", "redis-cli", "--pass", "${REDIS_PASSWORD}", "ping"]
```

**3. Wait Longer:**

Services may take time to initialize, especially PostgreSQL. Wait 30-60 seconds after `docker compose up`.

---

**Next:** [Firewall Issues](firewall.md) | [Back to Main](../TROUBLESHOOTING.md)
