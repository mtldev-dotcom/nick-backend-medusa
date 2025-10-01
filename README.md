# Nick Backend - Medusa E-commerce Platform

A Medusa v2 e-commerce backend built with TypeScript and PostgreSQL.

## Prerequisites

- Node.js >= 20
- Yarn package manager
- PostgreSQL database
- Redis (for production)

## Local Development

### 1. Clone the Repository

```bash
git clone <your-repository-url>
cd nick-backend-medusa
```

### 2. Install Dependencies

```bash
yarn install
```

### 3. Configure Environment Variables

Copy the `.env.template` file to `.env`:

```bash
cp .env.template .env
```

Update the `.env` file with your local configuration:

```env
# Database
DATABASE_URL=postgres://user:password@localhost:5432/medusa-db
DB_NAME=medusa-v2

# CORS
STORE_CORS=http://localhost:8000
ADMIN_CORS=http://localhost:5173,http://localhost:9000
AUTH_CORS=http://localhost:5173,http://localhost:9000

# Secrets (change for production!)
JWT_SECRET=supersecret
COOKIE_SECRET=supersecret

# Redis (optional for local dev)
REDIS_URL=redis://localhost:6379
```

### 4. Run Database Migrations

```bash
yarn medusa db:migrate
```

### 5. Seed the Database (Optional)

```bash
yarn seed
```

### 6. Start Development Server

```bash
yarn dev
```

The Medusa backend will be available at `http://localhost:9000`
The admin dashboard will be available at `http://localhost:9000/app`

## Build for Production

```bash
yarn build
```

## Production Deployment with Dokploy on Hetzner

### Prerequisites

1. A Hetzner VPS with Dokploy installed
2. PostgreSQL database (managed or self-hosted)
3. Redis database (managed or self-hosted)
4. Your repository pushed to GitHub

### Step 1: Prepare Your Application

Ensure your code is committed and pushed to GitHub.

### Step 2: Configure Dokploy

1. **Access Dokploy Dashboard**
   - Log into your Dokploy instance on your Hetzner server

2. **Connect GitHub Repository**
   - Go to the "Git" section and select "Github"
   - Click "Create Github App" and follow the authorization flow
   - Install the app and grant access to your repository

3. **Create New Application**
   - Create a new Application in Dokploy
   - Select your GitHub repository
   - Choose the branch to deploy (e.g., `main` or `production`)

### Step 3: Configure Environment Variables

In Dokploy's Environment Variables section, add the following:

```env
# Node Environment
NODE_ENV=production

# Database
DATABASE_URL=postgres://user:password@your-postgres-host:5432/medusa-prod

# CORS (update with your frontend domains)
STORE_CORS=https://your-store-domain.com
ADMIN_CORS=https://your-admin-domain.com
AUTH_CORS=https://your-admin-domain.com

# Secrets (generate secure random strings!)
JWT_SECRET=<generate-secure-random-string>
COOKIE_SECRET=<generate-secure-random-string>

# Redis
REDIS_URL=redis://your-redis-host:6379

# Admin (enable/disable)
DISABLE_MEDUSA_ADMIN=false

# Worker Mode (set to "server" for main app, "worker" for background jobs)
MEDUSA_WORKER_MODE=server
```

**Important:** Generate secure random strings for `JWT_SECRET` and `COOKIE_SECRET` using:
```bash
openssl rand -base64 32
```

### Step 4: Configure Build Settings

In Dokploy's General settings:

**Build Command:**
```bash
yarn install && yarn build
```

**Start Command:**
```bash
yarn start
```

### Step 5: Configure Domain

In Dokploy's Domains section:
- Add your custom domain or use the free generated domain via traefik.me
- Dokploy will automatically handle SSL certificates

### Step 6: Configure Resources (Optional)

In Advanced Settings, configure:
- **Memory Limit:** 1GB minimum (2GB recommended)
- **CPU Limit:** Adjust based on traffic
- **Port:** 9000 (Medusa default)

### Step 7: Deploy

1. Click "Deploy" in Dokploy
2. Monitor the deployment logs
3. Wait for the build and deployment to complete

### Step 8: Run Migrations (First Deployment)

For the first deployment, you may need to run migrations manually:

1. Access your application container in Dokploy
2. Run:
```bash
yarn medusa db:migrate
```

Or add a `predeploy` script in `package.json`:
```json
"scripts": {
  "predeploy": "medusa db:migrate",
  "build": "medusa build",
  "start": "medusa start"
}
```

## Production Architecture

For optimal production setup, consider running two separate Dokploy applications:

### Application 1: Medusa Server (API + Admin)
```env
MEDUSA_WORKER_MODE=server
DISABLE_MEDUSA_ADMIN=false
```

### Application 2: Medusa Worker (Background Jobs)
```env
MEDUSA_WORKER_MODE=worker
DISABLE_MEDUSA_ADMIN=true
```

Both should connect to the same PostgreSQL and Redis instances.

## Available Scripts

- `yarn dev` - Start development server with hot reload
- `yarn build` - Build for production
- `yarn start` - Start production server
- `yarn seed` - Seed database with sample data
- `yarn test:unit` - Run unit tests
- `yarn test:integration:http` - Run HTTP integration tests
- `yarn test:integration:modules` - Run module integration tests

## Documentation

- [Medusa Documentation](https://docs.medusajs.com)
- [Deployment Guide](https://docs.medusajs.com/learn/deployment/general)
- [Dokploy Documentation](https://docs.dokploy.com)

## Support

- [Medusa Discord](https://discord.gg/medusajs)
- [GitHub Discussions](https://github.com/medusajs/medusa/discussions)
- [GitHub Issues](https://github.com/medusajs/medusa/issues)


## Run with Docker Compose

The project includes a `docker-compose.yml` for local development and production. This will start your Medusa backend, PostgreSQL and Redis with non-conflicting ports.

1. Build and start all services:

```bash
docker-compose up --build
```

2. Medusa API/Admin will be available at [http://localhost:19000](http://localhost:19000)

3. PostgreSQL will be available at port `15432`, Redis at port `16379`.

**Environment variables and secrets** can be adjusted in the `docker-compose.yml` file.

### Sample Compose file

```yaml
version: "3.8"
services:
  postgres:
    image: postgres:15
    environment:
      POSTGRES_USER: medusa
      POSTGRES_PASSWORD: medusapass
      POSTGRES_DB: medusa-db
    ports:
      - "15432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data

  redis:
    image: redis:7
    ports:
      - "16379:6379"
    volumes:
      - redis_data:/data

  medusa-server:
    build: .
    restart: always
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://medusa:medusapass@postgres:5432/medusa-db
      REDIS_URL: redis://redis:6379
      JWT_SECRET: supersecret
      COOKIE_SECRET: supersecret
      STORE_CORS: http://localhost:18000
      ADMIN_CORS: http://localhost:15173,http://localhost:19000
      AUTH_CORS: http://localhost:15173,http://localhost:19000
      MEDUSA_WORKER_MODE: server
      DISABLE_MEDUSA_ADMIN: "false"
    ports:
      - "19000:9000"
    depends_on:
      - postgres
      - redis
    command: yarn start

  medusa-worker:
    build: .
    restart: always
    environment:
      NODE_ENV: production
      DATABASE_URL: postgres://medusa:medusapass@postgres:5432/medusa-db
      REDIS_URL: redis://redis:6379
      JWT_SECRET: supersecret
      COOKIE_SECRET: supersecret
      MEDUSA_WORKER_MODE: worker
      DISABLE_MEDUSA_ADMIN: "true"
    depends_on:
      - postgres
      - redis
    command: yarn start

volumes:
  postgres_data:
  redis_data:
```

**Note:**  
- You may need to run migrations manually on first launch:  
  `docker-compose exec medusa-server yarn medusa db:migrate`
- Adjust secrets and CORS origins for your environment.


## Local Development: Docker Compose

You can run the Medusa backend, PostgreSQL, and Redis locally with Docker Compose. This allows for easy setup and teardown, and ensures all dependencies are isolated.

### 1. Prerequisites

- Docker and Docker Compose installed
- The `Dockerfile` and `docker-compose.yml` saved in your project root

### 2. Start the Services

From your project root, run:

```bash
docker-compose up --build
```

This will start:
- **PostgreSQL** on port `15432`
- **Redis** on port `16379`
- **Medusa backend** (with hot reload) on port `19000`

### 3. Run Database Migrations

After the containers are running, run migrations:

```bash
docker-compose exec medusa yarn medusa db:migrate
```

### 4. (Optional) Seed the Database

You can seed test data with:

```bash
docker-compose exec medusa yarn seed
```

### 5. Access the Backend

- API and Admin: [http://localhost:19000](http://localhost:19000)
- PostgreSQL: `localhost:15432`
- Redis: `localhost:16379`

### 6. Stopping the Services

To stop and remove containers, run:

```bash
docker-compose down
```

### 7. Notes

- All code changes you make locally are reflected in the running container (hot reload).
- Environment variables and ports can be adjusted in `docker-compose.yml`.
- For production, use a separate compose file or adjust settings.
