import type { RecoveryContext, Language } from './types';

/**
 * Hard privacy invariant: the mentor must never receive anything about money —
 * not the loss amount, not savings, not a rounded band. This rejects any payload
 * that tries to smuggle a financial field in, so a client bug can never leak it.
 */
const FORBIDDEN_KEYS = [
  'amount',
  'amountPerSession',
  'saved',
  'savings',
  'lifetimeSaved',
  'money',
  'lei',
  'balance',
  'ratePerSecond',
  'yearlyLoss',
  'weeklyLoss',
];

export function assertNoFinancialData(raw: unknown): void {
  const scan = (obj: unknown, depth = 0) => {
    if (depth > 4 || obj === null || typeof obj !== 'object') return;
    for (const [key, value] of Object.entries(obj as Record<string, unknown>)) {
      const lower = key.toLowerCase();
      if (FORBIDDEN_KEYS.some((f) => lower.includes(f.toLowerCase()))) {
        throw new Error(`financial field rejected: ${key}`);
      }
      scan(value, depth + 1);
    }
  };
  scan(raw);
}

/**
 * Badge slugs that encode a savings *threshold* (crossing 1.000 / 5.000 lei). Their names
 * are semantically financial but can't be caught by the key-scan (they travel as VALUES in
 * the `badges` array), so the proxy strips them itself — a true backstop even if the client
 * filter ever regresses. Keep in sync with the client filter in ChatService.recoveryContext.
 */
const FINANCIAL_BADGES = new Set(['thousandLei', 'fiveThousandLei']);

/** Validates and normalizes untrusted input into a safe RecoveryContext. */
export function sanitizeContext(raw: unknown): RecoveryContext {
  assertNoFinancialData(raw);
  const c = (raw ?? {}) as Record<string, unknown>;
  const int = (v: unknown, max: number) =>
    Math.max(0, Math.min(max, Math.trunc(Number(v) || 0)));
  const lang: Language = c.language === 'en' ? 'en' : 'ro';
  const badges = Array.isArray(c.badges)
    ? c.badges
        .filter((b): b is string => typeof b === 'string')
        .filter((b) => !FINANCIAL_BADGES.has(b)) // strip savings-band badges server-side too
        .slice(0, 20)
    : [];
  return {
    streakDays: int(c.streakDays, 100000),
    cravingsBeaten: int(c.cravingsBeaten, 100000),
    relapseCount: int(c.relapseCount, 100000),
    carTier: typeof c.carTier === 'string' ? c.carTier.slice(0, 40) : 'rabla',
    badges,
    language: lang,
  };
}
