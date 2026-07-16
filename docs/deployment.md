# Deployment Guide

AutoVerify deploys as two independent services: the **frontend** on Vercel
and the **backend** on Railway (or any Docker-friendly host). They only need
to know one thing about each other - the backend's public URL - which is
passed to the frontend as an environment variable.

## Backend (Railway)

The backend's `Dockerfile` builds from the `backend/` directory root and
bundles both the Perl core (`lib/`, `bin/`) and the FastAPI service
(`backend/`), since the API calls the Perl bridge as a subprocess at
runtime.

```bash
cd backend
docker build -t autoverify-api -f Dockerfile .
docker run -p 8000:8000 autoverify-api
curl http://localhost:8000/health
```

Steps for Railway:

1. Push this repository to GitHub.
2. In Railway: **New Project → Deploy from GitHub repo**.
3. Point Railway's service root at the `backend/` directory so it finds the `Dockerfile` there.
4. Railway supplies a `$PORT` environment variable automatically; the image's `CMD` already reads it (`uvicorn ... --port ${PORT}`, defaulting to `8000` if unset).
5. Set `AUTOVERIFY_ALLOWED_ORIGINS` to your deployed frontend's origin (e.g. `https://your-app.vercel.app`) so CORS allows the browser to call the API. It defaults to `localhost:3000` only, which is correct for local development but will block a deployed frontend if left unset.
6. After deploy, confirm `GET /health` on the assigned Railway domain returns `{"status": "ok"}`.

### Things worth checking after a real deploy

- Confirm the build image resolves Perl's `JSON::PP` (part of core Perl on Debian-based images) without an extra CPAN fetch.
- Job directories (`backend/app/jobs/`) live on the container's ephemeral filesystem. A Railway restart or redeploy drops any in-flight jobs - acceptable for a "generate, then download promptly" workflow, but not a substitute for persistent storage if job history ever needs to survive a redeploy.
- The bridge subprocess's 30-second timeout applies per request; if a host's proxy timeout is shorter than that, a slow generate could be cut off before the bridge's own timeout fires.

## Frontend (Vercel)

```bash
cd frontend
pnpm install   # or npm install
pnpm build     # or npm run build
```

Steps for Vercel:

1. Import the repository into Vercel and set the project's **root directory** to `frontend/`.
2. Vercel auto-detects the Next.js framework preset; no build command override is needed.
3. Set the environment variable `NEXT_PUBLIC_API_URL` to the deployed backend's URL (e.g. `https://autoverify-api.up.railway.app`).
4. Deploy. Vercel rebuilds automatically on every push to the connected branch.

## Local development (both services)

```bash
# Terminal 1 - backend
cd backend/backend
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000

# Terminal 2 - frontend
cd frontend
cp .env.local.example .env.local   # NEXT_PUBLIC_API_URL=http://localhost:8000
pnpm install
pnpm dev
```

Visit `http://localhost:3000` for the UI and `http://localhost:8000/docs`
for the backend's interactive OpenAPI documentation.

## Notes

- The Docker build and Railway deployment steps above follow the documented conventions of each platform; validate them against a live Railway project before relying on them in production, same as with any new deployment target.
- No authentication or rate-limiting is configured on the backend - add both before exposing it beyond a local or trusted-network context.
