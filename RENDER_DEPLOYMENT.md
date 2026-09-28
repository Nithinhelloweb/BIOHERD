# 🚀 Deploying BIOHERD on Render

This guide walks you step-by-step through hosting the **BIOHERD Livestock Bio-Surveillance & Herd Health System** on [Render](https://render.com).

---

## 📋 Architecture & Highlights

- **Backend**: FastAPI (Python 3.11/3.12) with asynchronous SQLAlchemy and Uvicorn.
- **Zero-Failure Architecture**:
  - Automatically translates Render's default `postgres://` URLs into `postgresql+asyncpg://`.
  - Automatically initializes database tables (`Base.metadata.create_all`) and seeds the 36 Maharashtra districts on startup.
  - Resilient in-memory fallbacks if Redis or MinIO are not configured on free cloud tiers.
- **Frontend (Flutter)**: Pre-configured to accept the deployed Render API URL via compile-time `--dart-define`.

---

## 🌟 Choose Your Deployment Method

| Method | Effort | Best For |
|---|---|---|
| **[Method 1: Render Blueprint (`render.yaml`)](#-method-1-1-click-render-blueprint-recommended)** | ⚡ 1 Click | Fastest and least manual configuration |
| **[Method 2: Manual Dashboard Setup](#-method-2-manual-web-service-setup)** | 🛠️ 3 Minutes | Step-by-step control via Render UI |
| **[Method 3: Docker Deployment](#-method-3-docker-deployment)** | 🐳 2 Minutes | Guaranteed container consistency |

---

## ⚡ Method 1: 1-Click Render Blueprint (Recommended)

BIOHERD includes a pre-configured [render.yaml](file:///d:/HACKTHON/SIH/BIOHERD/BIOV1/render.yaml) at the repository root.

1. **Push your code to GitHub / GitLab**.
2. Log into the [Render Dashboard](https://dashboard.render.com).
3. Click the **"New +"** button at the top right and select **"Blueprint"**.
4. Connect your `BIOHERD` repository.
5. Render will automatically detect `render.yaml` and configure:
   - **Service Name**: `bioherd-api`
   - **Root Directory**: `backend`
   - **Build Command**: `pip install --upgrade pip && pip install -r requirements.txt`
   - **Start Command**: `uvicorn app.main:app --host 0.0.0.0 --port $PORT --proxy-headers --forwarded-allow-ips='*'`
   - **Auto-generated `SECRET_KEY`** and production environment settings.
6. Click **"Apply"**.
7. Wait 2–3 minutes for the build to finish. Your API will be live at `https://bioherd-api.onrender.com`!

---

## 🛠️ Method 2: Manual Web Service Setup

If you prefer to configure the service manually via the Render UI:

1. In [Render Dashboard](https://dashboard.render.com), click **"New +"** → **"Web Service"**.
2. Select **"Build and deploy from a Git repository"** and pick your repository.
3. Fill in the following settings:

| Field | Value |
|---|---|
| **Name** | `bioherd-api` (or your choice) |
| **Region** | `Oregon (US West)` or `Singapore (Southeast Asia)` |
| **Branch** | `main` (or your active branch) |
| **Root Directory** | `backend` |
| **Runtime** | `Python 3` |
| **Build Command** | `pip install --upgrade pip && pip install -r requirements.txt` |
| **Start Command** | `uvicorn app.main:app --host 0.0.0.0 --port $PORT --proxy-headers --forwarded-allow-ips='*'` |
| **Instance Type** | `Free` |

4. Scroll down to **Environment Variables** and add:

| Key | Recommended Value | Notes |
|---|---|---|
| `PYTHON_VERSION` | `3.11.9` | Ensures exact Python runtime |
| `ENVIRONMENT` | `production` | Enables production log formatting |
| `DEBUG` | `false` | Disables debug stack traces |
| `SECRET_KEY` | *(Click "Generate" or enter random string)* | Used for JWT signing |
| `CORS_ORIGINS` | `*` | Allows calls from Flutter web/mobile |
| `DATABASE_URL` | `sqlite+aiosqlite:///./bioherd_prod.db` | Or your PostgreSQL connection string |

5. Click **"Create Web Service"**.

---

## 🐳 Method 3: Docker Deployment

Render also natively supports Docker using the provided [backend/Dockerfile](file:///d:/HACKTHON/SIH/BIOHERD/BIOV1/backend/Dockerfile) or root [Dockerfile](file:///d:/HACKTHON/SIH/BIOHERD/BIOV1/Dockerfile).

1. In Render Dashboard, click **"New +"** → **"Web Service"**.
2. Connect your repository.
3. Set **Runtime** to **"Docker"**.
4. If using repository root:
   - **Dockerfile Path**: `backend/Dockerfile` (or `./Dockerfile`)
   - **Docker Context**: `backend` (or `./`)
5. Add the same Environment Variables as in Method 2 (`SECRET_KEY`, `CORS_ORIGINS=*`, etc.).
6. Click **"Create Web Service"**.

---

## 🗄️ Database Configuration Options

### Option A: Built-in SQLite (Zero Setup — Best for Demo & Hackathons)
- By default, BIOHERD creates an asynchronous SQLite database `bioherd_prod.db`.
- **Note**: Render Free Web Services have an ephemeral filesystem (data resets when the server spins down or redeploys).

### Option B: Render Managed PostgreSQL
1. On Render, click **"New +"** → **"PostgreSQL"**.
2. Name it `bioherd-postgres`, select `Free` plan, and click **"Create Database"**.
3. Copy the **Internal Database URL** (e.g., `postgres://user:pass@dpg-xxx:5432/bioherd_db`).
4. In your `bioherd-api` Web Service, add or update the `DATABASE_URL` environment variable with this URL.
   > **Note**: BIOHERD automatically translates `postgres://` or `postgresql://` into `postgresql+asyncpg://` so it works out of the box!

### Option C: External PostgreSQL (Neon / Supabase — Permanent Free Tiers)
1. Create a free PostgreSQL instance on [Neon](https://neon.tech) or [Supabase](https://supabase.com).
2. Copy the connection string.
3. Set `DATABASE_URL` in Render. If it starts with `postgresql://`, BIOHERD will auto-convert it.

---

## 📱 Connecting the Flutter Client to Render

Once your Render backend is deployed, you will have a live URL such as:
```
https://bioherd-api.onrender.com
```

### 1. Run Flutter Locally Pointing to Render API
```bash
flutter run -d chrome \
  --dart-define=API_BASE_URL=https://bioherd-api.onrender.com/api/v1 \
  --dart-define=AUTH_API_BASE_URL=https://bioherd-api.onrender.com/api/v1/auth
```

### 2. Build Flutter Web Release
```bash
flutter build web --release \
  --dart-define=API_BASE_URL=https://bioherd-api.onrender.com/api/v1 \
  --dart-define=AUTH_API_BASE_URL=https://bioherd-api.onrender.com/api/v1/auth
```

### 3. Deploy Flutter Web as a Render Static Site (Optional)
You can host the Flutter Web frontend for free on Render as a **Static Site**:
1. Run `flutter build web --release ...`
2. Push or upload the `build/web` directory.
3. In Render, click **"New +"** → **"Static Site"**.
4. Set **Publish Directory** to `build/web`.
5. Under **Rewrites and Redirects**, add:
   - Source: `/*`
   - Destination: `/index.html` (Action: `Rewrite`)

---

## 🧪 Post-Deployment Verification Checklist

Once your Render service status turns to **"Live"**:

1. **Verify Root Endpoint**:
   Visit `https://<your-render-subdomain>.onrender.com/` in your browser. You should see:
   ```json
   {
     "project": "BIOHERD",
     "status": "online",
     "version": "1.0.0",
     "api_docs": "/docs"
   }
   ```

2. **Interactive API Documentation (Swagger)**:
   Visit `https://<your-render-subdomain>.onrender.com/docs` to test endpoints interactively.

3. **Check System Health**:
   Visit `https://<your-render-subdomain>.onrender.com/api/v1/health` to view database connectivity and service telemetry.

4. **Verify Pre-Seeded Maharashtra Districts**:
   Send a GET request to:
   `https://<your-render-subdomain>.onrender.com/api/v1/districts`
   All 36 Maharashtra districts (Pune, Nashik, Ahmednagar, Satara, etc.) will be pre-populated.

5. **Test Pre-Seeded Demo Login**:
   - Endpoint: `POST /api/v1/auth/login`
   - Demo Farmer:
     - Phone: `9876543210`
     - Password: `Password@123`

---

## 💡 Render Free Tier Tips

- **Cold Starts**: Render's free tier spins down web services after 15 minutes of inactivity. The first request after spin-down may take ~30–50 seconds to boot up. Subsequent requests respond in milliseconds.
- **Keep-Alive (Optional)**: You can set up a free uptime monitor (e.g., [Cron-Job.org](https://cron-job.org) or [UptimeRobot](https://uptimerobot.com)) to ping `https://<your-app>.onrender.com/api/v1/health/liveness` every 10 minutes to prevent cold starts during hackathon demonstrations!
