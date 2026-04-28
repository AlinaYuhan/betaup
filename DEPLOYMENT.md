# BetaUp Deployment Guide

## Recommended Architecture

- `frontend/` deploy to Vercel
- `backend/` deploy to Railway or Render
- MySQL deploy to Railway MySQL, Aiven, PlanetScale, or a self-managed cloud database

This project also contains:

- root `index.html`: process portfolio / static page
- `mobile_flutter/`: Flutter client

If your goal is to publish the working web app, deploy `frontend/` and `backend/`.

## 1. Backend Deployment

### Stack

- Java 21
- Spring Boot 3.5
- Maven wrapper included

### Required environment variables

- `SPRING_PROFILES_ACTIVE=mysql`
- `BETAUP_DB_URL=jdbc:mysql://<host>:3306/<db>?useSSL=false&serverTimezone=UTC&allowPublicKeyRetrieval=true`
- `BETAUP_DB_USERNAME=<username>`
- `BETAUP_DB_PASSWORD=<password>`
- `BETAUP_JWT_SECRET=<long-random-secret-at-least-32-chars>`

### Recommended environment variables

- `BETAUP_CORS_ALLOWED_ORIGIN_PATTERNS=https://your-frontend-domain.vercel.app,https://your-custom-domain.com`
- `BETAUP_UPLOAD_DIR=/data/uploads`
- `BETAUP_DEEPSEEK_API_KEY=<your-deepseek-key>`
- `BETAUP_DEEPSEEK_ENDPOINT=https://api.deepseek.com/v1/chat/completions`
- `BETAUP_DEEPSEEK_MODEL=deepseek-chat`
- `AMAP_JS_KEY=<your-amap-js-key>`
- `AMAP_JS_SECURITY_CODE=<your-amap-js-security-code>`
- `AMAP_WEB_SERVICE_KEY=<your-amap-web-service-key>`

### Build / start commands

- Build: `./mvnw clean package -DskipTests`
- Start: `java -jar target/betaup-backend-0.0.1-SNAPSHOT.jar`

### Notes

- The app now reads `PORT` automatically, which most cloud platforms inject.
- Uploaded images are stored on local disk. On platforms with ephemeral filesystem, files may disappear after redeploy or restart.
- For a demo deployment, use a platform persistent volume or object storage later if needed.

## 2. Frontend Deployment

### Stack

- React
- Vite

### Required environment variable

- `VITE_API_BASE_URL=https://your-backend-domain/api`

### Vercel settings

- Framework Preset: `Vite`
- Root Directory: `frontend`
- Build Command: `npm run build`
- Output Directory: `dist`

`frontend/vercel.json` has been added so React Router refreshes correctly.

## 3. Recommended Order

1. Deploy MySQL
2. Deploy backend and verify `https://your-backend-domain/swagger-ui.html`
3. Deploy frontend with `VITE_API_BASE_URL`
4. Update backend `BETAUP_CORS_ALLOWED_ORIGIN_PATTERNS` to the real frontend domain
5. Re-test login, posting, uploads, and map features

## 4. Quick Verification Checklist

- Backend health: open `https://your-backend-domain/swagger-ui.html`
- Frontend can register and login
- Browser console has no CORS errors
- Requests are sent to the production backend, not `localhost:8080`
- Media upload works after a redeploy

## 5. Suggested Platform Pairing

For the lowest setup cost:

- frontend: Vercel
- backend: Railway
- database: Railway MySQL

If you want, the next step can be:

1. I directly add a `render.yaml` / `railway.json` for one target platform
2. I can also prepare a copy-paste-ready production environment variable checklist for frontend and backend
