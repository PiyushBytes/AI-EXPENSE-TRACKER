# ExpenseAI - Production Deployment Quick Reference

## 🚀 Quick Deploy Guide

### Prerequisites
```bash
# Verify installations
docker --version
docker compose version
node --version
```

### 1. Configure Environment (5 minutes)
```bash
# Copy production template
cp .env.production.example .env.production

# Generate secrets
openssl rand -hex 32  # For JWT_SECRET
openssl rand -hex 32  # For JWT_REFRESH_SECRET

# Edit .env.production and fill in:
# - DATABASE_URL
# - JWT_SECRET
# - JWT_REFRESH_SECRET
# - OPENAI_API_KEY
# - SENTRY_DSN (optional)
# - CORS_ORIGIN (your domain)
```

### 2. Security Audit (2 minutes)
```bash
chmod +x security-audit.sh
./security-audit.sh

# Fix any errors before proceeding
```

### 3. Deploy (10 minutes)
```bash
chmod +x deploy.sh
./deploy.sh production

# Wait for services to start
# Script will automatically:
# - Backup database
# - Build images
# - Start services
# - Run migrations
# - Verify health
```

### 4. SSL Setup (One-time)
```bash
# Using Let's Encrypt
certbot certonly --webroot \
  -w /var/www/certbot \
  -d yourdomain.com \
  -d www.yourdomain.com

# Copy certificates to nginx folder
cp /etc/letsencrypt/live/yourdomain.com/fullchain.pem ./nginx/ssl/
cp /etc/letsencrypt/live/yourdomain.com/privkey.pem ./nginx/ssl/

# Restart nginx
docker compose -f docker-compose.production.yml restart nginx
```

### 5. Verify Deployment
```bash
# Check services
docker compose -f docker-compose.production.yml ps

# Test health endpoint
curl https://yourdomain.com/health

# Expected response:
# {
#   "status": "healthy",
#   "checks": {
#     "database": {"status": "healthy"},
#     "system": {"status": "healthy"}
#   }
# }

# Test API
curl https://yourdomain.com/api/v1/docs

# Test frontend
curl https://yourdomain.com
```

---

## 🔧 Common Operations

### View Logs
```bash
# All services
docker compose -f docker-compose.production.yml logs -f

# Specific service
docker compose -f docker-compose.production.yml logs -f backend
docker compose -f docker-compose.production.yml logs -f frontend

# Last 100 lines
docker compose -f docker-compose.production.yml logs --tail=100
```

### Restart Services
```bash
# All services
docker compose -f docker-compose.production.yml restart

# Specific service
docker compose -f docker-compose.production.yml restart backend
```

### Database Operations
```bash
# Backup
docker compose -f docker-compose.production.yml exec postgres \
  pg_dump -U postgres expense_ai > backup.sql

# Restore
docker compose -f docker-compose.production.yml exec -T postgres \
  psql -U postgres expense_ai < backup.sql

# Run migrations
docker compose -f docker-compose.production.yml exec backend \
  npm run migration:run
```

### Scale Services
```bash
# Scale backend to 3 instances
docker compose -f docker-compose.production.yml up -d --scale backend=3
```

### Stop Everything
```bash
docker compose -f docker-compose.production.yml down

# With volumes (⚠️ deletes data)
docker compose -f docker-compose.production.yml down -v
```

---

## 🔍 Troubleshooting

### Service Won't Start
```bash
# Check logs
docker compose -f docker-compose.production.yml logs backend

# Common issues:
# - Database not ready → Wait for postgres health check
# - Port already in use → Change port in docker-compose
# - Missing env vars → Check .env.production
```

### Database Connection Failed
```bash
# Verify database is running
docker compose -f docker-compose.production.yml ps postgres

# Test connection
docker compose -f docker-compose.production.yml exec postgres \
  psql -U postgres -c "SELECT 1"

# Check DATABASE_URL in .env.production
```

### High Memory/CPU Usage
```bash
# Check resource usage
docker stats

# Restart specific service
docker compose -f docker-compose.production.yml restart backend

# Check for memory leaks in logs
```

### SSL Certificate Issues
```bash
# Verify certificate files exist
ls -la ./nginx/ssl/

# Test nginx configuration
docker compose -f docker-compose.production.yml exec nginx \
  nginx -t

# Renew Let's Encrypt certificate
certbot renew
```

---

## 📊 Monitoring Checklist

### Daily
- [ ] Check `/health` endpoint
- [ ] Review error logs
- [ ] Monitor CPU/Memory (should be < 70%)
- [ ] Check Sentry for new errors

### Weekly
- [ ] Review slow query logs
- [ ] Check disk space
- [ ] Analyze access logs
- [ ] Update dependencies (if needed)

### Monthly
- [ ] Rotate secrets
- [ ] Database vacuum/analyze
- [ ] Review backup integrity
- [ ] Performance testing

---

## 🔒 Security Commands

### Generate Strong Secrets
```bash
# JWT Secret
openssl rand -hex 32

# Or using Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Or using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Check for Vulnerabilities
```bash
# Node.js dependencies
cd backend && npm audit

# Python dependencies (if using FastAPI)
pip install safety
safety check

# Docker images
docker scout cves expense-ai-backend
```

### Rotate Database Password
```bash
# 1. Update password in database
docker compose -f docker-compose.production.yml exec postgres \
  psql -U postgres -c "ALTER USER postgres PASSWORD 'new_password';"

# 2. Update .env.production with new password

# 3. Restart services
docker compose -f docker-compose.production.yml restart
```

---

## 📈 Performance Optimization

### Enable Redis Caching
```bash
# Already configured in docker-compose.production.yml
# Verify Redis is running
docker compose -f docker-compose.production.yml exec redis \
  redis-cli -a ${REDIS_PASSWORD} ping

# Expected: PONG
```

### Database Performance
```bash
# Analyze query performance
docker compose -f docker-compose.production.yml exec postgres \
  psql -U postgres expense_ai -c "SELECT * FROM pg_stat_statements ORDER BY total_time DESC LIMIT 10;"

# Vacuum database
docker compose -f docker-compose.production.yml exec postgres \
  psql -U postgres expense_ai -c "VACUUM ANALYZE;"
```

### Clear Cache
```bash
# Redis cache
docker compose -f docker-compose.production.yml exec redis \
  redis-cli -a ${REDIS_PASSWORD} FLUSHALL
```

---

## 🆘 Emergency Procedures

### Complete System Failure
```bash
# 1. Check all services
docker compose -f docker-compose.production.yml ps

# 2. Check logs for all services
docker compose -f docker-compose.production.yml logs

# 3. Restart everything
docker compose -f docker-compose.production.yml down
docker compose -f docker-compose.production.yml up -d

# 4. If still failing, restore from backup
./restore-from-backup.sh latest
```

### Database Corruption
```bash
# 1. Stop application
docker compose -f docker-compose.production.yml stop backend frontend

# 2. Backup current state
docker compose -f docker-compose.production.yml exec postgres \
  pg_dump -U postgres expense_ai > corrupted_backup.sql

# 3. Restore from good backup
cat backups/backup_YYYYMMDD_HHMMSS.sql | \
  docker compose -f docker-compose.production.yml exec -T postgres \
  psql -U postgres expense_ai

# 4. Restart application
docker compose -f docker-compose.production.yml start backend frontend
```

### Rollback Deployment
```bash
# 1. Stop current deployment
docker compose -f docker-compose.production.yml down

# 2. Restore database from backup
cat backups/backup_YYYYMMDD_HHMMSS.sql | \
  docker compose -f docker-compose.production.yml exec -T postgres \
  psql -U postgres expense_ai

# 3. Checkout previous version
git checkout <previous-commit-hash>

# 4. Rebuild and restart
docker compose -f docker-compose.production.yml build
docker compose -f docker-compose.production.yml up -d
```

---

## 📞 Support Contacts

### Monitoring URLs
- Health: `https://yourdomain.com/health`
- Metrics: `https://yourdomain.com/api/metrics`
- API Docs: `https://yourdomain.com/api/docs`
- Sentry: `https://sentry.io/organizations/your-org/projects/expense-ai`

### Log Files
- App: `./logs/app.log`
- Errors: `./logs/error.log`
- Audit: `./logs/audit.log`
- Nginx Access: `/var/log/nginx/access.log`
- Nginx Error: `/var/log/nginx/error.log`

---

## ✅ Production Checklist

Before going live:
- [ ] All environment variables configured
- [ ] Secrets generated and secured
- [ ] SSL certificates installed
- [ ] Domain DNS configured
- [ ] CORS configured for production domain
- [ ] Database backups automated
- [ ] Monitoring alerts configured
- [ ] Security audit passed
- [ ] Load testing completed
- [ ] Documentation reviewed
- [ ] Team trained on operations

---

**Quick Help:** For detailed information, see `PRODUCTION_SECURITY_GUIDE.md`

**Last Updated:** 2024-02-15
