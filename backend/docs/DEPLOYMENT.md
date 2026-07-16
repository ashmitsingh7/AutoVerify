# Deployment Guide

## Honesty note up front

This sandbox has no Docker daemon and no Railway account, so **the Docker
build and the Railway deployment described below have not been executed or
verified from here** - only written correctly against documented conventions
for both. Build and test the image locally before trusting it in production.
Everything in `backend/` (the actual FastAPI service) *has* been run and
tested in this sandbox - see `backend/README.md`'s testing section.

## Local Docker

Build context is the **repo root** (`autoverify/`), not `backend/`, because the image needs both the Perl Core and the Python backend:

```bash
cd autoverify
docker build -t autoverify-api -f Dockerfile .
docker run -p 8000:8000 autoverify-api
curl http://localhost:8000/health
```

## Railway

Railway's Docker-based deploy will build from the `Dockerfile` at the repo root and inject a `$PORT` environment variable, which the image's `CMD` already reads (`uvicorn ... --port ${PORT}`, defaulting to 8000 if unset).

Steps (standard Railway Docker-service flow - not run against a live Railway project from this sandbox):

1. Push this repository to GitHub.
2. In Railway: New Project -> Deploy from GitHub repo.
3. Railway auto-detects the `Dockerfile` at the repo root; no build command override needed.
4. Set the service's root/build context to the repo root if Railway asks (it should infer this from the Dockerfile's `COPY` paths).
5. `PORT` is supplied by Railway automatically. Set `AUTOVERIFY_ALLOWED_ORIGINS` to your deployed frontend's origin (e.g. `https://your-app.vercel.app`, comma-separated if there's more than one) so the browser-facing CORS check passes - it defaults to `localhost:3000` only, which is correct for local dev but will block the deployed frontend if left unset.
6. After deploy, verify `GET /health` on the assigned Railway domain returns `{"status": "ok"}`.

### Things to check once actually deployed (can't check from here)

- Perl's `JSON::PP` is part of core Perl on Debian's `perl` package (verified locally in this sandbox), but confirm the Railway build log shows it resolving without a CPAN fetch - if it doesn't, the Dockerfile's `apt-get install perl` step needs adjusting for whatever base image Railway's builder actually uses.
- Job directories (`backend/app/jobs/`) live on the container's ephemeral filesystem. Railway containers can be restarted/rescheduled, which would drop in-flight jobs - fine for a "generate then download promptly" workflow, not fine if you need job history to survive a redeploy. If that's needed later, that's a real architecture change (external storage), not a Dockerfile tweak.
- The bridge subprocess's 30s timeout (see backend README) applies per-request regardless of host - if Railway's proxy has a shorter request timeout than 30s, a slow generate could get cut off at the proxy before the bridge's own timeout fires.
