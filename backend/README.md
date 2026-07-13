# PacaStop AI Mentor — Proxy

A thin, stateless edge proxy (Cloudflare Workers + Hono) that stands between the iOS app
and Anthropic. It exists so the **Anthropic API key never ships in the app** and so we can
enforce auth, premium, rate limits, and the privacy invariant in one trusted place.

## What it does per request (`POST /v1/chat`, streams SSE)

1. **Verifies the Clerk session JWT** (`Authorization: Bearer <jwt>`, checked against Clerk's JWKS).
2. **Rate-limits** per user (per-minute burst + per-day cap, Workers KV backstop).
3. **Confirms premium** server-side via RevenueCat REST (the `premium` entitlement).
4. **Rejects any financial data** in the payload — a hard invariant (`src/context.ts`). The
   mentor only ever receives non-financial progress (streak, cravings beaten, relapses,
   car tier, badges, language). No loss amount, no savings, not even a rounded band.
5. **Classifies crisis risk** with a cheap Haiku call → emits a `meta` event so the app can
   surface the helpline / panic button.
6. **Streams the reply** from Sonnet 4.6, with the big persona + knowledge-base system
   prompt **prompt-cached** (≈0.1× after the first call). Zero conversation storage — history
   lives on-device.

Wire events the app receives: `meta` `{risk, actions}` → `delta` `{text}` … → `done`, or `error`.

## Cost controls

- **Prompt caching** on the stable system+KB prefix (identical for every user → global cache hit).
- **Model routing**: Haiku 4.5 classifier + Sonnet 4.6 responder; `max_tokens` capped at 1024.
- **History capped** to the last 16 turns by the app and re-capped here.

## Configure & deploy

```bash
cd backend
npm install

# 1. Rate-limit KV namespace — paste the id into wrangler.toml
npx wrangler kv:namespace create RATE_LIMIT

# 2. Secrets (never committed)
npx wrangler secret put ANTHROPIC_API_KEY        # sk-ant-...  (server-only)
npx wrangler secret put REVENUECAT_SECRET_KEY    # sk_...  (only if REQUIRE_PREMIUM=true)

# 3. Confirm the Clerk issuer/JWKS in [vars] match your instance (clerk.paca-stop.ro)

npm run deploy
```

Then set `AI_BACKEND_URL` in the app's `Secrets.plist` to the deployed Worker URL
(e.g. `https://pacastop-ai-proxy.<subdomain>.workers.dev`).

### Local dev

```bash
cp .dev.vars.example .dev.vars   # add your ANTHROPIC_API_KEY
# in wrangler.toml set REQUIRE_AUTH=false, REQUIRE_PREMIUM=false to skip gates
npm run dev
```

## Premium identity note

The premium check keys RevenueCat by the **Clerk user id**. For it to work, the app must
identify RevenueCat with that id (`Purchases.logIn(clerkUserId)` after sign-in). If you
don't wire that, set `REQUIRE_PREMIUM=false` and rely on the client gate + rate limiting.

## Production hardening (follow-ups)

- Swap the KV fixed-window limiter for a **Durable Object** if you need exact limits.
- Add **rolling summarization** of old turns to keep long conversations cheap.
- Keep request-body logging **off** (it's off here) so no message content is ever retained.
