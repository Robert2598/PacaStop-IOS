// Shared types for the PacaStop AI proxy.

export interface Env {
  RATE_LIMIT: KVNamespace;

  // vars
  CLERK_ISSUER: string;
  CLERK_JWKS_URL: string;
  REQUIRE_AUTH: string;
  REQUIRE_PREMIUM: string;
  RATE_PER_MINUTE: string;
  RATE_PER_DAY: string;
  /** RevenueCat project id (proj…) — the V2 API keys premium checks by project. */
  REVENUECAT_PROJECT_ID: string;

  // secrets
  ANTHROPIC_API_KEY: string;
  /** Legacy misspelling tolerated so a mis-named secret still works. Prefer ANTHROPIC_API_KEY. */
  ANTROPHIC_API_KEY?: string;
  REVENUECAT_SECRET_KEY?: string;
}

export type Language = 'ro' | 'en';

/**
 * The ONLY user state the mentor ever receives. Strictly non-financial:
 * no loss amount, no money saved, not even a rounded band. Enforced by
 * `assertNoFinancialData` in context.ts.
 */
export interface RecoveryContext {
  streakDays: number;
  cravingsBeaten: number;
  relapseCount: number;
  carTier: string; // e.g. "smecher" — derived from streak, not money
  badges: string[];
  language: Language;
}

export type Role = 'user' | 'assistant';

export interface ChatTurn {
  role: Role;
  content: string;
}

export interface ChatRequest {
  message: string;
  history: ChatTurn[]; // recent turns only; the client caps this
  context: RecoveryContext;
}

export type Risk = 'none' | 'elevated' | 'crisis';

export interface RiskAssessment {
  risk: Risk;
  /** Actions the client should surface, e.g. ["helpline", "panic"]. */
  actions: string[];
}
