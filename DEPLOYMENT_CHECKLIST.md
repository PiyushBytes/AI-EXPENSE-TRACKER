# Deployment & Testing Checklist

## Pre-Deployment Checklist

### Backend Verification

- [ ] PostgreSQL database is running
- [ ] Database migrations are up to date (`alembic upgrade head`)
- [ ] `.env` file exists with all required variables
- [ ] OpenAI API key is valid
- [ ] Secret key is set and secure
- [ ] Dependencies are installed (`pip install -r requirements.txt`)
- [ ] Backend starts without errors (`uvicorn main:app --reload`)
- [ ] API docs are accessible at `http://localhost:8000/docs`

### Frontend Verification

- [ ] Node modules are installed (`npm install`)
- [ ] `.env.local` file exists with API URL
- [ ] Frontend builds successfully (`npm run build`)
- [ ] Frontend starts without errors (`npm run dev`)
- [ ] No TypeScript errors
- [ ] All pages are accessible

## Component Testing Checklist

### Authentication Flow
- [ ] Registration page loads
- [ ] Can create new account
- [ ] Validation errors show correctly
- [ ] Login page loads
- [ ] Can login with created account
- [ ] Invalid credentials show error
- [ ] Token is stored in localStorage
- [ ] Automatic redirect to dashboard after login
- [ ] Logout functionality works
- [ ] Protected routes redirect to login when not authenticated

### Dashboard
- [ ] Dashboard loads without errors
- [ ] Period information displays correctly
- [ ] Summary stats show (income, expenses, balance, savings rate)
- [ ] Top expenses list displays
- [ ] Month/year selector works (if implemented)
- [ ] Loading state shows while fetching
- [ ] Error state shows on API failure

### Transactions
- [ ] Transaction list loads
- [ ] Pagination works (Load More button)
- [ ] Create transaction form displays
- [ ] Form validation works
- [ ] Can create new transaction
- [ ] Transaction appears in list after creation
- [ ] Toast notification shows on success
- [ ] Category icons and colors display
- [ ] Tags display correctly
- [ ] Empty state shows when no transactions
- [ ] Loading state shows while fetching
- [ ] Error state shows on API failure

### Budgets
- [ ] Budget grid loads
- [ ] Can create new budget
- [ ] Budget form validation works
- [ ] Progress bars display correctly
- [ ] Status badges show (On Track, Near Limit, Exceeded)
- [ ] Color coding works (green, yellow, red)
- [ ] Empty state shows when no budgets
- [ ] Loading state shows while fetching
- [ ] Error state shows on API failure

### AI Insights
- [ ] Insights list loads
- [ ] Generate insights button works
- [ ] New insights appear after generation
- [ ] Can mark insight as read
- [ ] Can dismiss insight
- [ ] Priority badges display correctly
- [ ] Empty state shows when no insights
- [ ] Loading state shows while fetching
- [ ] Error state shows on API failure

### Navigation
- [ ] Navbar displays on all pages
- [ ] Navigation links work
- [ ] Active page is highlighted
- [ ] User avatar shows
- [ ] Dropdown menu works
- [ ] Mobile navigation works
- [ ] Logout from menu works

### Error Handling
- [ ] Network errors show user-friendly messages
- [ ] 401 errors trigger token refresh
- [ ] Failed token refresh redirects to login
- [ ] Form validation errors display
- [ ] API error messages show in toasts

### Responsive Design
- [ ] Desktop layout works (1920px+)
- [ ] Laptop layout works (1280px)
- [ ] Tablet layout works (768px)
- [ ] Mobile layout works (375px)
- [ ] Touch targets are adequate on mobile
- [ ] Text is readable on all sizes

## API Endpoint Testing

### Authentication Endpoints
```bash
# Register
curl -X POST http://localhost:8000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123","name":"Test User"}'

# Login
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"test@example.com","password":"password123"}'

# Get current user (replace TOKEN)
curl -X GET http://localhost:8000/api/v1/users/me \
  -H "Authorization: Bearer TOKEN"
```

### Transaction Endpoints
```bash
# Create transaction (replace TOKEN)
curl -X POST http://localhost:8000/api/v1/transactions \
  -H "Authorization: Bearer TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"amount":50.00,"category_id":"CATEGORY_ID","date":"2024-01-15","description":"Lunch"}'

# List transactions (replace TOKEN)
curl -X GET http://localhost:8000/api/v1/transactions \
  -H "Authorization: Bearer TOKEN"
```

### Dashboard Endpoint
```bash
# Get dashboard (replace TOKEN)
curl -X GET http://localhost:8000/api/v1/dashboard \
  -H "Authorization: Bearer TOKEN"
```

## Performance Checklist

- [ ] Page load time < 3 seconds
- [ ] API response time < 500ms
- [ ] Images are optimized
- [ ] No console errors or warnings
- [ ] No memory leaks
- [ ] Smooth animations and transitions

## Security Checklist

- [ ] Passwords are hashed (bcrypt)
- [ ] JWT tokens expire appropriately
- [ ] No sensitive data in localStorage (only tokens)
- [ ] API endpoints are protected
- [ ] CORS is configured correctly
- [ ] SQL injection protection (using ORM)
- [ ] XSS protection
- [ ] CSRF protection for state-changing operations

## Browser Compatibility

- [ ] Chrome (latest)
- [ ] Firefox (latest)
- [ ] Safari (latest)
- [ ] Edge (latest)
- [ ] Mobile Chrome
- [ ] Mobile Safari

## Database Verification

```bash
# Connect to database
psql -U postgres -d expense_tracker

# Check tables exist
\dt

# Verify tables:
# - users
# - categories
# - transactions
# - budgets
# - insights
# - refresh_tokens

# Check sample data
SELECT COUNT(*) FROM users;
SELECT COUNT(*) FROM categories;
SELECT COUNT(*) FROM transactions;
```

## Environment Variables Check

### Backend (.env)
```env
✓ DATABASE_URL
✓ SECRET_KEY
✓ ALGORITHM
✓ ACCESS_TOKEN_EXPIRE_MINUTES
✓ REFRESH_TOKEN_EXPIRE_DAYS
✓ OPENAI_API_KEY
✓ APP_NAME
✓ DEBUG
```

### Frontend (.env.local)
```env
✓ NEXT_PUBLIC_API_URL
```

## Post-Deployment Verification

1. **Smoke Test**:
   - [ ] Can access the application
   - [ ] Can create an account
   - [ ] Can login
   - [ ] Can create a transaction
   - [ ] Can create a budget
   - [ ] Can generate insights

2. **Load Test** (Optional):
   - [ ] Application handles multiple concurrent users
   - [ ] Database queries are optimized
   - [ ] No performance degradation under load

3. **Backup**:
   - [ ] Database backup strategy in place
   - [ ] Environment variables backed up securely
   - [ ] Code is in version control

## Known Limitations

1. **Authentication**:
   - No email verification (can be added)
   - No password reset (can be added)
   - No 2FA (can be added)

2. **AI Features**:
   - Requires OpenAI API key (costs apply)
   - Limited by OpenAI rate limits

3. **File Uploads**:
   - No receipt upload feature (can be added)

4. **Export**:
   - No CSV/PDF export (can be added)

5. **Real-time**:
   - No WebSocket support (can be added)

## Success Criteria

✅ All authentication flows work
✅ All CRUD operations function correctly
✅ Loading states display properly
✅ Error handling works as expected
✅ Empty states show when appropriate
✅ Forms validate correctly
✅ Navigation works across all pages
✅ Responsive design works on all devices
✅ API integration is complete
✅ No critical errors in console

## Deployment Notes

### Development
- Backend: `uvicorn main:app --reload`
- Frontend: `npm run dev`

### Production
- Backend: `gunicorn main:app -w 4 -k uvicorn.workers.UvicornWorker`
- Frontend: `npm run build && npm start`

### Database
- Development: Local PostgreSQL
- Production: Managed PostgreSQL (AWS RDS, DigitalOcean, etc.)

## Monitoring (Recommended)

- [ ] Setup error tracking (Sentry)
- [ ] Setup performance monitoring
- [ ] Setup uptime monitoring
- [ ] Setup database monitoring
- [ ] Setup log aggregation

---

**Ready to Deploy?** ✅

If all checkboxes are marked, your application is ready for deployment!
