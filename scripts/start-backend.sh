#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

echo "==> Starting local Supabase (Docker required)..."
supabase start

echo "==> Applying migrations..."
supabase db reset --yes

echo ""
echo "==> Local backend is ready."
supabase status

echo ""
echo "Run edge functions in another terminal:"
echo "  cd \"$ROOT\" && supabase functions serve"
echo ""
echo "Run Flutter against local Supabase (defaults to 127.0.0.1:54321):"
echo "  cd \"$ROOT/flutter_app\" && flutter run"
