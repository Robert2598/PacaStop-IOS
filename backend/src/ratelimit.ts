import type { Env } from './types';

/**
 * Fixed-window rate limiting per authenticated user, backed by Workers KV. Two windows
 * (per-minute burst + per-day cap) as an abuse backstop on top of the auth + premium
 * gates. KV is eventually consistent, so this is a soft cap, not an exact counter —
 * for hard guarantees, move to a Durable Object. Good enough to stop a runaway client.
 */

interface WindowResult {
  allowed: boolean;
  scope?: 'minute' | 'day';
  retryAfter?: number;
}

async function bumpWindow(
  kv: KVNamespace,
  key: string,
  limit: number,
  windowSeconds: number,
): Promise<{ ok: boolean; retryAfter: number }> {
  const now = Math.floor(Date.now() / 1000);
  const windowStart = now - (now % windowSeconds);
  const fullKey = `${key}:${windowStart}`;
  const current = Number((await kv.get(fullKey)) ?? '0');
  if (current >= limit) {
    return { ok: false, retryAfter: windowStart + windowSeconds - now };
  }
  // TTL a little past the window so the key self-expires.
  await kv.put(fullKey, String(current + 1), { expirationTtl: windowSeconds + 5 });
  return { ok: true, retryAfter: 0 };
}

export async function checkRateLimit(env: Env, userId: string): Promise<WindowResult> {
  const perMinute = Number(env.RATE_PER_MINUTE) || 8;
  const perDay = Number(env.RATE_PER_DAY) || 120;

  const minute = await bumpWindow(env.RATE_LIMIT, `rl:min:${userId}`, perMinute, 60);
  if (!minute.ok) return { allowed: false, scope: 'minute', retryAfter: minute.retryAfter };

  const day = await bumpWindow(env.RATE_LIMIT, `rl:day:${userId}`, perDay, 86400);
  if (!day.ok) return { allowed: false, scope: 'day', retryAfter: day.retryAfter };

  return { allowed: true };
}
