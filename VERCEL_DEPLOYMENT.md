# Vercel Deployment Guide - ExpenseAI

## 🚀 Quick Deploy to Vercel

### **Method 1: Vercel Dashboard (Easiest)**

1. **Push to GitHub** (I'll help you with this)
2. **Go to Vercel:** https://vercel.com/
3. **Click "Add New Project"**
4. **Import from GitHub:** Select `AI-EXPENSE-TRACKER`
5. **Configure:**
   - Framework Preset: **Next.js**
   - Root Directory: **frontend**
   - Build Command: `npm run build`
   - Output Directory: `.next`
6. **Add Environment Variables:**
   ```
   NEXT_PUBLIC_API_URL=https://your-backend-url.com
   ```
7. **Click Deploy!** 🚀

---

### **Method 2: Vercel CLI**

```bash
# Install Vercel CLI
npm install -g vercel

# Login
vercel login

# Deploy
cd frontend
vercel

# Follow the prompts:
# - Set up and deploy: Yes
# - Which scope: Your account
# - Link to existing project: No
# - Project name: expense-ai
# - Directory: ./
# - Override settings: No

# Production deployment
vercel --prod
```

---

## ⚙️ **Vercel Configuration**

### **Project Settings**

**Root Directory:** `frontend`

**Build Settings:**
- Build Command: `npm run build`
- Output Directory: `.next`
- Install Command: `npm install`
- Development Command: `npm run dev`

**Node Version:** 18.x

---

## 🔐 **Environment Variables**

Add these in Vercel Dashboard → Settings → Environment Variables:

### **Required:**
```
NEXT_PUBLIC_API_URL=https://your-backend-url.com
```

### **Optional:**
```
NODE_ENV=production
NEXT_TELEMETRY_DISABLED=1
```

---

## 🏗️ **Backend Deployment**

Since Vercel is frontend-only, deploy your backend separately:

### **Option 1: Railway** (Recommended)
```bash
# Install Railway CLI
npm install -g @railway/cli

# Login
railway login

# Deploy backend
cd backend
railway init
railway up
```

### **Option 2: Render**
1. Go to https://render.com/
2. New → Web Service
3. Connect GitHub repo
4. Root Directory: `backend`
5. Build Command: `npm install && npm run build`
6. Start Command: `npm run start:prod`

### **Option 3: Heroku**
```bash
# Install Heroku CLI
# Then:
cd backend
heroku create expense-ai-backend
git push heroku main
```

### **Option 4: DigitalOcean App Platform**
1. Go to https://cloud.digitalocean.com/apps
2. Create App → GitHub
3. Select repository
4. Configure as Node.js app

---

## 📝 **Frontend-Only Deployment (Vercel)**

If you want to deploy frontend-only for now:

### **1. Update API URL**

Create `frontend/.env.production`:
```env
NEXT_PUBLIC_API_URL=https://your-backend-url.com
```

Or use mock API temporarily:
```env
NEXT_PUBLIC_API_URL=https://jsonplaceholder.typicode.com
```

### **2. Deploy to Vercel**

```bash
cd frontend
vercel --prod
```

---

## 🌐 **Full Stack Deployment Options**

### **Option A: Vercel + Railway**
- **Frontend:** Vercel (free tier)
- **Backend:** Railway (free $5/month credit)
- **Database:** Railway PostgreSQL

### **Option B: Vercel + Render**
- **Frontend:** Vercel
- **Backend:** Render (free tier)
- **Database:** Render PostgreSQL

### **Option C: Vercel + Supabase**
- **Frontend:** Vercel
- **Backend:** Your backend on any platform
- **Database:** Supabase (free tier)

### **Option D: All-in-One (Render/Railway)**
- **Frontend + Backend:** Single platform
- Easier to manage
- Single deployment

---

## 🔄 **Continuous Deployment**

Once connected to GitHub, Vercel automatically:
- ✅ Deploys on every push to `main`
- ✅ Creates preview deployments for PRs
- ✅ Provides unique URLs for each deployment

---

## 📊 **Vercel Features**

- **Automatic HTTPS:** SSL certificates included
- **Global CDN:** Fast worldwide
- **Serverless Functions:** API routes work automatically
- **Preview Deployments:** Every PR gets a URL
- **Analytics:** Built-in performance monitoring

---

## 🐛 **Troubleshooting**

### **Build Fails**

Check build logs in Vercel dashboard. Common issues:

1. **Missing dependencies:**
   ```bash
   # Make sure package.json is complete
   npm install
   ```

2. **TypeScript errors:**
   ```bash
   # Fix type errors locally first
   npm run build
   ```

3. **Environment variables:**
   - Add `NEXT_PUBLIC_API_URL` in Vercel settings

### **API Connection Issues**

1. **CORS:** Make sure backend allows Vercel domain
2. **API URL:** Check environment variable is set correctly
3. **SSL:** Use `https://` not `http://` for production

---

## 📧 **Get Help**

- Vercel Docs: https://vercel.com/docs
- Vercel Discord: https://vercel.com/discord
- Railway Docs: https://docs.railway.app/
- Render Docs: https://render.com/docs

---

## ✅ **Quick Checklist**

Before deploying:

- [ ] Push code to GitHub
- [ ] Create Vercel account
- [ ] Import project to Vercel
- [ ] Set environment variables
- [ ] Deploy backend (Railway/Render)
- [ ] Update `NEXT_PUBLIC_API_URL`
- [ ] Test the deployment

---

**Ready to deploy!** 🚀

Choose your preferred method and follow the steps above.
