import type { Env } from './types';

/**
 * Server-side premium gate (RevenueCat API **V2**). The client's own "isSubscribed" flag is
 * tamperable, so when REQUIRE_PREMIUM is on we confirm the customer has an active entitlement
 * straight from RevenueCat, keyed by the Clerk user id.
 *
 * V2 (not V1): the app's secret key is a V2 key, and V1 rejects it (error 7723). V2 keys the
 * request by project, so REVENUECAT_PROJECT_ID (proj…) is required alongside the key.
 *
 * Assumptions:
 *  - The app identifies RevenueCat with the Clerk user id (`Purchases.logIn(clerkUserId)` after
 *    sign-in), so the customer_id below is that same id.
 *  - PacaStop sells a single entitlement (`premium`), so ANY active entitlement means premium.
 *    If more entitlements are ever added, match on the specific one here.
 * If RevenueCat isn't configured, set REQUIRE_PREMIUM=false and rely on the client gate + rate limiting.
 */
export async function hasPremium(env: Env, userId: string): Promise<boolean> {
  if (!env.REVENUECAT_SECRET_KEY || !env.REVENUECAT_PROJECT_ID) return false;

  const url =
    `https://api.revenuecat.com/v2/projects/${encodeURIComponent(env.REVENUECAT_PROJECT_ID)}` +
    `/customers/${encodeURIComponent(userId)}/active_entitlements`;

  const res = await fetch(url, {
    headers: {
      Authorization: `Bearer ${env.REVENUECAT_SECRET_KEY}`,
      'Content-Type': 'application/json',
    },
  });

  if (!res.ok) {
    // Failures only (not per request): a non-2xx here is a config problem, not "no premium".
    console.log(`premium check: RevenueCat v2 http ${res.status}`);
    return false;
  }

  const body = (await res.json()) as {
    items?: Array<{ entitlement_id?: string; expires_at?: number | null }>;
  };
  const now = Date.now();
  // `active_entitlements` already returns only active ones; guard on expiry defensively
  // (null expires_at = non-expiring, e.g. lifetime). PacaStop sells a single entitlement,
  // so ANY active entitlement means premium.
  return (body.items ?? []).some((it) => it.expires_at == null || it.expires_at > now);
}
