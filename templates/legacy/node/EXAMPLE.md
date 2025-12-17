# Example: Node.js Project with MongoDB and Redis

Complete configuration for a Node.js/TypeScript API using Express, MongoDB, and Redis.

## Project Structure

```
my-node-project/
├── .devcontainer/
│   ├── devcontainer.json
│   ├── Dockerfile
│   └── init-firewall.sh
├── docker-compose.yml
├── package.json
├── tsconfig.json
├── src/
│   ├── index.ts
│   ├── db.ts
│   └── routes/
│       └── health.ts
└── tests/
    └── health.test.ts
```

## Configuration Files

### .devcontainer/devcontainer.json

```json
{
  "name": "My Node.js App Sandbox",
  "build": {
    "dockerfile": "Dockerfile",
    "context": "..",
    "args": {
      "TZ": "${localEnv:TZ:America/Los_Angeles}",
      "CLAUDE_CODE_VERSION": "latest",
      "GIT_DELTA_VERSION": "0.18.2",
      "ZSH_IN_DOCKER_VERSION": "1.2.0"
    }
  },
  "runArgs": [
    "--cap-add=NET_ADMIN",
    "--cap-add=NET_RAW",
    "--network=node-app-network"
  ],
  "containerUser": "node",
  "remoteUser": "node",
  "mounts": [
    {
      "source": "claude-code-bashhistory-${devcontainerId}",
      "target": "/home/node/.bash_history_dir",
      "type": "volume"
    },
    {
      "source": "claude-code-config-${devcontainerId}",
      "target": "/home/node/.claude",
      "type": "volume"
    }
  ],
  "workspaceMount": "source=${localWorkspaceFolder},target=/workspace,type=bind,consistency=delegated",
  "workspaceFolder": "/workspace",
  "postStartCommand": "/usr/local/bin/init-firewall.sh",
  "postCreateCommand": "npm install",
  "customizations": {
    "vscode": {
      "extensions": [
        "anthropic.claude-code",
        "dbaeumer.vscode-eslint",
        "esbenp.prettier-vscode",
        "eamodio.gitlens",
        "mongodb.mongodb-vscode",
        "ms-vscode.vscode-typescript-next"
      ],
      "settings": {
        "terminal.integrated.defaultProfile.linux": "zsh",
        "editor.formatOnSave": true,
        "editor.defaultFormatter": "esbenp.prettier-vscode",
        "editor.tabSize": 2,
        "editor.codeActionsOnSave": {
          "source.fixAll.eslint": true
        }
      }
    }
  },
  "containerEnv": {
    "HISTFILE": "/home/node/.bash_history_dir/.bash_history",
    "FIREWALL_MODE": "strict",
    "NODE_ENV": "development",
    "MONGODB_URL": "mongodb://admin:devpass@mongodb:27017/myapp?authSource=admin",
    "// NOTE": "For passwords with special characters, URL-encode them: encodeURIComponent(password)",
    "REDIS_URL": "redis://redis:6379",
    "PORT": "3000"
  }
}
```

### .devcontainer/Dockerfile

```dockerfile
FROM node:20-bookworm-slim

ARG TZ=America/Los_Angeles
ARG CLAUDE_CODE_VERSION=latest
ARG GIT_DELTA_VERSION=0.18.2
ARG ZSH_IN_DOCKER_VERSION=1.2.0

ENV TZ="$TZ"

# Install system packages
RUN apt-get update && apt-get install -y --no-install-recommends \
  git vim nano less procps sudo unzip wget curl ca-certificates gnupg gnupg2 \
  jq man-db zsh fzf gh \
  iptables ipset iproute2 dnsutils \
  && apt-get clean && rm -rf /var/lib/apt/lists/*

# Create node user (already exists in node image, but ensure correct setup)
RUN mkdir -p /usr/local/share/npm-global && \
  chown -R node:node /usr/local/share

# Persistent bash history
RUN mkdir /commandhistory && \
  touch /commandhistory/.bash_history && \
  chown -R node /commandhistory

ENV DEVCONTAINER=true

# Create workspace and config directories
RUN mkdir -p /workspace /home/node/.claude && \
  chown -R node:node /workspace /home/node/.claude

WORKDIR /workspace

# Pre-install Node.js dependencies (for faster startup)
COPY --chown=node:node package*.json ./
RUN npm ci && \
  chown -R node:node /workspace/node_modules

# Install git-delta
RUN ARCH=$(dpkg --print-architecture) && \
  wget "https://github.com/dandavison/delta/releases/download/${GIT_DELTA_VERSION}/git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  dpkg -i "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb" && \
  rm "git-delta_${GIT_DELTA_VERSION}_${ARCH}.deb"

USER node

# Global npm configuration
ENV NPM_CONFIG_PREFIX=/usr/local/share/npm-global
ENV PATH=$PATH:/usr/local/share/npm-global/bin

# ZSH with Powerlevel10k
ENV SHELL=/bin/zsh

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v${ZSH_IN_DOCKER_VERSION}/zsh-in-docker.sh)" -- \
  -p git -p fzf \
  -a "source /usr/share/doc/fzf/examples/key-bindings.zsh" \
  -a "source /usr/share/doc/fzf/examples/completion.zsh" \
  -a "export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.bash_history" \
  -x

ENV EDITOR=nano
ENV VISUAL=nano

# Install Claude Code
RUN npm install -g @anthropic-ai/claude-code@${CLAUDE_CODE_VERSION}

# Set up firewall script
COPY .devcontainer/init-firewall.sh /usr/local/bin/
USER root
RUN chmod +x /usr/local/bin/init-firewall.sh && \
  echo "node ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh" > /etc/sudoers.d/node-firewall && \
  chmod 0440 /etc/sudoers.d/node-firewall
USER node
```

### docker-compose.yml

```yaml
services:
  # MongoDB Database
  mongodb:
    image: mongo:7
    container_name: node-app-mongodb
    environment:
      MONGO_INITDB_ROOT_USERNAME: admin
      MONGO_INITDB_ROOT_PASSWORD: devpass
      MONGO_INITDB_DATABASE: myapp
    ports:
      - "27017:27017"
    volumes:
      - mongodb_data:/data/db
      - mongodb_config:/data/configdb
    healthcheck:
      test: ["CMD", "mongosh", "--eval", "db.adminCommand('ping')"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Redis Cache
  redis:
    image: redis:7-alpine
    container_name: node-app-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    command: redis-server --appendonly yes
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  # Mongo Express (Database UI - Optional)
  mongo-express:
    image: mongo-express:latest
    container_name: node-app-mongo-express
    environment:
      ME_CONFIG_MONGODB_ADMINUSERNAME: admin
      ME_CONFIG_MONGODB_ADMINPASSWORD: devpass
      ME_CONFIG_MONGODB_URL: mongodb://admin:devpass@mongodb:27017/
      ME_CONFIG_BASICAUTH: false
    ports:
      - "8081:8081"
    depends_on:
      - mongodb

volumes:
  mongodb_data:
  mongodb_config:
  redis_data:

networks:
  default:
    name: node-app-network
```

### package.json

```json
{
  "name": "my-node-app",
  "version": "1.0.0",
  "description": "Node.js API with MongoDB and Redis",
  "main": "dist/index.js",
  "scripts": {
    "dev": "tsx watch src/index.ts",
    "build": "tsc",
    "start": "node dist/index.js",
    "test": "jest",
    "lint": "eslint src/**/*.ts",
    "format": "prettier --write \"src/**/*.ts\""
  },
  "keywords": [],
  "author": "",
  "license": "MIT",
  "dependencies": {
    "express": "^4.18.2",
    "mongodb": "^6.3.0",
    "redis": "^4.6.12",
    "dotenv": "^16.3.1",
    "helmet": "^7.1.0",
    "cors": "^2.8.5"
  },
  "devDependencies": {
    "@types/express": "^4.17.21",
    "@types/node": "^20.10.8",
    "@types/cors": "^2.8.17",
    "@typescript-eslint/eslint-plugin": "^6.18.1",
    "@typescript-eslint/parser": "^6.18.1",
    "eslint": "^8.56.0",
    "prettier": "^3.1.1",
    "typescript": "^5.3.3",
    "tsx": "^4.7.0",
    "jest": "^29.7.0",
    "@types/jest": "^29.5.11",
    "ts-jest": "^29.1.1"
  }
}
```

### tsconfig.json

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "module": "commonjs",
    "lib": ["ES2022"],
    "outDir": "./dist",
    "rootDir": "./src",
    "strict": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "forceConsistentCasingInFileNames": true,
    "resolveJsonModule": true,
    "moduleResolution": "node"
  },
  "include": ["src/**/*"],
  "exclude": ["node_modules", "dist"]
}
```

### .devcontainer/init-firewall.sh

Copy the template firewall script and customize the allowed domains:

```bash
ALLOWED_DOMAINS=(
  # Version control
  "github.com"

  # Package registries
  "registry.npmjs.org"

  # AI providers
  "api.anthropic.com"

  # Analytics
  "sentry.io"

  # VS Code
  "marketplace.visualstudio.com"
  "vscode.blob.core.windows.net"
  "update.code.visualstudio.com"
)
```

## Application Code Examples

### src/index.ts

```typescript
import express, { Express, Request, Response } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import { connectDB, getDB } from './db';
import healthRouter from './routes/health';

const app: Express = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());

// Routes
app.use('/health', healthRouter);

app.get('/', (req: Request, res: Response) => {
  res.json({ message: 'Hello from Claude Code sandbox!' });
});

// Start server
const start = async () => {
  try {
    // Connect to MongoDB
    await connectDB();
    console.log('Connected to MongoDB');

    app.listen(PORT, () => {
      console.log(`Server running on http://localhost:${PORT}`);
    });
  } catch (error) {
    console.error('Failed to start server:', error);
    process.exit(1);
  }
};

start();
```

### src/db.ts

```typescript
import { MongoClient, Db } from 'mongodb';
import { createClient, RedisClientType } from 'redis';

// NOTE: For passwords with special characters (@, :, /, etc.), URL-encode them:
// const password = encodeURIComponent(process.env.MONGO_PASSWORD || 'devpass');
// const MONGODB_URL = `mongodb://admin:${password}@mongodb:27017/myapp?authSource=admin`;
const MONGODB_URL = process.env.MONGODB_URL || 'mongodb://admin:devpass@mongodb:27017/myapp?authSource=admin';
const REDIS_URL = process.env.REDIS_URL || 'redis://redis:6379';

let mongoClient: MongoClient;
let db: Db;
let redisClient: RedisClientType;

export async function connectDB(): Promise<void> {
  // MongoDB
  mongoClient = new MongoClient(MONGODB_URL);
  await mongoClient.connect();
  db = mongoClient.db();

  // Redis
  redisClient = createClient({ url: REDIS_URL });
  redisClient.on('error', (err) => console.error('Redis Client Error', err));
  await redisClient.connect();
}

export function getDB(): Db {
  if (!db) {
    throw new Error('Database not initialized. Call connectDB first.');
  }
  return db;
}

export function getRedis(): RedisClientType {
  if (!redisClient) {
    throw new Error('Redis not initialized. Call connectDB first.');
  }
  return redisClient;
}

export async function closeDB(): Promise<void> {
  if (mongoClient) {
    await mongoClient.close();
  }
  if (redisClient) {
    await redisClient.quit();
  }
}
```

### src/routes/health.ts

```typescript
import { Router, Request, Response } from 'express';
import { getDB, getRedis } from '../db';

const router = Router();

router.get('/', async (req: Request, res: Response) => {
  try {
    // Test MongoDB
    const db = getDB();
    await db.admin().ping();

    // Test Redis
    const redis = getRedis();
    await redis.ping();

    res.json({
      status: 'healthy',
      services: {
        mongodb: 'connected',
        redis: 'connected'
      },
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(503).json({
      status: 'unhealthy',
      error: error instanceof Error ? error.message : 'Unknown error'
    });
  }
});

export default router;
```

## Setup Instructions

### 1. Copy Template Files

```bash
cd my-node-project
cp -r /path/to/template/.devcontainer .
cp /path/to/template/docker-compose.base.yml docker-compose.yml
```

### 2. Create Project Files

```bash
mkdir -p src/routes tests
touch src/index.ts src/db.ts src/routes/health.ts
touch tests/health.test.ts
touch package.json tsconfig.json .eslintrc.json .prettierrc
```

### 3. Start Services

```bash
docker compose up -d
```

### 4. Open in DevContainer

```bash
code .
# Ctrl+Shift+P → "Dev Containers: Reopen in Container"
```

### 5. Install Dependencies

Inside the DevContainer (may already be done via postCreateCommand):

```bash
npm install
```

### 6. Run Development Server

```bash
npm run dev
```

Access at: http://localhost:3000

### 7. Test Database Connection

```bash
# MongoDB
mongosh "mongodb://admin:devpass@mongodb:27017/myapp?authSource=admin"

# Redis
redis-cli -h redis ping
```

## Development Workflow

### Running the Application

```bash
# Development mode with hot reload
npm run dev

# Build for production
npm run build

# Run production build
npm start
```

### Running Tests

```bash
npm test
```

### Linting and Formatting

```bash
# Lint code
npm run lint

# Format code
npm run format
```

### Using Claude Code

```bash
# Start Claude Code session
claude

# Ask Claude to help with your code
# Examples:
# - "Add a user authentication route"
# - "Write tests for the health endpoint"
# - "Optimize the database queries"
```

## Database Management

### MongoDB

**Using Mongo Express UI:**

Access at: http://localhost:8081

**Using mongosh:**

```bash
# Connect to MongoDB
mongosh "mongodb://admin:devpass@mongodb:27017/myapp?authSource=admin"

# Show databases
show dbs

# Use your database
use myapp

# Show collections
show collections

# Insert document
db.users.insertOne({ name: "Alice", email: "alice@example.com" })

# Find documents
db.users.find()
```

### Redis

**Using redis-cli:**

```bash
# Connect to Redis
redis-cli -h redis

# Set a key
SET mykey "Hello from Claude Code"

# Get a key
GET mykey

# List all keys
KEYS *

# Check key expiration
TTL mykey
```

## Firewall Configuration

This setup uses **strict mode** by default. The firewall allows:

- `registry.npmjs.org` for npm packages
- `api.anthropic.com` for Claude Code
- `github.com` for git operations

To add more domains, edit `.devcontainer/init-firewall.sh` and restart the firewall:

```bash
sudo /usr/local/bin/init-firewall.sh
```

## Common Tasks

### Install New Package

```bash
npm install package-name
```

The container will auto-update since `node_modules` is on the host filesystem.

### Add New Route

```typescript
// src/routes/users.ts
import { Router, Request, Response } from 'express';
const router = Router();

router.get('/', async (req: Request, res: Response) => {
  // Your logic here
});

export default router;
```

```typescript
// src/index.ts
import usersRouter from './routes/users';
app.use('/users', usersRouter);
```

### Working with MongoDB Collections

```typescript
// Get a collection
const usersCollection = db.collection('users');

// Insert
await usersCollection.insertOne({ name: 'Alice' });

// Find
const users = await usersCollection.find({}).toArray();

// Update
await usersCollection.updateOne({ name: 'Alice' }, { $set: { age: 30 } });

// Delete
await usersCollection.deleteOne({ name: 'Alice' });
```

### Working with Redis

```typescript
const redis = getRedis();

// Set with expiration (in seconds)
await redis.set('session:123', 'user-data', { EX: 3600 });

// Get
const data = await redis.get('session:123');

// Delete
await redis.del('session:123');

// Check if key exists
const exists = await redis.exists('session:123');
```

## Troubleshooting

### Can't connect to MongoDB

```bash
# Check if MongoDB is healthy
docker compose ps

# Test connection
mongosh "mongodb://admin:devpass@mongodb:27017/?authSource=admin" --eval "db.adminCommand('ping')"
```

### npm install fails

```bash
# Switch to permissive firewall temporarily
export FIREWALL_MODE=permissive
sudo /usr/local/bin/init-firewall.sh

# Install packages
npm install

# Switch back to strict
export FIREWALL_MODE=strict
sudo /usr/local/bin/init-firewall.sh
```

### TypeScript compilation errors

```bash
# Clean build
rm -rf dist
npm run build
```

## Next Steps

- Add user authentication with JWT
- Implement CRUD operations for your models
- Add request validation with Zod or Joi
- Set up API documentation with Swagger
- Add logging with Winston
- Implement rate limiting
- Deploy to production

## Additional Resources

- [Express Documentation](https://expressjs.com/)
- [MongoDB Node.js Driver](https://www.mongodb.com/docs/drivers/node/current/)
- [Redis Node.js Guide](https://redis.io/docs/clients/nodejs/)
- [TypeScript Handbook](https://www.typescriptlang.org/docs/)

---

**Last Updated:** 2025-12-16
**Version:** 2.2.1
