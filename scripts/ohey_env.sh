#!/usr/bin/env bash
# Shared public Ohey environment defaults for local scripts.
# Secrets and service-role values must stay in /Users/yota/Projects/Secrets/Ohey
# or CI/Render secrets; do not add them here.

OHEY_DEV_ENV="dev"
OHEY_PRODUCTION_ENV="production"

OHEY_DEV_BACKEND_URL="https://dev-ohey-backend.onrender.com"
OHEY_PRODUCTION_BACKEND_URL="https://ohey-backend.onrender.com"

OHEY_DEV_SUPABASE_URL="https://wwyaftonswgxnjcceyfb.supabase.co"
OHEY_DEV_SUPABASE_PUBLISHABLE_KEY="sb_publishable_pPvKPrOvVmkKQIXKVWj2Rw_DlYkm0Ty"
OHEY_PRODUCTION_SUPABASE_URL="https://pwifgddolctqghygwxwj.supabase.co"
OHEY_PRODUCTION_SUPABASE_PUBLISHABLE_KEY="sb_publishable_pezjPt7pYRECNFdydlon8A_RpSjNulk"

OHEY_DEV_AUTH_REDIRECT_URL="app.ohey.com.dev://login-callback/"
OHEY_PRODUCTION_AUTH_REDIRECT_URL="app.ohey.com://login-callback/"
