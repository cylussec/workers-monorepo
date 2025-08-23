# Multi-Website Worker (Bus & Brew + future sites)

This repo hosts a multi-website platform on Cloudflare Workers. It supports per-domain websites, email collection in Cloudflare D1, campaign sending via MailChannels, and unsubscribe handling. The first site is "Baltimore Bus and Brew Tour".

Key backend entry: `workers/app.ts` (Hono + React Router). Database utilities in `workers/utils/`.

## Local development

Prereqs:
- Node 18+
- Wrangler v3

Install deps:
```
npm install
```

Start dev server (Workers + Vite):
```
npm run dev
```

This serves the Worker at `http://127.0.0.1:8787`. API examples:
- Subscribe: `POST /api/subscribe` with `{ "email": "you@example.com" }`
- List subscribers: `GET /api/subscribers`
- Create campaign: `POST /api/campaigns` with `{ "subject": "Hello", "content": "<h1>Hi</h1>" }`
- Send campaign: `POST /api/campaigns/:id/send`
- Unsubscribe: `GET /u/:token`

Ensure `wrangler.jsonc` has D1 binding and these vars set:
```
{
  "vars": {
    "FROM_EMAIL": "announcements@busandbrew.com",
    "REPLY_TO_EMAIL": "hello@busandbrew.com",
    "MAILCHANNELS_URL": "https://api.mailchannels.net/tx/v1/send"
  }
}
```

## Database schema (Cloudflare D1)

Schema file: `schema.sql`

Create/Update locally:
```
wrangler d1 execute multi-website-db --local --file=./schema.sql
```

Create/Update in Cloudflare:
```
wrangler d1 execute multi-website-db --file=./schema.sql
```

Notes:
- `schema.sql` includes `ALTER TABLE` for `unsubscribe_token` and a unique index.
- `websites` table seeds `busandbrew.com` and `busandbrew.brianseel.com`.

## Database setup per environment (staging and production)

Use separate D1 databases for each environment to isolate data.

1) Create the databases (one-time)
- Staging:
  - `wrangler d1 create multi-website-db-staging`
- Production:
  - `wrangler d1 create multi-website-db-prod`

2) Update `wrangler.jsonc` with real IDs
- Copy each DB UUID via `wrangler d1 list` or the Cloudflare dashboard.
- Set:
  - `env.staging.d1_databases[0].database_id = "<staging UUID>"`
  - `env.production.d1_databases[0].database_id = "<prod UUID>"`

3) Initialize schema (remote)
- Staging:
  - `wrangler d1 execute multi-website-db-staging --env=staging --file=./schema.sql --remote`
- Production:
  - `wrangler d1 execute multi-website-db-prod --env=production --file=./schema.sql --remote`

4) Verify
- Staging:
  - `wrangler d1 execute multi-website-db-staging --env=staging --command "SELECT * FROM websites" --remote`
- Production:
  - `wrangler d1 execute multi-website-db-prod --env=production --command "SELECT * FROM websites" --remote`

5) CI deploys (recommended)
- On `staging` branch, run the schema apply for `multi-website-db-staging` before `wrangler deploy --env staging`.
- On `main`, run the schema apply for `multi-website-db-prod` before `wrangler deploy --env production`.

## Deployment

Preview (no DNS):
```
wrangler dev
```

Deploy to Cloudflare:
```
wrangler deploy
```

After deploy, you'll get a Workers URL like `https://<worker-name>.<subdomain>.workers.dev`.

## CI/CD: main and staging branches

- Branches:
  - `staging` → deploys to Wrangler env `staging`
  - `main` → deploys to Wrangler env `production`
- Workflow: `.github/workflows/deploy.yml`
- Required GitHub Secrets:
  - `CLOUDFLARE_ACCOUNT_ID`
  - `CLOUDFLARE_API_TOKEN`
- `wrangler.jsonc` must have valid D1 `database_id` values for both envs.

### GitHub branch protection (recommended)
1. Create `staging` branch from `main`.
2. Settings → Branches → Add protection rule for `staging` and `main`:
   - Require pull request before merging
   - Require status checks to pass (select the deploy workflow checks)
   - Require approvals (e.g., 1)
   - Restrict who can push (no direct pushes)

### Typical flow
- Open PR → `staging` → merge → auto-deploys to staging
- Validate → open PR from `staging` to `main` → merge → auto-deploys to prod

## Connect your domain in Cloudflare Dashboard

1. Create/Select a zone for your domain (e.g., `busandbrew.com`).
2. Add a Worker route in the domain’s "Workers Routes" section:
   - Route: `busandbrew.com/*` → Service: this Worker
   - Optionally add `www.busandbrew.com/*`
3. If you prefer DNS, set an `A` or `CNAME` is not needed for Workers routes; Workers run at the edge via routes.
4. If you use a custom hostname under another domain (e.g., `busandbrew.brianseel.com`), add a route for that hostname as well.
5. Ensure sender domain DNS is configured for email:
   - SPF: include MailChannels via `v=spf1 include:relay.mailchannels.net -all`
   - DKIM: create TXT per MailChannels guidance
   - DMARC: recommend a basic policy `v=DMARC1; p=none; rua=mailto:postmaster@yourdomain`
6. In `wrangler.jsonc`, set `FROM_EMAIL` at that domain and deploy.

## Multi-website routing

The worker looks up the `Host` header via `WebsiteRouter` and maps it to a `websites` row. Add new sites by inserting into `websites` and serving content based on `website.domain` or additional config.

## Files of interest
- `workers/app.ts` — Worker entry, API routes, unsubscribe, campaign sending
- `workers/utils/database.ts` — D1 data access and business logic
- `workers/utils/mailer.ts` — MailChannels sending
- `workers/utils/website-router.ts` — Domain→website lookup
- `workers/types.ts` — Shared types and env bindings
- `schema.sql` — Database schema and seeds

## Admin and templates (next)
- Admin UI protected by Cloudflare Access
- HTML email wrapper with per-site branding

See `specs/01-spec-multi-website-worker-bus-and-brew.md` for the engineering spec and task breakdown.
