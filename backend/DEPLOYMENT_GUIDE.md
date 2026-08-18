# 🚀 KamJodo Backend Deployment Guide

Backend ko live publish karne ke liye sabse easy aur popular free options niche diye gaye hain:

---

## Option 1: Render.com (Recommended — 100% Free & Easy)

1. **GitHub pe project push karo:**
   - GitHub pe naya repository banao aur code push kar do.
2. **Render Dashboard pe jao:**
   - [render.com](https://render.com) pe login karo.
   - **New +** ➔ **Web Service** select karo.
   - Apne GitHub repository ko connect karo.
3. **Settings fill karo:**
   - **Name**: `kamjodo-backend`
   - **Root Directory**: `backend`
   - **Environment**: `Node`
   - **Build Command**: `npm install`
   - **Start Command**: `node server.js`
   - **Plan**: `Free`
4. **Environment Variables add karo:**
   - `NODE_ENV`: `production`
   - `JWT_SECRET`: `your_random_secret_key_123`
   - `CORS_ORIGIN`: `*`
   - `MONGODB_URI`: (MongoDB Atlas URI if available, or leave blank for local store)
5. **Deploy**: **Create Web Service** pe click karo. Render aapko live URL de dega (e.g. `https://kamjodo-backend.onrender.com`).

---

## Option 2: Railway.app (Fastest Deployment)

1. [railway.app](https://railway.app) pe login karo with GitHub.
2. **New Project** ➔ **Deploy from GitHub repo** ➔ Select `KamJodo` repository.
3. Set **Root Directory** to `/backend`.
4. Railway automatically detect kar lega `node server.js`.
5. **Variables** tab me environment variables add karo (`JWT_SECRET`, `CORS_ORIGIN=*`).
6. **Generate Domain** pe click karo ➔ Live URL mil jayegi!

---

## Option 3: Vercel (Serverless)

1. [vercel.com](https://vercel.com) pe login karo.
2. **Add New Project** ➔ Import `KamJodo` repository.
3. Root Directory: `backend`.
4. Environment variables add karo.
5. Deploy button press karo.

---

## 📱 Mobile App (Flutter) me Live URL Update Karna

Backend deploy hone ke baad jo Live URL milega (e.g. `https://kamjodo-backend.onrender.com`), usko standard config file me change karo:

### `frontend/lib/services/auth_service.dart` & `frontend_cap/lib/services/auth_service.dart`:
```dart
static String get baseUrl {
  if (kReleaseMode) return 'https://kamjodo-backend.onrender.com';
  // ... local dev urls
}
```
