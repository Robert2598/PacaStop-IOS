import { createRemoteJWKSet, jwtVerify } from 'jose';
import type { Env } from './types';

/**
 * Verifies a Clerk session JWT against Clerk's JWKS. The token is minted on-device by
 * ClerkKit (`session.getToken()`), sent as `Authorization: Bearer <jwt>`, and proves the
 * caller is a real signed-in user before we ever touch the Anthropic key.
 */

// One JWKS set per issuer, cached across requests (jose caches the keys internally).
let jwks: ReturnType<typeof createRemoteJWKSet> | null = null;

function getJwks(env: Env) {
  if (!jwks) jwks = createRemoteJWKSet(new URL(env.CLERK_JWKS_URL));
  return jwks;
}

export interface AuthResult {
  userId: string;
}

export async function verifyClerkToken(token: string, env: Env): Promise<AuthResult> {
  const { payload } = await jwtVerify(token, getJwks(env), {
    issuer: env.CLERK_ISSUER,
  });
  if (!payload.sub) throw new Error('token missing subject');
  return { userId: payload.sub };
}

export function bearerToken(header: string | undefined | null): string | null {
  if (!header) return null;
  const m = /^Bearer\s+(.+)$/i.exec(header.trim());
  return m ? m[1] : null;
}
