# Production Security & Deployment Guide

## Table of Contents
1. [Security Headers](#security-headers)
2. [Rate Limiting](#rate-limiting)
3. [Input Sanitization](#input-sanitization)
4. [CORS Configuration](#cors-configuration)
5. [Secrets Management](#secrets-management)
6. [Monitoring](#monitoring)
7. [Error Tracking](#error-tracking)
8. [Performance Optimization](#performance-optimization)

---

## Security Headers

### Implemented Headers

#### 1. Strict-Transport-Security (HSTS)
```
Strict-Transport-Security: max-age=31536000; includeSubDomains
```
- Forces HTTPS for 1 year
- Applies to all subdomains
- Prevents protocol downgrade attacks

#### 2. Content-Security-Policy (CSP)
```
default-src 'self'; script-src 'self' 'unsafe-inline' 'unsafe-eval'; ...
```
- Prevents XSS attacks
- Controls which resources can be loaded
- Blocks inline scripts (except where explicitly allowed)

####3. X-Frame-Options
```
X-Frame-Options: DENY
```
- Prevents clickjacking attacks
- Blocks iframe embedding

#### 4. X-Content-Type-Options
```
X-Content-Type-Options: nosniff
```
- Prevents MIME sniffing
- Forces correct content type

#### 5. X-XSS-Protection
```
X-XSS-Protection: 1; mode=block
```
- Enables browser XSS protection
- Blocks page if XSS detected

#### 6. Referrer-Policy
```
Referrer-Policy: strict-origin-when-cross-origin
```
- Controls referrer information
- Protects sensitive URLs

#### 7. Permissions-Policy
```
Permissions-Policy: geolocation=(), microphone=(), camera=()
```
- Disables unnecessary browser features
- Reduces attack surface

### Implementation

**NestJS (src/middleware/security-headers.middleware.ts)**:
```typescript
import { SecurityHeadersMiddleware } from './middleware/security-headers.middleware';

app.use(SecurityHeadersMiddleware);
```

**FastAPI (app/middleware/security.py)**:
```python
from app.middleware.security import SecurityHeadersMiddleware

app.add_middleware(SecurityHeadersMiddleware)
```

---

## Rate Limiting

### Configuration

#### Global Rate Limiting
- **100 requests per minute** per IP address
- **1000 requests per hour** per user
- **10,000 requests per day** per API key

#### Endpoint-Specific Limits

| Endpoint | Limit | Window |
|----------|-------|--------|
| `/api/v1/auth/login` | 5 requests | 15 minutes |
| `/api/v1/auth/register` | 3 requests | 1 hour |
| `/api/v1/transactions` (POST) | 20 requests | 1 minute |
| `/api/v1/ai/*` | 10 requests | 1 minute |

### Implementation

**Install Dependencies**:
```bash
# NestJS
npm install @nestjs/throttler

# FastAPI
pip install slowapi redis
```

**Configure**:
```typescript
// NestJS
import { ThrottlerModule } from '@nestjs/throttler';

ThrottlerModule.forRoot({
  ttl: 60,
  limit: 100,
})
```

```python
# FastAPI
from slowapi import Limiter
from slowapi.util import get_remote_address

limiter = Limiter(key_func=get_remote_address)
app.state.limiter = limiter
```

### DDoS Protection

1. **Use Cloudflare** or similar CDN
2. **Implement IP allowlist/blocklist**
3. **Monitor unusual traffic patterns**
4. **Set up automatic banning** for abusive IPs

---

## Input Sanitization

### Validation Rules

#### 1. Email Validation
```typescript
// Regex pattern
/^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/

// Sanitization
- Convert to lowercase
- Trim whitespace
- Remove special characters
- Check for SQL injection patterns
```

#### 2. Password Validation
```
Requirements:
- Minimum 8 characters
- At least one uppercase letter
- At least one lowercase letter
- At least one number
- At least one special character
```

#### 3. Numeric Validation
```typescript
// Amount validation
- Must be positive number
- Maximum 2 decimal places
- Range: 0.01 to 999,999,999.99
```

#### 4. String Validation
```typescript
// Description/Notes
- Maximum length: 500 characters
- HTML escaped
- No SQL injection patterns
- No XSS patterns
```

#### 5. Array Validation
```typescript
// Tags validation
- Maximum 10 tags
- Each tag max 50 characters
- Alphanumeric + hyphens only
- Converted to lowercase
```

### SQL Injection Protection

**Using ORM** (Automatic Protection):
```typescript
// TypeORM/Prisma automatically escapes queries
await transactionRepository.find({
  where: { userId: user.id }
});
```

**Pattern Detection**:
```python
SQL_INJECTION_PATTERNS = [
    r"(\bOR\b|\bAND\b)\s+\d+\s*=\s*\d+",  # OR 1=1
    r";\s*DROP\s+TABLE",  # DROP TABLE
    r"UNION\s+SELECT",  # UNION SELECT
]
```

### XSS Protection

1. **Escape all user input** before rendering
2. **Use Content Security Policy** headers
3. **Validate and sanitize** HTML input
4. **Use templating engines** with auto-escaping

**Implementation** (app/utils/sanitization.py):
```python
from app.utils.sanitization import InputSanitizer

# Sanitize string
clean_text = InputSanitizer.sanitize_string(user_input)

# Sanitize email
clean_email = InputSanitizer.sanitize_email(email)

# Sanitize tags
clean_tags = sanitize_tags(tags)
```

---

## CORS Configuration

### Production CORS Settings

```typescript
// NestJS
app.enableCors({
  origin: [
    'https://yourdomain.com',
    'https://www.yourdomain.com',
  ],
  credentials: true,
  methods: ['GET', 'POST', 'PUT', 'DELETE'],
  allowedHeaders: ['Authorization', 'Content-Type'],
  maxAge: 3600,
});
```

```python
# FastAPI
from app.middleware.security import get_cors_config

cors_config = get_cors_config('production')
app.add_middleware(CORSMiddleware, **cors_config)
```

### Environment-Specific Configuration

**Development**:
- Allow `localhost:3000`, `localhost:3001`
- Allow all methods
- Allow all headers

**Staging**:
- Allow `staging.yourdomain.com`
- Restricted methods
- Specific headers only

**Production**:
- Allow only production domain(s)
- Strict method allowlist
- Minimal headers
- Credentials enabled

---

## Secrets Management

### Environment Variables

**Never commit** `.env` files to version control!

#### Required Secrets

```env
# Database
DATABASE_URL=postgresql://user:password@host:port/dbname

# JWT
SECRET_KEY=<generate-strong-random-key>
REFRESH_SECRET_KEY=<different-strong-random-key>
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# OpenAI
OPENAI_API_KEY=sk-...

# Email (if using)
SMTP_HOST=smtp.gmail.com
SMTP_PORT=587
SMTP_USER=your-email@gmail.com
SMTP_PASSWORD=<app-specific-password>

# Sentry (Error Tracking)
SENTRY_DSN=https://...@sentry.io/...

# Environment
NODE_ENV=production
DEBUG=false
```

#### Generate Strong Secrets

```bash
# Generate random secret key
openssl rand -hex 32

# Or using Python
python -c "import secrets; print(secrets.token_urlsafe(32))"

# Or using Node.js
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### Secret Management Solutions

#### Option 1: AWS Secrets Manager
```bash
# Store secret
aws secretsmanager create-secret \
  --name expense-ai/database-url \
  --secret-string "postgresql://..."

# Retrieve in application
import boto3
client = boto3.client('secretsmanager')
secret = client.get_secret_value(SecretId='expense-ai/database-url')
```

#### Option 2: HashiCorp Vault
```bash
# Store secret
vault kv put secret/expense-ai database_url="postgresql://..."

# Retrieve in application
vault kv get -field=database_url secret/expense-ai
```

#### Option 3: Kubernetes Secrets
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: expense-ai-secrets
type: Opaque
data:
  database-url: <base64-encoded-value>
```

### Best Practices

1. ✅ **Rotate secrets regularly** (every 90 days)
2. ✅ **Use different secrets** for each environment
3. ✅ **Limit secret access** to necessary services only
4. ✅ **Audit secret access** regularly
5. ✅ **Never log secrets** or expose in error messages

---

## Monitoring

### Health Check Endpoints

**GET /health**
```json
{
  "status": "healthy",
  "timestamp": "2024-02-15T10:00:00Z",
  "version": "1.0.0",
  "checks": {
    "database": {
      "status": "healthy",
      "message": "Database connection successful"
    },
    "system": {
      "status": "healthy",
      "cpu_percent": 15.2,
      "memory_percent": 45.8,
      "disk_percent": 62.1
    }
  }
}
```

**GET /metrics**
```json
{
  "timestamp": "2024-02-15T10:00:00Z",
  "system": {
    "cpu_percent": 15.2,
    "memory_percent": 45.8,
    "disk_percent": 62.1
  },
  "process": {
    "cpu_percent": 2.5,
    "memory_mb": 156.4,
    "num_threads": 8
  }
}
```

### Monitoring Tools

#### 1. Application Performance Monitoring (APM)

**New Relic**:
```bash
npm install newrelic
# Add to app startup
require('newrelic');
```

**DataDog**:
```bash
npm install dd-trace
# Initialize
const tracer = require('dd-trace').init();
```

#### 2. Log Aggregation

**ELK Stack** (Elasticsearch, Logstash, Kibana):
```yaml
# docker-compose.yml
elasticsearch:
  image: elasticsearch:8.0.0
  ports:
    - "9200:9200"

logstash:
  image: logstash:8.0.0
  volumes:
    - ./logstash.conf:/usr/share/logstash/pipeline/logstash.conf

kibana:
  image: kibana:8.0.0
  ports:
    - "5601:5601"
```

**Splunk**:
- Configure HTTP Event Collector
- Send logs in JSON format
- Create dashboards for monitoring

#### 3. Uptime Monitoring

**UptimeRobot**:
- Monitor `/health` endpoint every 5 minutes
- Alert via email/SMS on downtime
- Track response times

**Pingdom**:
- Real user monitoring
- Transaction monitoring
- Alert on slowdowns

### Alerts Configuration

```yaml
# Example alert rules
alerts:
  - name: High Error Rate
    condition: error_rate > 5%
    duration: 5m
    severity: critical
    notify: [email, slack, pagerduty]

  - name: High Response Time
    condition: p95_latency > 1000ms
    duration: 10m
    severity: warning
    notify: [email, slack]

  - name: Database Connection Failed
    condition: database_status == "unhealthy"
    duration: 1m
    severity: critical
    notify: [email, slack, pagerduty]

  - name: High CPU Usage
    condition: cpu_percent > 80%
    duration: 15m
    severity: warning
    notify: [email]
```

---

## Error Tracking

### Sentry Integration

#### Installation

```bash
# NestJS
npm install @sentry/node @sentry/tracing

# FastAPI
pip install sentry-sdk
```

#### Configuration

**NestJS**:
```typescript
import * as Sentry from '@sentry/node';

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 1.0,
  beforeSend(event) {
    // Filter sensitive data
    if (event.request) {
      delete event.request.cookies;
      delete event.request.headers['authorization'];
    }
    return event;
  },
});
```

**FastAPI**:
```python
import sentry_sdk
from sentry_sdk.integrations.fastapi import FastApiIntegration

sentry_sdk.init(
    dsn=os.getenv("SENTRY_DSN"),
    environment=os.getenv("ENVIRONMENT"),
    traces_sample_rate=1.0,
    integrations=[FastApiIntegration()],
)
```

### Structured Logging

**Implementation** (app/utils/logging.py):
```python
from app.utils.logging import setup_logging

logger = setup_logging(log_level="INFO", log_file="app.log")

# Log with context
logger.info("Transaction created", extra={
    "user_id": user.id,
    "transaction_id": transaction.id,
    "amount": transaction.amount
})
```

**Log Format** (JSON):
```json
{
  "timestamp": "2024-02-15T10:00:00.123Z",
  "level": "INFO",
  "logger": "app.api.transactions",
  "message": "Transaction created",
  "user_id": "123e4567-e89b-12d3-a456-426614174000",
  "transaction_id": "987fcdeb-51a2-43e1-9876-543210fedcba",
  "amount": 50.00,
  "environment": "production",
  "app": "ExpenseAI"
}
```

### Audit Logging

**Security-Sensitive Operations**:
```python
from app.utils.logging import audit_logger

# Login attempts
audit_logger.log_login(
    user_id=user.id,
    email=user.email,
    ip_address=request.client.host,
    success=True
)

# Transaction creation
audit_logger.log_transaction_create(
    user_id=user.id,
    transaction_id=transaction.id,
    amount=transaction.amount
)

# Budget alerts
audit_logger.log_budget_alert(
    user_id=user.id,
    budget_id=budget.id,
    category=budget.category.name,
    percentage=budget.percentage_used
)
```

**Audit Log Retention**:
- Keep audit logs for **minimum 1 year**
- Store in append-only storage
- Regular backups to immutable storage
- Compliance with regulations (GDPR, SOX, etc.)

---

## Performance Optimization

### Database Optimization

#### 1. Connection Pooling

**NestJS (TypeORM)**:
```typescript
TypeOrmModule.forRoot({
  type: 'postgres',
  // ... connection details
  extra: {
    max: 20,  // Maximum connections
    min: 5,   // Minimum connections
    idle_timeout: 10000,
    connection_timeout: 2000,
  },
})
```

**FastAPI (SQLAlchemy)**:
```python
from app.utils.performance import DatabaseOptimization

engine = create_async_engine(
    DATABASE_URL,
    **DatabaseOptimization.get_connection_pool_config()
)
```

#### 2. Query Optimization

**Indexes**:
```sql
-- Add indexes for frequently queried fields
CREATE INDEX idx_transactions_user_date ON transactions(user_id, date DESC);
CREATE INDEX idx_transactions_category ON transactions(category_id);
CREATE INDEX idx_budgets_user_active ON budgets(user_id, is_active);
```

**Eager Loading**:
```typescript
// Load related entities in single query
await transactionRepository.find({
  relations: ['category'],
  where: { userId: user.id }
});
```

**Pagination**:
```typescript
// Always paginate large result sets
await transactionRepository.find({
  skip: (page - 1) * limit,
  take: limit,
  order: { date: 'DESC' }
});
```

#### 3. Caching

**Install Redis**:
```bash
npm install ioredis
pip install redis
```

**Implement Caching**:
```python
from app.utils.performance import async_cached

@async_cached(ttl=300)  # Cache for 5 minutes
async def get_dashboard_data(user_id: str, month: int, year: int):
    # Expensive query
    return dashboard_data
```

**Cache Invalidation**:
```python
from app.utils.performance import invalidate_cache

# Invalidate when data changes
async def create_transaction(transaction: TransactionCreate):
    # Create transaction
    new_transaction = await transaction_service.create(transaction)

    # Invalidate dashboard cache
    invalidate_cache(f"get_dashboard_data:{user_id}")

    return new_transaction
```

### Frontend Optimization

#### 1. Next.js Configuration

**next.config.js**:
```javascript
module.exports = {
  reactStrictMode: true,
  swcMinify: true,
  compress: true,
  images: {
    domains: ['yourdomain.com'],
    formats: ['image/webp', 'image/avif'],
  },
  headers: async () => [
    {
      source: '/:path*',
      headers: [
        {
          key: 'X-DNS-Prefetch-Control',
          value: 'on'
        },
        {
          key: 'X-Frame-Options',
          value: 'DENY'
        }
      ],
    },
  ],
}
```

#### 2. Code Splitting

```typescript
// Lazy load components
const TransactionForm = dynamic(
  () => import('@/components/organisms/TransactionForm'),
  { loading: () => <LoadingState /> }
);
```

#### 3. Image Optimization

```typescript
import Image from 'next/image';

<Image
  src="/logo.png"
  alt="Logo"
  width={200}
  height={50}
  priority  // For above-the-fold images
  placeholder="blur"
/>
```

#### 4. API Response Compression

**Enable gzip/brotli**:
```typescript
// NestJS
import compression from 'compression';
app.use(compression());
```

---

## Production Deployment Checklist

### Pre-Deployment

- [ ] All environment variables set
- [ ] Database migrations applied
- [ ] Security headers configured
- [ ] Rate limiting enabled
- [ ] CORS configured for production domain
- [ ] Secrets rotated and stored securely
- [ ] SSL/TLS certificates installed
- [ ] Monitoring tools configured
- [ ] Error tracking enabled
- [ ] Logging configured
- [ ] Backup strategy in place

### Post-Deployment

- [ ] Health check endpoint responding
- [ ] Monitoring dashboards showing data
- [ ] Alerts configured and tested
- [ ] Load testing completed
- [ ] Security audit performed
- [ ] Penetration testing completed
- [ ] Documentation updated
- [ ] Team notified

### Ongoing Maintenance

- [ ] Monitor error rates daily
- [ ] Review logs weekly
- [ ] Rotate secrets every 90 days
- [ ] Update dependencies monthly
- [ ] Security audit quarterly
- [ ] Load test before major releases
- [ ] Backup restoration test quarterly

---

## Additional Resources

- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [OWASP API Security Top 10](https://owasp.org/www-project-api-security/)
- [CWE Top 25](https://cwe.mitre.org/top25/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**Last Updated**: 2024-02-15
**Version**: 1.0.0
