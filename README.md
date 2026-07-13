# PăcăStop

> **An anti-gambling recovery app for Romania.** iOS 17+, SwiftUI, local-first — with a hardened Cloudflare Workers AI-mentor proxy. Dark-only, Romanian-first, built to help someone take back control the moment a craving hits.

PacaStop (stylized **PăcăStop**) helps people quit slot machines (*păcănele/aparate*), sports betting (*pariuri*), and online casinos. It combines **real Screen Time blocking**, **ONJN self-exclusion**, a **savings tracker**, a **60-second panic lockout**, an **AI recovery mentor**, and a car-tier **gamification** ladder — all wrapped in a non-judgmental, brutally-honest tone.

- **Platform:** iOS 17+, iPhone-only, SwiftUI + SwiftData, Swift 6 / `@Observable` / `@MainActor`.
- **Backend:** Cloudflare Workers + Hono proxy in front of the Anthropic API (`backend/`).
- **Auth:** Clerk (Apple + Google OAuth). **Subscriptions:** RevenueCat + StoreKit 2. **Analytics:** PostHog (EU).
- **Privacy:** everything personal stays on-device; **the AI mentor never receives any financial data, ever.**

---

## Table of contents

- [What it does](#what-it-does)
- [Repository layout](#repository-layout)
- [Architecture](#architecture)
- [App flow & screens](#app-flow--screens)
- [🎨 Design system](#-design-system) — *the reference for designing new UI*
  - [Principles](#principles) · [Color](#color) · [Typography](#typography) · [Spacing / Radius / Metrics](#spacing-radius--metrics) · [Motion](#motion) · [Components](#components) · [Style modifiers](#style-modifiers) · [Designing new UI](#designing-new-ui)
- [Backend — AI mentor proxy](#backend--ai-mentor-proxy)
- [Privacy model](#privacy-model)
- [Build & run](#build--run)
- [Conventions](#conventions)

---

## What it does

| Feature | What it is |
|---|---|
| 🔒 **Real blocking** | Blocks betting/casino apps you pick via **Screen Time** (`FamilyControls`/`ManagedSettings`), plus a web-content filter over the bundled **ONJN operator denylist** (~94 domains) in Safari + system web views. |
| 📋 **ONJN self-exclusion** | Deep-links the official Romanian self-exclusion process, with a self-attested local flag. |
| 💰 **Savings tracker** | A live "money kept" counter (jackpot-style), anchored to real 2026 RON prices of things you can now afford. |
| 🆘 **Panic lockout** | A 60-second full-screen takeover with a countdown ring, rotating reality messages, and the helpline — leaving early never breaks the streak. |
| 💬 **AI recovery mentor** | A Romanian, psychologist-toned chat you talk to instead of gambling. Streams over SSE from a proxy. **No financial data is ever sent.** |
| 🚗 **Gamification** | Streak days, a 6-rank car "garage" that upgrades as you stay clean, and sticky achievement badges. |

---

## Repository layout

```
PacaStop/                      ← repo root (this monorepo)
├── PacaStop/                  ← the iOS app (Xcode project)
│   ├── PacaStop.xcodeproj
│   └── PacaStop/
│       ├── App/               ← @main entry, AppEnvironment (DI), AppRouter, RootView
│       ├── Stores/            ← AppModel (the single source of truth), LocalizationStore, PreferencesStore
│       ├── Models/            ← SwiftData @Model classes (UserProfile, PanicEventRecord, BadgeUnlock, ChatMessage)
│       ├── Services/          ← Auth / Purchases / Chat / Blocking / Analytics / Notifications (protocol + prod/fallback)
│       ├── Domain/            ← pure, deterministic "brain" (savings, streak, car ladder, badges, house-edge sim…)
│       ├── Features/          ← screens (Auth, Onboarding, Paywall, Main, Home, Garage, Progress, Panic, Chat, Settings)
│       ├── Components/        ← reusable UI (PacaButton, PacaTabBar, cards, chips, car, rings…)
│       ├── DesignSystem/      ← Palette, Typography, Layout (spacing/radius/metrics), Motion, Styles
│       ├── Localization/      ← typed RO/EN contract + tables
│       └── Resources/         ← Fonts/, Secrets.plist (git-ignored), PacaStop.storekit
├── backend/                   ← Cloudflare Workers + Hono AI-mentor proxy (TypeScript)
│   ├── src/                   ← index.ts, auth.ts, ratelimit.ts, premium.ts, context.ts, anthropic.ts, prompt.ts, knowledge.ts
│   └── wrangler.toml
└── artifacts/                 ← design/handover docs, screenshots
```

---

## Architecture

**Local-first & always-runs.** Every third-party SDK (Clerk, RevenueCat, PostHog) has a functional native fallback — keys only *upgrade* a service to its production impl, so the app builds and runs even with no keys and no network. All personal state is on-device (SwiftData → SQLite).

**Composition root — `AppEnvironment`** (`App/AppEnvironment.swift`): an `@Observable @MainActor` class built once at launch and injected into the SwiftUI environment. It owns the `ModelContainer`, the sub-stores (`loc`, `prefs`, `router`), all services (as `any` protocols), and the `appModel`. `ServiceFactory` (bottom of the file) is the only place that picks concrete impls.

**Single source of truth — `AppModel`** (`Stores/AppModel.swift`): an `@Observable @MainActor` store wrapping SwiftData. It exposes **live derived values** from the pure `Domain` layer (savings, streak, current car tier, badge context) and orchestrates services. Dependencies are `@ObservationIgnored`. Journey mutations (`completeOnboarding`, `relapse`, `recordPanic`, `enrollONJN`, blocking setters, `evaluateBadges`) all `save()` and emit analytics.

**Derived routing — `AppPhase`** (`App/AppRouter.swift`): the app never navigates between phases manually; the phase is *computed* from state, so it's always consistent:

```swift
guard isSignedIn else { return authRestoring ? .launch : .login }
guard onboardingCompleted else { return .onboarding }
if hasPremiumOverride { return .main }          // DEBUG/demo only — always false in release
guard entitlementReady else { return .launch }  // hold on splash, don't flash the paywall
return isSubscribed ? .main : .paywall           // hard paywall: no trial, no free tier
```

**Per-account isolation (`ownerID`).** The device supports multiple accounts. On sign-in, `switchToProfile(for:)` resolves the active `UserProfile` by `authUserID` (resume existing → claim the unclaimed one → else create fresh), and child rows (`PanicEventRecord`/`BadgeUnlock`/`ChatMessage`) carry an `ownerID` so nothing leaks across accounts. `endSession()` (sign-out) is **reversible** (keeps the journey + shields); `wipeAllLocalData()` (account deletion, Guideline 5.1.1(v)) removes only the current account's data.

**SwiftData schema** (`Schema([UserProfile, PanicEventRecord, BadgeUnlock, ChatMessage])`):

| Model | Purpose | Notable fields |
|---|---|---|
| `UserProfile` | the active account record | `authUserID?`, `quitDate`, `onboardingCompleted`, `amountPerSession`, `frequencyRaw`, `relapseCount`, `lifetimeSavedBeforeReset`, blocking flags, `blockedSelectionData` (opaque `FamilyActivitySelection`), `premiumOverride` |
| `PanicEventRecord` | one panic session | `heldOut` (full clock = "craving beaten"), `configuredSeconds`, `ownerID?` |
| `BadgeUnlock` | a sticky earned badge | `badgeRaw`, `unlockedAt`, `ownerID?` |
| `ChatMessage` | one mentor turn | `roleRaw` (user/mentor), `text`, `isStreaming`, `ownerID?` |

**Service layer — protocol + production/fallback.** Each domain is a `@MainActor protocol`; production SDKs are compiled behind `#if canImport(...)`.

| Domain | Protocol | Production (condition) | Fallback | Preview |
|---|---|---|---|---|
| Auth | `AuthService` | `ClerkAuthService` (`ClerkKit` + key) | `LocalAuthService` | `PreviewAuthService` |
| Purchases | `PurchaseService` | `RevenueCatPurchaseService` (`RevenueCat` + key) | `StoreKitPurchaseService` (StoreKit 2) | `PreviewPurchaseService` |
| Analytics | `AnalyticsService` | `PostHogAnalyticsService` (`PostHog` + key) | `ConsoleAnalyticsService` | — |
| Blocking | `BlockingService` | `ScreenTimeBlockingService` | `PreviewBlockingService` | `PreviewBlockingService` |
| Notifications | `NotificationService` | `LocalNotificationService` (always) | — | — |
| Chat | `ChatService` | `RemoteChatService` (SSE, when backend URL set) | `PreviewChatService` (canned on-device mentor) | `PreviewChatService` |

**Auth is the most careful seam.** `AuthState` is the single source of truth — `enum { restoring, signedOut, authenticated(AuthUser), localOnly(AuthUser) }`; `isSignedIn`/`currentUser`/`hasBackendSession` are *derived*, so no parallel flag can drift. `.localOnly` is signed-in but has no backend session (gates the mentor). `ClerkAuthService` mirrors Clerk's async session lifecycle, and `handleUnauthorized()` drops to `.signedOut` only when a token truly can't be minted (→ clean re-login instead of a dead-end error). Both Apple and Google run through **Clerk OAuth**.

**Purchases — one source of truth.** The client checks **any active RevenueCat entitlement** (the entitlement is identified *"PacaStop Pro"* in the dashboard; neither client nor server hardcodes the name) — which is exactly what the backend's RevenueCat **V2 API** check does. `identify(_:)` aliases the RevenueCat customer to the Clerk id so the server-side gate keys to the same user.

**Localization — a typed RO/EN contract.** `protocol Localization` is exhaustive (plain copy as properties, interpolated copy as functions), so a string can never exist in one language but not the other. `LocalizationStore` (`@Observable`) flips `language` (persisted, default `.ro`) and re-renders instantly.

**Domain layer** (`Domain/*.swift`) — pure, `nonisolated`, deterministic, `now`-injectable: `SavingsCalculator`, `Frequency`, `StreakCalculator`, `CarTier`/`CarLadder` (6 ranks), `Badge`/`BadgeEngine` (9 achievements), `MoneyCalculator` (RON 2026 prices), `PanicCalculator`, `HouseEdgeSimulation` (seeded RTP-0.94 bankroll bleed), `MoneyFormatter` (RO `"1.131,42 lei"`), `CasinoBlocklist` (ONJN denylist).

---

## App flow & screens

Every phase transition is a crossfade in `RootView`; the phase is derived (never pushed).

```
launch (Splash) ──not signed in──▶ login (Login: Apple/Google via Clerk, or demo)
                                          │ onAuthenticated
       ┌──────────────────────────────────┘
       ├─ not onboarded ─▶ onboarding (5 steps: Frequency → Money → Reveal → Commit → Pledge)
       ├─ onboarded, not subscribed ─▶ paywall (hard, with Restore)
       └─ onboarded, subscribed ─▶ main (tabs: Acasă · Progres · Mentor · Setări)
                                        ├─ sheet ─▶ Garage (car/rank ladder)
                                        └─ fullScreenCover ─▶ Panic (60s lockout; also from Mentor on crisis/urge)
```

| Screen | Purpose |
|---|---|
| **Splash** (`.launch`) | Brief hold while entitlement/session resolves — prevents a returning user flashing Login. |
| **Login** (`.login`) | Fast, discreet sign-in. Apple + Google (Clerk OAuth) + demo shortcut. Real failure reasons surfaced in an alert. |
| **Onboarding** (`.onboarding`) | 5 linear steps. Step 2 = amount slider (50–2000 lei) with live weekly/yearly loss; **Step 3** = the house-edge "reveal" (100-bar bankroll bleed lime→red); Step 5 = a typed commitment pledge (diacritic/case-insensitive match). |
| **Paywall** (`.paywall`) | Hard, conversion-tuned. Loss-anchor band, benefit chips, plan cards (annual = "best value"), dominant CTA, and a **prominent Restore** (plus top-bar Restore). Prices in storefront currency. |
| **Home** (Acasă) | Rank + `StreakChip`, the car hero (→ Garage), a live money-kept `JackpotDisplay`, and the pulsing panic button. |
| **Garage** | The full 6-tier car/rank ladder as a bottom sheet. |
| **Progress** (Progres) | View-only trophy room: badge grid + "what your saved money buys." |
| **Mentor** (Mentor) | Streaming AI chat with a persistent disclaimer; crisis banner (helpline + panic) and urge quick-action reuse the panic machinery. |
| **Settings** (Setări) | Protection (master toggle, app picker, ONJN sites filter), ONJN self-exclusion, language RO⇄EN, Restore, and account (relapse / sign-out / delete). |
| **Panic** | 60s oxblood-red takeover: countdown ring, rotating message, reality card (litres of fuel), "give up" escape. Resisted → lime check burst. Runs with zero dependencies. |

---

## 🎨 Design system

> **This section is the source of truth for designing new UI (human or AI).** Design *against these tokens* — never introduce raw hex, ad-hoc sizes, or new fonts. Everything lives in `PacaStop/PacaStop/DesignSystem/` (`Palette`, `Typography`, `Layout`, `Motion`, `Styles`).

### Principles

1. **Dark-only.** There is no light theme. Every screen sits on `#0D0E11`; surfaces step *up* in lightness.
2. **Two accents, period.** **Lime** = win / money / progress. **Red** = loss / panic / danger. The source comment is explicit: *"Do not introduce new hues."* (`amber` exists only for the relapse row.)
3. **Loud display, calm body.** A condensed, heavy display face (**Anton**) screams the numbers and titles; a clean grotesque (**Space Grotesk**) carries everything readable.
4. **Tactile & alive.** Springy press feedback, staggered fade-ups, live-ticking counters, pulsing panic — motion has meaning.
5. **Tokens over values.** Use `Palette.*`, `Typo.*`, `Spacing.*`, `Radius.*`, `Metrics.*`, `Motion.*`, and the `.pacaCard`/`PacaButton`/`Kicker` primitives. If you're typing a hex or a magic number, stop.

### Color

Defined in Swift via `Color(hex: 0xRRGGBB, opacity:)` or `Color(white:opacity:)`.

**Backgrounds & surfaces** (darkest → lightest):

| Token | Hex | Role |
|---|---|---|
| `Palette.desk` | `#08090B` | deepest insets / frame backdrop |
| `Palette.background` | `#0D0E11` | **every screen background** |
| `Palette.surfaceDeep` | `#121317` | hero cards |
| `Palette.surfaceInset` | `#141519` | jackpot cells |
| `Palette.surface` | `#16181D` | **standard cards / list groups** |
| `Palette.raised` | `#1C1F26` | inner rows, avatars |

**Text:**

| Token | Value | Role |
|---|---|---|
| `Palette.textPrimary` | `#F4F5F7` | primary |
| `Palette.textSecondary` | white @ 55% | secondary |
| `Palette.textTertiary` | white @ 40% | tertiary |
| `Palette.textFaint` | white @ 28% | faint / disabled |

**Accents & tints:**

| Token | Value | Role |
|---|---|---|
| `Palette.lime` | `#C6F03C` | **primary accent** — money / win / progress |
| `Palette.onLime` | `#0D0E11` | text/icons *on* a lime fill |
| `Palette.red` | `#FF3B30` | panic / loss / danger |
| `Palette.softRed` | `#FF8079` | panic kickers, sign-out |
| `Palette.amber` | `#FFB84D` | relapse row **only** |
| `Palette.hairline` | white @ 8% | standard card border / divider |
| `Palette.hairlineStrong` | white @ 12% | stronger divider / track |
| `Palette.limeSoftFill` / `limeSoftBorder` | lime @ 10% / 28% | lime chips & selected states |
| `Palette.redSoftFill` / `redSoftBorder` | red @ 8% / 28% | danger chips |
| `Palette.panicBackground` / `panicBackgroundDeep` | `#2A0806` / `#1A0503` | panic takeover gradient |

### Typography

Two bundled TTF families, **registered programmatically at launch** via CoreText (`FontRegistrar.registerAll()` in `AppEnvironment`) — there is **no `UIAppFonts` key** in Info.plist. Files: `PacaStop/Resources/Fonts/`.

- **Display = `Anton`** (`Anton-Regular.ttf`) — condensed, single-weight, heavy. Big numbers, titles, rank names, jackpot digits, countdown.
- **Body = `Space Grotesk`** (`Regular / Medium / SemiBold / Bold`). Everything readable.
- Both verified for Romanian diacritics (ă â î ș ț, comma-below Ș/Ț).

Helpers: `Font.display(_ size:, relativeTo:)` and `Font.body(_ size:, weight:, relativeTo:)` (weight maps to the concrete face; both fall back to system fonts if registration fails). Prefer the `Typo.*` ramp:

**Display / Anton:** `heroHuge 64` · `hero 52` · `displayLg 44` · `screenTitle 34` · `rankName 30` · `displayMd 28` · `displaySm 21` · `countdown 78`.

**Body / Space Grotesk:** `title 20/bold` · `headline 17/semibold` · `button 16/bold` · `bodyLg 16/medium` · `bodyMd 15/regular` · `bodySm 14/regular` · `label 13/semibold` · `caption 12.5/regular` · `kicker 11/bold` (uppercased, `tracking 2`, lime — via the `Kicker` view).

### Spacing, Radius & Metrics

**`Spacing`** (CGFloat): `xxs 4` · `xs 8` · `sm 12` · `md 16` · `lg 20` · `xl 26` · `xxl 34` · `screenH 22` (horizontal screen padding) · `block 22` (vertical rhythm).

**`Radius`:** `card 22` · `cardLarge 24` · `tile 20` · `panicButton 20` · `field 16` · `button 15` · `reel 7` · `pill 999`.

**`Metrics`:** `primaryButtonHeight 54` · `panicButtonHeight 64` · `tabBarHeight 64` · `minTapTarget 52` · toggle `48×28`.

### Motion

`Motion.*` SwiftUI animations — use these, don't hand-roll springs:

| Token | Definition | Use |
|---|---|---|
| `snappy` | `spring(response: 0.32, dampingFraction: 0.82)` | **default** UI response, selection, taps, `PressableScale` |
| `smooth` | `spring(response: 0.5, dampingFraction: 0.85)` | sheets / larger movement, phase crossfade |
| `entrance` | `easeOut(0.45)` | section/screen entrance (backs `.fadeUpOnAppear`) |
| `counterTick` | `easeInOut(0.9)` | live savings/jackpot digit roll |
| `pulse` | `easeInOut(1.6).repeatForever(autoreverses:)` | panic button |
| `float` | `easeInOut(3.2).repeatForever(autoreverses:)` | car gentle bob |
| `barDrain` | `easeOut(0.09)` | house-edge sim bars |
| `bulbChase` | `easeInOut(0.5)` | marquee bulbs |

Entrance helper: `.fadeUpOnAppear(index:)` — starts at opacity 0 / `offset(y: 14)`, animates in with `entrance` staggered `index × 0.06s`. Transition: `AnyTransition.fadeUp` (move-from-bottom + opacity in, opacity out).

### Components

All in `PacaStop/PacaStop/Components/` (+ `Styles.swift`). Compose from these before building anything new.

- **`PacaButton`** — full-width button. `PacaButton(title:kind:icon:isLoading:isEnabled:action:)`. `kind`: `.lime` (primary CTA), `.white`, `.dark` (e.g. Google), `.redOutline` (destructive/ONJN step), `.ghost`. Height `54`, radius `15`, label `Typo.button`, optional leading SF Symbol; `isLoading` → spinner; disabled → 40% opacity; `PressableScale` feedback.
- **`PacaTabBar`** — the custom bottom tab bar (native chrome avoided). `MainTab`: `home` · `progress` · `mentor` · `settings`; active = lime, inactive = `textTertiary`; height `64`.
- **`SectionCard`** — padded surface card. `SectionCard(fill:padding:radius:border:) { … }` (defaults: `surface`, `20`, `22`, `hairline`).
- **`LabeledGroup`** — a settings group: uppercase `Kicker`-style label above a content block.
- **`ScreenHeader`** — Anton `screenTitle` with an optional back chevron (in a `40×40` surface tile).
- **`StreakChip`** — compact lime streak pill (flame + day count + unit) in a `limeSoftFill` capsule.
- **`BadgeTile`** — achievement tile: unlocked = lime tile + glyph; locked = `raised` empty with hairline.
- **`CarSilhouette`** — the status-metaphor car, drawn from shapes in a `200×112` space; upgrades tier-by-tier (junker with smoke/warning → sleek lime `legenda`). `floating:` adds a gentle bob.
- **`CountdownRing`** — panic countdown: depleting red ring + big Anton seconds (`countsDown` numeric transition).
- **`JackpotDisplay`** — the ironic slot display repurposed to count **money kept**: marquee bulbs + glowing lime digit "reels" that live-tick (`counterTick`).
- **`MarqueeBulbs`** — chasing casino bulbs (the ironic frame).
- **`SegmentedProgressBar`** — onboarding "Pasul n din 5" step indicator (lime segments).
- **`LinearProgressBar`** — lime car-tier progress toward the next rank.
- **`UpTriangle`** (`Shapes.swift`) — the streak-chip flame shape.
- **`LogoTile`** (in `App/RootView.swift`) — the lime brand tile with a rotated dark diamond (splash `56`, login `40`).

### Style modifiers

- **`.screenBackground(_ = Palette.background)`** — the standard edge-to-edge dark background.
- **`.pacaCard(_ fill = surface, radius = 22, border = hairline, borderWidth = 1)`** — the canonical card treatment (continuous corners + strokeBorder). Backs `SectionCard`.
- **`Kicker(_ text, color = lime, tracking = 2)`** — the all-caps letter-spaced label above headlines.
- **`PressableScale(scale = 0.97)`** — the standard button press-scale (uses `snappy`).
- **`.fadeUpOnAppear(index:)`** — staggered entrance (above).

### Designing new UI

A quick rubric for anything new (screens, components, states):

- ✅ Background `Palette.background`; group content in `.pacaCard`/`SectionCard`.
- ✅ Lime = something good/earned; red = loss/danger; everything else is neutral greys. **No new hues.**
- ✅ Headlines/numbers in `Font.display`/`Typo` display sizes; body in `Typo` body sizes. Prefix sections with a `Kicker`.
- ✅ Pad with `Spacing.screenH` (22) horizontally; use the `Spacing`/`Radius`/`Metrics` scales.
- ✅ Primary action = one dominant `PacaButton(.lime)`; secondary = `.dark`/`.ghost`; destructive = `.redOutline`.
- ✅ Animate with `Motion.snappy` (interactions) / `Motion.smooth` (transitions); enter with `.fadeUpOnAppear(index:)`.
- ✅ Tap targets ≥ `Metrics.minTapTarget` (52); real `Button`s (free VoiceOver), not tap gestures.
- ✅ All copy comes from the `Localization` contract (RO + EN) — never hardcode user-facing strings.
- ❌ No raw hex, no ad-hoc font sizes, no new fonts, no light mode, no third accent color.

---

## Backend — AI mentor proxy

A **Cloudflare Workers + Hono** service (`backend/`, worker `pacastop-ai-proxy`) that fronts the Anthropic API so the key never ships in the app. Entry: `src/index.ts`.

**`GET /health`** → `{ ok: true }`. **`POST /v1/chat`** → an **SSE** stream. The request runs a strict pipeline; any gate short-circuits *before* the Anthropic key is touched:

1. **Clerk JWT verify** (`auth.ts`) — `jose` `jwtVerify` against Clerk's JWKS (`createRemoteJWKSet`, cached), asserting the issuer; `userId = payload.sub`. Missing → `401 missing_token`; bad → `401 invalid_token`. Only the literal `REQUIRE_AUTH="false"` disables it (fails secure).
2. **Per-user rate limit** (`ratelimit.ts`) — two fixed-window KV counters: per-minute (`RATE_PER_MINUTE`, default 8) and per-day (`RATE_PER_DAY`, default 120). Breach → `429` + `Retry-After`. Soft cap (KV is eventually consistent).
3. **RevenueCat V2 premium gate** (`premium.ts`) — when `REQUIRE_PREMIUM="true"`: `GET /v2/projects/{REVENUECAT_PROJECT_ID}/customers/{clerkUserId}/active_entitlements` with the **secret** key. Any active entitlement = premium. False → `403 premium_required`; throw → `502`. (Uses **V2** because the app key is a V2 key — V1 rejects it with error 7723.)
4. **Body parse + privacy guard** (`context.ts`) — `message` (≤4000), `history` (≤16 turns), and `context` through `sanitizeContext`, which **throws on any financial field** (see below). Failure → `400`.
5. **Crisis classifier** (`anthropic.ts`) — Anthropic **`claude-haiku-4-5`**, `max_tokens 256`, structured JSON output → `{ risk: none | elevated | crisis }`. Emitted first as `event: meta` (with `actions`) so the app renders crisis UI immediately. **Fails open to `none`** on error.
6. **Streaming responder** — Anthropic **`claude-sonnet-4-6`**, `stream: true`. System = a **prompt-cached** persona/boundaries/knowledge-base prefix (`cache_control: ephemeral`) + a small uncached per-turn non-financial context block. Streamed back as `delta` → `done` events.

**Env** — `[vars]`: `CLERK_ISSUER`, `CLERK_JWKS_URL`, `REQUIRE_AUTH`, `REQUIRE_PREMIUM`, `RATE_PER_MINUTE`, `RATE_PER_DAY`, `REVENUECAT_PROJECT_ID` (non-secret). **Secrets** (via `wrangler secret put`, never committed): `ANTHROPIC_API_KEY` (server-only), `REVENUECAT_SECRET_KEY` (only if `REQUIRE_PREMIUM=true`). KV binding: `RATE_LIMIT`.

---

## Privacy model

- **On-device by default.** All personal data (profile, streak, savings inputs, badges, panic history, chat) lives in SwiftData on the phone. Nothing syncs.
- **The AI mentor never receives financial data — ever.** Not a loss amount, not savings, not a rounded band. This is enforced in three layers:
  1. **Client** — `AppModel.recoveryContext(language:)` is the *only* place the mentor payload is built, and it sends strictly non-financial signals (`streakDays`, `cravingsBeaten`, `relapseCount`, `carTier`, non-financial `badges`, `language`); money-threshold badges are dropped.
  2. **Server key-scan** — `assertNoFinancialData` (`context.ts`) recursively rejects any key matching `amount, saved, savings, money, lei, balance, yearlyLoss, weeklyLoss, …` → `400`.
  3. **Prompt** — the system prompt tells the model it *does not know* money figures ("that data intentionally never leaves their phone").
- **Analytics carry no money.** The per-session loss amount is never emitted; only bucketed, non-financial super-properties. PostHog autocapture/replay/screen-views are off; EU hosting.

---

## Build & run

### iOS app

- Open `PacaStop/PacaStop.xcodeproj` in Xcode (iOS 17+ SDK). Scheme: **PacaStop**. iPhone-only.
- **Secrets:** create `PacaStop/PacaStop/Resources/Secrets.plist` (git-ignored). Keys: Clerk publishable key, PostHog key + host, RevenueCat public SDK key, `AI_BACKEND_URL`. Any `YOUR_…` placeholder → the app uses that service's **fallback** (so it still builds/runs with none set).
- Command-line build for the simulator:
  ```sh
  # NOTE: unset these first or SPM resolution can hang on this machine
  unset GIT_CONFIG_COUNT GIT_CONFIG_KEY_0 GIT_CONFIG_VALUE_0
  xcodebuild -project PacaStop/PacaStop.xcodeproj -scheme PacaStop \
    -destination 'generic/platform=iOS Simulator' -configuration Debug \
    build CODE_SIGNING_ALLOWED=NO
  ```
- **TestFlight:** bump `CURRENT_PROJECT_VERSION`, archive (`-allowProvisioningUpdates DEVELOPMENT_TEAM=…`), export with the App Store options plist, upload via `xcrun altool --upload-app` with your App Store Connect API key.

### Backend

```sh
cd backend
npm install
npx wrangler dev                     # local (uses .dev.vars for secrets)
npx wrangler deploy                  # deploy
npx wrangler secret put ANTHROPIC_API_KEY
npx wrangler secret put REVENUECAT_SECRET_KEY
npx wrangler tail --format pretty    # live logs
```

---

## Conventions

- **State:** `@Observable` + `@MainActor` stores; `@State` for owned view state, `@Bindable` for injected observables, `@Environment(AppEnvironment.self)`. No `ObservableObject`/`@Published` in new code.
- **Async:** `.task {}` / explicit load methods — never I/O in `body` or `init`.
- **Domain logic stays pure** (`Domain/`), UI orchestrates. `now` is injectable for deterministic tests.
- **Accessibility:** real `Button`s, Dynamic-Type-relative fonts (`relativeTo:`), grouped labels.
- **Copy:** everything user-facing goes through the typed `Localization` contract (RO primary, EN parity).

---

*PăcăStop — dacă tu sau cineva drag are o problemă cu jocurile de noroc, sună la linia „Joc Responsabil".*
