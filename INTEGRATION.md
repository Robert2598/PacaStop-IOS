# PăcăStop — Integration & Handover Notes

The app is **fully functional today** with native/first-party services (real Sign in with
Apple, StoreKit 2, Screen Time blocking, on-device SwiftData, local notifications). The
third-party SDKs you chose (Clerk, RevenueCat, PostHog) are wired behind seams and activate
automatically once their package + key are present — no further code changes needed.

## Architecture at a glance

- **UI:** SwiftUI (iOS 26), Swift 6 approachable concurrency, `@Observable` stores, custom
  design system (`DesignSystem/`), typed localization (`Localization/`, RO primary + EN,
  live switch).
- **Domain "brain":** pure, tested logic in `Domain/` (savings, streak, car ladder, badges,
  calculator, house-edge sim, RO money format). Unit tests in `PacaStopTests/DomainTests.swift`.
- **Persistence:** SwiftData → SQLite, on-device only (`Models/`).
- **DI:** `App/AppEnvironment.swift` builds everything; `ServiceFactory` picks production SDK
  vs native fallback based on `AppConfiguration` keys.

## Activating the production SDKs

The three Swift packages (RevenueCat `purchases-ios` 5.x, PostHog `posthog-ios` 3.x, Clerk
`clerk-ios` 1.x) are **already added to the Xcode project**. The adapter files
(`RevenueCatPurchaseService`, `PostHogAnalyticsService`, `ClerkAuthService`) are guarded with
`#if canImport(...)`, so they're compiled in. Each activates only when its key is set.

### Where to put your keys → `PacaStop/Resources/Secrets.plist`

Replace the `YOUR_…` placeholders. Any value still starting with `YOUR_` is ignored, so that
service falls back to its native implementation. (You can also set env vars of the same name in
the scheme's Run → Arguments, handy for CI.)

| Plist key | Use the… | Format | ⚠️ Security |
|---|---|---|---|
| `CLERK_PUBLISHABLE_KEY` | Clerk **Publishable key** | `pk_test_…` / `pk_live_…` | Client-safe (publishable). |
| `REVENUECAT_API_KEY` | RevenueCat **public Apple SDK key** | `appl_…` | **Never** the *secret* API key (`sk_…`) — that's server-only and must not ship. |
| `POSTHOG_API_KEY` | PostHog **Project API key** | `phc_…` | Client-safe (write-only ingestion). |
| `POSTHOG_HOST` | PostHog host | `https://eu.i.posthog.com` (EU) or `https://us.i.posthog.com` | — |

> **Never commit real keys.** Add `PacaStop/Resources/Secrets.plist` to `.gitignore` and inject
> it in CI. Only publishable/public client keys ever belong in the app bundle; they're designed
> to be shipped, but treat the file as sensitive anyway.

### Dashboard setup

- **RevenueCat:** create an entitlement named exactly **`premium`**, and an Offering whose
  packages are the annual + weekly products (`com.pixelpaw.pacastop.annual` / `.weekly`). The
  adapter reads `offerings.current` and the `premium` entitlement.
- **Clerk:** enable the **Apple** and **Google** OAuth providers. The iOS OAuth callback uses
  `ASWebAuthenticationSession` with Clerk's default redirect **`com.pixelpaw.PacaStop://callback`**
  (scheme = the bundle id) — **no Info.plist URL-scheme registration is needed**. Just ensure that
  redirect is allowed in your Clerk instance's native-application settings. (In the app, "Continue
  with Apple" uses the native Sign-in-with-Apple button and reflects the session locally; "Continue
  with Google" runs through Clerk's OAuth. If you want Apple to also create a Clerk session, switch
  the Apple button to `env.auth.signIn(.apple)` in `LoginView`.)

## App identity (App Store Connect)

- **Bundle ID:** `com.pixelpaw.PacaStop` — matches the Xcode project (`PRODUCT_BUNDLE_IDENTIFIER`).
- **Apple ID:** `6788886935` · **SKU:** `com.pixelpaw.pacastop` · Primary language: Romanian.
- The explicit App ID has Family Controls + Sign in with Apple enabled (already configured).
- **PostHog:** nothing extra — autocapture, screen views and session replay are already disabled
  in code for privacy; only the typed funnel events are sent.

## Analytics (PostHog) — the funnel you get

Privacy rule baked in: **no loss amounts ever leave the device** (honors the app's promise).
Only behavioral funnel events + non-financial segmentation are sent.

**Super properties** on every event: `app_version`, `build`, `platform`, `language`,
`frequency` (category), `streak_bucket`, `has_premium`, `blocking_active`, `onjn_enrolled`,
`relapses`.

**Onboarding funnel:** `onboarding_started` → `onboarding_step_viewed` (step) →
`onboarding_step_completed` (step, **seconds**) → `onboarding_frequency_selected` (category) →
`onboarding_house_edge_replayed` → `onboarding_back_tapped` (from_step) →
`onboarding_completed` (**total seconds**). Build a step-drop-off funnel and see where/how long
users stall — the house-edge step is the key aha.

**Paywall funnel:** `paywall_shown` → `paywall_plan_selected` (product, fires on every toggle) →
`purchase_started` → `purchase_completed` / `purchase_failed` / `purchase_cancelled` (product) →
`paywall_result` (**purchased** bool, **dwell_seconds**). `paywall_shown` → `purchase_completed`
is your conversion rate; `paywall_result{purchased:false}` with dwell is abandonment.

Suggested PostHog insights: an onboarding funnel (started → each step_completed → completed), a
paywall funnel (shown → started → completed), conversion split by `frequency` and
`streak_bucket`, and median `dwell_seconds` for buyers vs abandoners.

## App blocking (Screen Time)

Uses **FamilyControls + ManagedSettings** (`Services/Blocking/`). The
`com.apple.developer.family-controls` entitlement is already in `PacaStop.entitlements`.

- **Development:** works on a real device with your Apple ID. On the Simulator authorization
  is limited (the UI degrades gracefully with an explanatory hint).
- **App Store:** you must **request the Family Controls distribution entitlement** from Apple
  (developer.apple.com → Support → Contact). Approval is required before release.

## Monetization

- Local testing uses `PacaStop.storekit` (wired to the shared scheme). Run from Xcode to see
  live products; the paywall also shows display-only fallback plans if products can't load.
- For production, create the matching auto-renewable subscriptions in App Store Connect:
  `com.pixelpaw.pacastop.annual` (P1Y) and `com.pixelpaw.pacastop.weekly` (P1W).

## Before shipping — verify these (flagged in the brief)

- **Responsible-gaming helpline:** `Joc Responsabil · 0800 800 099` in `Strings_RO/EN` is a
  placeholder. Confirm the current official Romanian helpline and update `panicHelpline`.
- **ONJN self-exclusion:** the app deep-links the official page
  (`https://onjn.gov.ro/relatii-publice/autoexcludere/`) and stores a self-attested enrolled
  flag. Re-verify the real process/URL before release.
- **Betting blocklist:** blocking uses the user's own Screen Time app/site selection (there is
  no bundled list). Consider curating a Safari Content Blocker list of RO operators as a follow-up.

## Running

```
xcodebuild -scheme PacaStop -destination 'platform=iOS Simulator,name=iPhone 17' build
# Verification shortcuts (DEBUG only):
xcrun simctl launch booted com.pixelpaw.PacaStop -uiState home   # or login|onboarding|paywall|progress|settings
xcrun simctl launch booted com.pixelpaw.PacaStop -uiState home -lang en
```
