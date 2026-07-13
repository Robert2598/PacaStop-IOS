import { Hono } from 'hono';
import { streamSSE } from 'hono/streaming';
import type { Env, ChatTurn, Risk } from './types';
import { bearerToken, verifyClerkToken } from './auth';
import { checkRateLimit } from './ratelimit';
import { hasPremium } from './premium';
import { sanitizeContext } from './context';
import { classifyRisk, streamReply, parseTextDeltas } from './anthropic';
import { SYSTEM_PROMPT, buildContextBlock } from './prompt';

const app = new Hono<{ Bindings: Env }>();

const MAX_MESSAGE = 4000;
const MAX_HISTORY = 16;

app.get('/health', (c) => c.json({ ok: true, service: 'pacastop-ai-proxy' }));

function actionsFor(risk: Risk): string[] {
  if (risk === 'crisis') return ['helpline', 'panic'];
  if (risk === 'elevated') return ['panic'];
  return [];
}

app.post('/v1/chat', async (c) => {
  const env = c.env;

  // ── 1. Auth ────────────────────────────────────────────────────────────────
  let userId = 'anon';
  if (env.REQUIRE_AUTH !== 'false') {
    const token = bearerToken(c.req.header('Authorization'));
    if (!token) return c.json({ error: 'missing_token' }, 401);
    try {
      ({ userId } = await verifyClerkToken(token, env));
    } catch {
      return c.json({ error: 'invalid_token' }, 401);
    }
  } else {
    // Dev mode: derive a stable id from the token if present, else "anon".
    userId = bearerToken(c.req.header('Authorization'))?.slice(0, 24) ?? 'anon';
  }

  // ── 2. Rate limit ────────────────────────────────────────────────────────────
  const rl = await checkRateLimit(env, userId);
  if (!rl.allowed) {
    c.header('Retry-After', String(rl.retryAfter ?? 60));
    return c.json({ error: 'rate_limited', scope: rl.scope }, 429);
  }

  // ── 3. Premium gate ──────────────────────────────────────────────────────────
  if (env.REQUIRE_PREMIUM === 'true') {
    try {
      if (!(await hasPremium(env, userId))) {
        return c.json({ error: 'premium_required' }, 403);
      }
    } catch {
      return c.json({ error: 'premium_check_failed' }, 502);
    }
  }

  // ── 4. Parse + privacy-guard the body ────────────────────────────────────────
  let message: string;
  let history: ChatTurn[];
  let ctx;
  try {
    const body = (await c.req.json()) as Record<string, unknown>;
    message = String(body.message ?? '').slice(0, MAX_MESSAGE).trim();
    if (!message) return c.json({ error: 'empty_message' }, 400);

    const rawHistory = Array.isArray(body.history) ? body.history : [];
    history = rawHistory
      .filter(
        (t): t is ChatTurn =>
          !!t &&
          typeof (t as ChatTurn).content === 'string' &&
          ((t as ChatTurn).role === 'user' || (t as ChatTurn).role === 'assistant'),
      )
      .slice(-MAX_HISTORY)
      .map((t) => ({ role: t.role, content: t.content.slice(0, MAX_MESSAGE) }));

    ctx = sanitizeContext(body.context); // throws if any financial field is present
  } catch (e) {
    const msg = e instanceof Error ? e.message : 'bad_request';
    return c.json({ error: 'bad_request', detail: msg }, 400);
  }

  // ── 5. Crisis classification (cheap Haiku) ───────────────────────────────────
  const risk = await classifyRisk(env, message);

  // ── 6. Stream the reply ──────────────────────────────────────────────────────
  return streamSSE(c, async (stream) => {
    // Meta first so the app can render crisis UI immediately.
    await stream.writeSSE({ event: 'meta', data: JSON.stringify({ risk, actions: actionsFor(risk) }) });

    try {
      const upstream = await streamReply(
        env,
        SYSTEM_PROMPT,
        buildContextBlock(ctx, risk),
        history,
        message,
      );
      if (!upstream.ok || !upstream.body) {
        await stream.writeSSE({ event: 'error', data: JSON.stringify({ error: 'upstream', status: upstream.status }) });
        return;
      }
      for await (const delta of parseTextDeltas(upstream)) {
        if (delta) await stream.writeSSE({ event: 'delta', data: JSON.stringify({ text: delta }) });
      }
      await stream.writeSSE({ event: 'done', data: '{}' });
    } catch {
      await stream.writeSSE({ event: 'error', data: JSON.stringify({ error: 'stream_failed' }) });
    }
  });
});

export default app;
