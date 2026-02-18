# ExpenseAI - Quick Start Guide

Complete guide to running the ExpenseAI application (FastAPI backend + Next.js frontend).

## Prerequisites

- Python 3.10+
- Node.js 18+
- PostgreSQL 14+
- OpenAI API Key (for AI features)

## Backend Setup

### 1. Database Setup

```bash
# Create PostgreSQL database
createdb expense_tracker

# Or using psql
psql -U postgres
CREATE DATABASE expense_tracker;
\q
```

### 2. Backend Configuration

```bash
# Navigate to backend directory
cd backend

# Create virtual environment
python -m venv venv

# Activate virtual environment
# On Windows:
venv\Scripts\activate
# On macOS/Linux:
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
cp .env.example .env
```

### 3. Configure .env file

Edit `backend/.env`:

```env
# Database
DATABASE_URL=postgresql://postgres:password@localhost:5432/expense_tracker

# JWT
SECRET_KEY=your-secret-key-here-change-this-in-production
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=15
REFRESH_TOKEN_EXPIRE_DAYS=7

# OpenAI
OPENAI_API_KEY=your-openai-api-key-here

# App
APP_NAME=ExpenseAI
DEBUG=True
```

### 4. Run Database Migrations

```bash
# Initialize Alembic (if not already done)
alembic init alembic

# Run migrations
alembic upgrade head
```

### 5. Start Backend Server

```bash
# Run with uvicorn
uvicorn main:app --reload --host 0.0.0.0 --port 8000

# Backend will be available at: http://localhost:8000
# API docs at: http://localhost:8000/docs
```

## Frontend Setup

### 1. Install Dependencies

```bash
# Navigate to frontend directory
cd frontend

# Install packages
npm install
# or
yarn install
# or
pnpm install
```

### 2. Configure Environment

```bash
# Create .env.local
cp .env.example .env.local
```

Edit `frontend/.env.local`:

```env
NEXT_PUBLIC_API_URL=http://localhost:8000
```

### 3. Start Frontend Server

```bash
# Run development server
npm run dev
# or
yarn dev
# or
pnpm dev

# Frontend will be available at: http://localhost:3000
```

## First Time Usage

### 1. Create an Account

1. Open http://localhost:3000
2. Click "Sign up"
3. Fill in:
   - Email
   - Name (optional)
   - Password
   - Monthly Income (optional)
4. Click "Create Account"

### 2. Login

1. Enter your email and password
2. Click "Sign In"
3. You'll be redirected to the dashboard

### 3. Create Categories (Optional)

The system comes with default categories, but you can create custom ones:

1. Use the API docs at http://localhost:8000/docs
2. Or create them via the backend

### 4. Add Your First Transaction

1. Go to "Transactions" page
2. Click "+ Add Transaction"
3. Fill in the form:
   - Amount
   - Category
   - Date
   - Description (optional)
   - Payment method (optional)
   - Tags (optional)
4. Click "Create Transaction"

### 5. Set Up Budgets

1. Go to "Budgets" page
2. Click "+ Create Budget"
3. Fill in:
   - Category
   - Budget Limit
   - Period (daily/weekly/monthly/yearly)
   - Alert Threshold
4. Click "Create Budget"

### 6. Generate AI Insights

1. Go to "Insights" page
2. Click "Generate New Insights"
3. AI will analyze your transactions and provide personalized advice

## Project Structure

```
AI-EXPENSE-TRACKER/
├── backend/                 # FastAPI backend
│   ├── app/
│   │   ├── api/            # API routes
│   │   ├── db/             # Database models
│   │   ├── schemas/        # Pydantic schemas
│   │   └── services/       # Business logic
│   ├── alembic/            # Database migrations
│   ├── main.py             # FastAPI app
│   └── requirements.txt    # Python dependencies
│
└── frontend/               # Next.js frontend
    ├── app/                # App router pages
    ├── components/         # React components
    ├── services/           # API services
    ├── lib/                # Utilities
    └── types/              # TypeScript types
```

## Common Issues & Solutions

### Backend Issues

**Issue**: Database connection error
```
Solution: Check PostgreSQL is running and DATABASE_URL is correct
```

**Issue**: Migration errors
```bash
# Reset database
alembic downgrade base
alembic upgrade head
```

**Issue**: OpenAI API errors
```
Solution: Verify OPENAI_API_KEY is set correctly in .env
```

### Frontend Issues

**Issue**: API connection refused
```
Solution: Ensure backend is running on http://localhost:8000
```

**Issue**: CORS errors
```
Solution: Backend is configured to allow localhost:3000
Check main.py for CORS settings
```

**Issue**: Module not found
```bash
# Clear cache and reinstall
rm -rf node_modules package-lock.json
npm install
```

## Development Workflow

### Making Changes

1. **Backend Changes**:
   - Modify files in `backend/app/`
   - Server auto-reloads with `--reload` flag
   - Test at http://localhost:8000/docs

2. **Frontend Changes**:
   - Modify files in `frontend/`
   - Next.js auto-reloads
   - View at http://localhost:3000

### Database Changes

1. **Create Migration**:
```bash
cd backend
alembic revision --autogenerate -m "description"
```

2. **Apply Migration**:
```bash
alembic upgrade head
```

3. **Rollback**:
```bash
alembic downgrade -1
```

## Testing

### Backend API Testing

```bash
# Using curl
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Or use the interactive API docs
http://localhost:8000/docs
```

### Frontend Testing

1. Open http://localhost:3000
2. Navigate through all pages
3. Test creating transactions, budgets, etc.

## Production Deployment

### Backend (FastAPI)

```bash
# Install production dependencies
pip install gunicorn

# Run with gunicorn
gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000
```

### Frontend (Next.js)

```bash
# Build for production
npm run build

# Start production server
npm start
```

### Environment Variables for Production

Update these for production:

**Backend `.env`**:
```env
DEBUG=False
DATABASE_URL=postgresql://user:password@prod-db-host:5432/expense_tracker
SECRET_KEY=strong-random-secret-key
```

**Frontend `.env.local`**:
```env
NEXT_PUBLIC_API_URL=https://your-api-domain.com
```

## API Documentation

Once the backend is running, visit:

- **Interactive API Docs**: http://localhost:8000/docs
- **Alternative Docs**: http://localhost:8000/redoc

## Features Overview

### ✅ Authentication
- User registration and login
- JWT token-based authentication
- Automatic token refresh

### ✅ Dashboard
- Monthly financial overview
- Income vs Expenses
- Savings rate calculation
- Trend comparison

### ✅ Transactions
- Create, read, update, delete transactions
- Category-based organization
- Tag support
- Payment method tracking
- Pagination

### ✅ Budgets
- Set spending limits per category
- Visual progress tracking
- Alert notifications
- Multiple period types

### ✅ AI Features
- Natural language transaction parsing
- Automatic categorization
- Personalized insights
- Spending pattern analysis

## Support

For issues or questions:
1. Check the API docs at `/docs`
2. Review the FRONTEND_README.md
3. Check backend logs
4. Review browser console for frontend errors

## Next Steps

1. Customize categories for your needs
2. Import existing transactions (via bulk API)
3. Set up budgets for all spending categories
4. Generate regular AI insights
5. Review and optimize your spending patterns

Enjoy using ExpenseAI! 🎉
