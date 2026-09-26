# Lucky Web — Deployment

## Local

```bash
npm install
npm run dev
```

Use the exact Vite URL printed in the terminal, usually `http://localhost:5173/`.

## Supabase

1. Create/open the Supabase project.
2. Run `supabase/migrations/001_luckyweb_demo.sql` in SQL Editor.
3. Copy `.env.example` to `.env`.
4. Fill `VITE_SUPABASE_URL` and `VITE_SUPABASE_PUBLISHABLE_KEY`.
5. Restart Vite after changing `.env`.

Only the public/publishable key belongs in the frontend. Never put a service-role key in `.env` used by Vite.

## Production build

```bash
npm run build
```

Deploy the `dist/` folder to a static host. Configure the same two Vite environment variables in the hosting provider.

## SPA routing

The current demo keeps navigation in the client and does not require server-side routes. If real URL routes are added later, configure the host to rewrite unknown paths to `index.html`.
