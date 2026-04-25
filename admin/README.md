# Fasto VPN Admin

## Setup
```bash
cd admin
cp .env.example .env.local
npm install
npm run dev
```

Open: `http://localhost:3000`

## Required backend
- Backend should run at `http://localhost:4000`
- Admin BFF will proxy to `${BACKEND_URL}/api/v1/admin/*`

## Build
```bash
npm run build
npm run start
```
