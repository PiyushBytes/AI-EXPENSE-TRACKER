# Deployment Guide - ExpenseAI

## 📚 Table of Contents
1. [Quick Start](#quick-start)
2. [Deployment Methods](#deployment-methods)
3. [Environment Setup](#environment-setup)
4. [CI/CD Setup](#cicd-setup)
5. [Troubleshooting](#troubleshooting)

---

## 🚀 Quick Start

### One-Command Deployment

```bash
# Make script executable
chmod +x quick-deploy.sh

# Deploy to development
./quick-deploy.sh

# Deploy to staging
./quick-deploy.sh staging

# Deploy to production
./quick-deploy.sh production
```

### Full Deployment with All Features

```bash
# Make script executable
chmod +x one-click-deploy.sh

# Deploy to development (with tests)
./one-click-deploy.sh development

# Deploy to staging
./one-click-deploy.sh staging

# Deploy to production
./one-click-deploy.sh production

# Skip tests
SKIP_TESTS=true ./one-click-deploy.sh staging

# Skip backup
SKIP_BACKUP=true ./one-click-deploy.sh production
```

---

## 🔧 Deployment Methods

### Method 1: One-Click Deploy (Recommended)

**Features:**
- ✅ Automated dependency checks
- ✅ Environment validation
- ✅ Automated testing
- ✅ Database backup
- ✅ Health checks
- ✅ Rollback on failure

**Usage:**
```bash
./one-click-deploy.sh [environment]
```

### Method 2: Quick Deploy (Fast)

**Features:**
- ✅ Fast deployment
- ✅ Minimal checks
- ✅ Good for development

**Usage:**
```bash
./quick-deploy.sh [environment]
```

### Method 3: Manual Docker Compose

**Development:**
```bash
docker compose -f docker-compose.dev.yml up -d
```

**Staging:**
```bash
docker compose -f docker-compose.staging.yml up -d
```

**Production:**
```bash
docker compose -f docker-compose.production.yml up -d
```

### Method 4: Manual Step-by-Step

```bash
# 1. Build images
docker compose -f docker-compose.production.yml build

# 2. Start services
docker compose -f docker-compose.production.yml up -d

# 3. Run migrations
docker compose -f docker-compose.production.yml exec backend npm run migration:run

# 4. Check health
curl http://localhost:3000/health
```

---

## 🔐 Environment Setup

### Development Environment

**File:** `.env.development`

```bash
# Copy example
cp .env.development.example .env.development

# No changes needed for local development
```

**Includes:**
- Local PostgreSQL
- Local Redis
- Debug logging
- No SSL required
- Hot reload enabled

### Staging Environment

**File:** `.env.staging`

```bash
# Copy and configure
cp .env.staging.example .env.staging

# Edit these values:
# - DATABASE_URL
# - JWT_SECRET
# - JWT_REFRESH_SECRET
# - REDIS_PASSWORD
# - OPENAI_API_KEY
# - SENTRY_DSN
```

**Requirements:**
- Managed database (AWS RDS, DigitalOcean, etc.)
- Redis instance
- SSL certificates
- Domain configured

### Production Environment

**File:** `.env.production`

```bash
# Copy and configure
cp .env.production.example .env.production

# CRITICAL: Change all CHANGE_THIS values
# Generate secrets:
openssl rand -hex 32
```

**Checklist:**
- [ ] All secrets generated
- [ ] Database configured with SSL
- [ ] Redis secured with password
- [ ] CORS set to production domain
- [ ] Sentry configured
- [ ] Backup schedule set
- [ ] Monitoring enabled

---

## 🔄 CI/CD Setup

### GitHub Actions

**File:** `.github/workflows/ci-cd.yml`

**Setup Steps:**

1. **Configure Secrets** (GitHub Settings → Secrets):
   ```
   STAGING_HOST         - Staging server IP/domain
   STAGING_USER         - SSH username
   STAGING_SSH_KEY      - Private SSH key

   PROD_HOST            - Production server IP/domain
   PROD_USER            - SSH username
   PROD_SSH_KEY         - Private SSH key

   SLACK_WEBHOOK        - Slack webhook URL (optional)
   ```

2. **Workflow Triggers:**
   - Push to `main` → Deploy to production
   - Push to `develop` → Deploy to staging
   - Pull requests → Run tests only

3. **Pipeline Stages:**
   - Lint & Security Scan
   - Backend Tests
   - Frontend Tests
   - Build Docker Images
   - Deploy to Staging/Production
   - Health Check
   - Notify

### GitLab CI/CD

**File:** `.gitlab-ci.yml`

**Setup Steps:**

1. **Configure CI/CD Variables** (GitLab Settings → CI/CD):
   ```
   STAGING_HOST         - Staging server
   STAGING_USER         - SSH username
   STAGING_SSH_KEY      - Private SSH key

   PROD_HOST            - Production server
   PROD_USER            - SSH username
   PROD_SSH_KEY         - Private SSH key
   ```

2. **Pipeline Stages:**
   - Lint (Backend & Frontend)
   - Test (Backend & Frontend)
   - Build (Docker images)
   - Deploy (Staging/Production)

---

## 🏗️ Infrastructure Setup

### Server Requirements

**Minimum (Development):**
- 2 CPU cores
- 4 GB RAM
- 20 GB storage

**Recommended (Production):**
- 4 CPU cores
- 8 GB RAM
- 50 GB storage (SSD)
- Managed database
- Redis instance
- CDN (optional)

### Initial Server Setup

```bash
# 1. Update system
sudo apt update && sudo apt upgrade -y

# 2. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER

# 3. Install Docker Compose
sudo apt install docker-compose-plugin

# 4. Clone repository
git clone https://github.com/yourusername/expense-ai.git
cd expense-ai

# 5. Configure environment
cp .env.production.example .env.production
nano .env.production

# 6. Deploy
./one-click-deploy.sh production
```

### SSL Certificate Setup (Let's Encrypt)

```bash
# Install certbot
sudo apt install certbot

# Get certificate
sudo certbot certonly --standalone \
  -d yourdomain.com \
  -d www.yourdomain.com

# Copy to nginx folder
sudo cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./nginx/ssl/
sudo cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ./nginx/ssl/

# Set up auto-renewal
sudo crontab -e
# Add: 0 0 1 * * certbot renew --quiet
```

---

## 📊 Health Checks

### Manual Health Check

```bash
chmod +x health-check.sh
./health-check.sh [environment]
```

### Automated Monitoring

**Endpoints:**
- `/health` - Full system health
- `/metrics` - Prometheus metrics
- `/readiness` - Kubernetes readiness
- `/liveness` - Kubernetes liveness

**Example:**
```bash
# Check health
curl http://localhost:3000/health

# Expected response:
{
  "status": "healthy",
  "checks": {
    "database": {"status": "healthy"},
    "system": {"status": "healthy"}
  }
}
```

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Services Won't Start

```bash
# Check logs
docker compose -f docker-compose.production.yml logs

# Common causes:
# - Port already in use
# - Missing environment variables
# - Database not ready

# Solution:
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d
```

#### 2. Database Connection Failed

```bash
# Test connection
docker compose -f docker-compose.production.yml exec postgres \
  psql -U postgres -c "SELECT 1"

# Check DATABASE_URL in .env file
# Ensure PostgreSQL is running
```

#### 3. Build Failures

```bash
# Clear Docker cache
docker builder prune -a

# Rebuild without cache
docker compose -f docker-compose.production.yml build --no-cache
```

#### 4. Migration Errors

```bash
# Check migration status
docker compose -f docker-compose.production.yml exec backend \
  npm run migration:show

# Revert last migration
docker compose -f docker-compose.production.yml exec backend \
  npm run migration:revert

# Run migrations
docker compose -f docker-compose.production.yml exec backend \
  npm run migration:run
```

### Logs & Debugging

```bash
# View all logs
docker compose -f docker-compose.production.yml logs -f

# View specific service
docker compose -f docker-compose.production.yml logs -f backend

# Last 100 lines
docker compose -f docker-compose.production.yml logs --tail=100

# Save logs to file
docker compose -f docker-compose.production.yml logs > deployment.log
```

### Rollback

```bash
# 1. Stop current deployment
docker compose -f docker-compose.production.yml down

# 2. Restore database from backup
cat backups/backup_YYYYMMDD_HHMMSS.sql | \
  docker compose -f docker-compose.production.yml exec -T postgres \
  psql -U postgres expense_ai

# 3. Checkout previous version
git checkout <previous-commit>

# 4. Redeploy
./one-click-deploy.sh production
```

---

## 📋 Deployment Checklist

### Pre-Deployment

- [ ] All tests passing
- [ ] Environment variables configured
- [ ] Secrets generated and secured
- [ ] Database backup created
- [ ] SSL certificates installed
- [ ] Domain DNS configured
- [ ] Monitoring configured

### During Deployment

- [ ] Services start successfully
- [ ] Health checks passing
- [ ] Migrations completed
- [ ] No errors in logs

### Post-Deployment

- [ ] Application accessible
- [ ] All features working
- [ ] Performance metrics normal
- [ ] Monitoring active
- [ ] Team notified

---

## 🆘 Support

### Quick Commands Reference

```bash
# Deploy
./one-click-deploy.sh production

# Health check
./health-check.sh production

# View logs
docker compose -f docker-compose.production.yml logs -f

# Restart service
docker compose -f docker-compose.production.yml restart backend

# Stop all
docker compose -f docker-compose.production.yml down

# Backup database
docker compose -f docker-compose.production.yml exec postgres \
  pg_dump -U postgres expense_ai > backup.sql
```

### Getting Help

- Documentation: See all `*.md` files
- Issues: GitHub Issues
- Logs: `docker-compose logs`
- Health: `curl /health`

---

**Last Updated:** 2024-02-15
**Version:** 1.0.0
