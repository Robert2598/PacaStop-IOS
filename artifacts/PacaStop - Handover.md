# PăcăStop — UI/UX Handover & Implementation Brief

> A private mobile app that helps Romanian men quit the slot machines (*păcănele / aparate*).
> This document describes **what to build and how it should look, feel, and behave** — the full UX.
> All technical decisions (framework, storage, notifications, blocking mechanism, auth, etc.) are **yours to make**. Nothing here prescribes a stack.

---

## 0. How to read this document

- **Section 1–3** = the product, its voice, and the global design language. Read first.
- **Section 4** = the navigation map (how screens connect).
- **Section 5** = every screen, described visually and behaviorally, top to bottom.
- **Section 6** = the "brain": all the rules and numbers (savings math, streak, car ranks, badges, calculator, panic timing).
- **Section 7** = full copy in **Romanian (primary)** and **English**, plus the tone guide.
- **Section 8** = states, edge cases, and things you must decide or source.
- **Section 9** = suggested build priority (MVP → full).

A working, clickable reference prototype exists (`PacaStop App.dc.html`). When wording here and the prototype differ, **this document wins** — it reflects the latest decisions.

---

## 1. Product in one paragraph

PăcăStop helps a man stop feeding slot machines — **alone, privately, on his own money**. No therapy, no "let's talk about feelings," **no social features, no friends, no leaderboard, nobody ever sees how much he lost.** The core loop: it **blocks** betting apps/sites, it **shows him how much he's saving** by not playing (framed as a jackpot he's winning by staying out), it **ranks his progress** as an upgrading car, and it **stops him in the exact moment of temptation** with a 60-second panic lockout. The single emotional message everywhere:

> **"Nu fi fraierul aparatelor."** — *Don't be the machine's fool. The house always wins; the only sure win is walking away with your money.*

**Audience:** Romanian men who play the slots. Blunt, practical, money- and pride-driven. Not clinical.

**Privacy is a feature.** Everything is personal and local to the user. There is intentionally nothing to compare, share, or broadcast.

---

## 2. Voice & tone

- **Firm, blunt, confident — but never insulting.** We push with reality, money, pride, and family. We do not call the user stupid.
- Short sentences. Punchy. Romanian slang is welcome and on-brand: *fraier, aparate, păcănele, rablă, șmecher, cashu'*.
- Money is the lever. Always translate abstract loss into concrete things (fuel, groceries, car payments, a real car).
- Pride/status is the second lever (the car ladder, ranks).
- Family is the third lever, used sparingly (a reminder on Home, one panic message).
- **Never** celebrate gambling, never show winnings as exciting, never use casino glamour except *ironically* (the jackpot counter is repurposed to count money **kept**, not won).

**Do:** "Aparatul câștigă mereu. Tu ești singurul care pleacă cu buzunarele goale."
**Don't:** "Ești un prost dacă joci." (crosses into insult)

---

## 3. Design language

The app is **dark, bold, and in-your-face**, but disciplined — not a neon casino.

### 3.1 Color

| Role | Value | Usage |
|---|---|---|
| App background | `#0d0e11` | every screen |
| "Desk" behind the phone | `#08090b` | frame backdrop |
| Surface / card | `#16181d` | standard cards, list groups |
| Surface (deep / insets) | `#121317`, `#141519`, `#08090b` | hero cards, jackpot cells |
| Surface (raised row) | `#1c1f26` | inner rows, avatars |
| Hairline / border | `rgba(255,255,255,.06–.10)` | card borders, dividers |
| Text primary | `#f4f5f7` | headings, values |
| Text secondary | `rgba(244,245,247,.55)` | body, subtitles |
| Text tertiary | `rgba(244,245,247,.35–.42)` | labels, captions |
| **Accent — money / win / progress** | **`#C6F03C`** (electric lime) | savings, streak, unlocked badges, progress, primary CTAs, active nav |
| **Danger — panic / loss** | **`#FF3B30`** (signal red) | panic button, panic screen, yearly-loss number, warnings |
| Soft red (text) | `#ff8079` | panic kickers, sign-out |
| Amber (caution) | `#ffb84d` | "Am recăzut" (relapse) row only |

**Rules of thumb:** Lime = "you're winning by staying out." Red = "danger / what you're about to lose." Everything else is neutral dark. Do not introduce new hues; don't use gold/casino-green.

### 3.2 Typography

- **Display face — condensed, heavy, screaming.** Used for: all big numbers, rank names, screen titles, jackpot digits, hero statements. (Prototype uses **Anton**.) All-caps friendly.
- **UI/body face — clean modern grotesque**, weights ~400/500/600/700. Used for: everything else — labels, body, buttons, list rows. (Prototype uses **Space Grotesk**.)
- **Must fully support Romanian diacritics** (ă â î ș ț). Verify any substitute face renders `ș`/`ț` correctly.
- Never smaller than ~11px for labels; body ~14–16px; hero numbers 40–78px.

### 3.3 Shape, spacing, motion

- **Corners:** cards 20–24px, buttons 14–16px, pills fully round, jackpot digit cells ~7px.
- **Tap targets:** ≥ 52px for primary actions; toggles ~48×28px.
- **Screen padding:** ~20–26px horizontal; generous vertical rhythm (~16–26px between blocks).
- **Motion** (all subtle, purposeful):
  - Screen/section entrances: short fade-up.
  - **Savings counter ticks live** (updates continuously, visibly changing).
  - Panic countdown ring depletes smoothly.
  - Jackpot marquee bulbs blink in a staggered chase.
  - Car gently floats.
  - Panic button softly pulses (red glow).
  - House-edge simulation bars drain left→right.
  - Sheets slide up from the bottom.

### 3.4 Iconography

Minimal, geometric, **monochrome**, tinted by state (lime when active, muted otherwise). No emoji. Bottom-nav icons: a house (Home), ascending bars (Progres), sliders (Setări). Checkmarks for unlocked badges. A small triangle "flame" for the streak chip.

### 3.5 The car illustrations (status metaphor)

Cars are shown as **clean, minimalist side-profile silhouettes** that visibly improve tier by tier (dull/boxy/broken → sleek/low/premium/lime-accented). In the prototype they're built from simple shapes; you may replace them with higher-fidelity illustrations if you wish, **as long as the progression reads at a glance** and the lowest tier clearly looks like a broken old junker (with a little exhaust smoke and a red warning light).

### 3.6 Device framing

Designed as a **portrait phone app** (single column, ~390–400pt wide). Dark status bar content. A persistent bottom tab bar on the main screens; full-bleed takeover for the panic flow.

---

## 4. Navigation map (how it all links)

```
                         ┌─────────────┐
                         │   LOGIN     │  Apple / Google  ┐
                         └─────────────┘  "Am deja cont"  │ (demo shortcut → Home)
                                │                          │
                     (new user) │                          │
                                ▼                          │
                    ┌───────────────────────┐             │
                    │  ONBOARDING (4 steps)  │             │
                    │  1 frequency           │             │
                    │  2 money (slider)      │             │
                    │  3 house-edge reveal   │             │
                    │  4 commit              │             │
                    └───────────────────────┘             │
                                │ "ÎNCEP ACUM"             │
                                ▼                          ▼
   ┌──────────────────────────────  MAIN APP  ──────────────────────────────┐
   │   Bottom tab bar visible on all three:  [ Acasă ] [ Progres ] [ Setări ]│
   │                                                                          │
   │   ACASĂ (Home) ──tap car card──▶  GARAGE (bottom sheet)                  │
   │        │                                                                 │
   │        └──"BUTON DE PANICĂ"──▶  PANIC (full-screen takeover)             │
   │                                     │                                    │
   │                                     ├─ hold 60s ▶ "AI REZISTAT" ▶ Home   │
   │                                     └─ "Renunț..." ▶ Home (streak kept)  │
   │                                                                          │
   │   PROGRES ── badges + "ce-ți luai" calculator (view only)               │
   │                                                                          │
   │   SETĂRI ── blocking · ONJN self-exclusion · language · theme            │
   │             · "Am recăzut" (reset streak) · "Deconectează-te" (→ Login)  │
   └──────────────────────────────────────────────────────────────────────────┘
```

- **Login** and **Onboarding** are linear and have **no tab bar**.
- **Panic** is a **full-screen takeover** — no tab bar, no way to wander off; the only exits are "held out 60s" or a small, deliberately unglamorous "give up" link.
- **Garage** is a **bottom sheet** over Home (dim scrim, slides up, close via ✕ or tap-outside).
- The **panic button lives permanently on Home** (it is *not* a setting).

---

## 5. Screens, one by one

For each: purpose → layout (top→bottom) → interactions.

### 5.1 Login

**Purpose:** get in fast, privately, reassure it's discreet.

**Layout:**
- Wordmark **PĂCĂSTOP** with a small lime logo tile (top).
- A red pill stat: *"Românii pierd 2 miliarde € pe an la aparate"* (a small pulsing red dot).
- Huge display headline: **"Nu fi fraierul aparatelor."**
- One line of body: what the app does.
- Two full-width buttons: **Continuă cu Apple** (white), **Continuă cu Google** (dark).
- Text link **"Am deja cont — intră în aplicație"** (a returning-user / demo entry that lands directly on a populated Home).
- Fine print: terms + "totul rămâne privat, pe telefonul tău."

**Interactions:** any auth button → Onboarding (new user). The text link → Home directly.

---

### 5.2 Onboarding — 4 steps

Linear, with a back chevron and a 4-segment progress bar at top ("PASUL n DIN 4"). A single bottom CTA advances; it's disabled until the step's requirement is met. **This is the persuasion core — the moment the user *sees* he can't win.**

**Step 1 — Frequency.** Title *"Cât de des joci la păcănele?"*, sub *"Fii sincer. Nu te vede nimeni."* Four single-select options (selected = lime outline + filled radio):
- Zilnic · De câteva ori pe săptămână · O dată pe săptămână · De câteva ori pe lună.
(Each maps to a sessions-per-week number — see §6.)

**Step 2 — Money.** Title *"Cât lași, în medie, de fiecare dată?"*. A big lime number (the amount) with a **slider** (≈50–2000 lei, default 200). Below, a live projection card that updates as he drags: **Pe săptămână** = weekly loss, **Într-un an** = yearly loss (shown big and **red**).

**Step 3 — The house-edge reveal.** The emotional turn. Kicker *"MATEMATICA SIMPLĂ"*, title **"Aparatul e reglat să câștige. Mereu."** Body explains in plain words: *of every 100 lei fed in, the machine returns ~94 and keeps ~6; you win sometimes — just enough to keep you there — but you feed it all back and the house always takes it.* Then an **animated simulation**: a bar chart of a 100-spin bankroll that **drains from full (lime) down to almost nothing (red)**, left to right, tappable to replay. A result line updates: *"Ți-au mai rămas ~X lei."*

**Step 4 — Commit.** Kicker *"CU RITMUL TĂU"*, then a personalized gut-punch: **"Într-un an dai aparatelor {sumă} lei"** (huge, red), computed from his own answers. Then the flip: **"Gata cu fraierul. De azi banii rămân la tine."** CTA **ÎNCEP ACUM** → Home. This is the moment the blocker "turns on" and the savings counter starts from now (Day 0).

---

### 5.3 Acasă (Home) — the daily hub

**Purpose:** show pride (rank/car), reward (money kept, as a jackpot), and the escape hatch (panic). Scrollable; bottom tab bar pinned.

**Top→bottom:**
1. **Header.** Left: tiny label *"RANGUL TĂU"* + **rank name** in lime display type (e.g. *"Ai prins viteză"*). Right: a **compact streak chip** — a small lime pill with a triangle "flame", the day count, and the word **ZILE** (e.g. `▲ 12 ZILE`). The streak is intentionally small here.
2. **Car hero card** (tappable → Garage). A lime glow behind the **current car silhouette** (gently floating), the **model name** under it (e.g. *VW Golf*), a **progress bar** toward the next tier, a caption *"Următoarea mașină în N zile"*, and a lime link *"Garajul meu ›"*.
3. **Jackpot — "AI STRÂNS".** The savings, styled like a **slot-machine jackpot display** (irony: the machine metaphor now counts money he *kept*): a row of blinking **marquee bulbs**, the label **AI STRÂNS**, then the amount rendered as **individual glowing lime digit "reels"** (dark inset cells, split line across the middle, thousands/decimal separators as their own small cells, "lei" suffix). **The last digits tick up live.** Caption: *"de când nu mai hrănești aparatul."*
4. **Panic section.** Kicker *"SIMȚI IMPULSUL SĂ JOCI?"*, a big **red, softly pulsing** button **BUTON DE PANICĂ**, sub *"Apasă și rezistă 60 de secunde. Atât."*
5. **Family reminder card.** Kicker *"ȚINE MINTE DE CE"* + a line about his kids watching / being the man they admire, not the one who gambles away his paycheck.

**Interactions:** car card → Garage sheet; panic button → Panic flow; tab bar → Progres / Setări.

---

### 5.4 Panic — the 60-second lockout

**Purpose:** intercept the urge, run out the clock, reframe the loss, protect the streak. **Full-screen, no navigation, deep oxblood-red background.** Two states.

**State A — Counting down:**
- Title **"STAI. RESPIRĂ."**
- A **rotating firm message** (changes every ~8 seconds) — see the message set in §7. Some interpolate his own numbers (his saved total, his streak).
- A large **countdown ring** (default **60s**) that depletes as time passes, with the seconds remaining shown big in the center + the word *"secunde."*
- A **reality-check card** (red): *"Erai pe cale să dai {sumă} lei"* + *"Adică ~N litri de benzină, aruncați pe un ecran care oricum câștigă."*
- At the very bottom: a responsible-gaming **helpline line**, and a small, deliberately unrewarding link *"Renunț și deschid aparatul"* (leaving is allowed — leaving does **not** reset the streak; the friction is the wait itself).

**State B — Held out (timer hits 0):**
- A lime check-burst, **"AI REZISTAT."**, sub *"Pofta a trecut. Banii au rămas la tine. Seria e intactă."*, and a lime button **"Înapoi, mai puternic"** → Home. This counts as a "craving beaten" (feeds a badge).

---

### 5.5 Progres — achievements & "what that money buys"

**Purpose:** the private trophy room + a motivating money-translation. **View-only**, reached from the tab bar.

**Layout:**
- Title **"Progresul meu"**, sub *"Realizările și economiile tale — private, doar pentru tine."*
- **Insigne (badges).** Section header with an *"X / 9"* unlocked count. A 3-column grid of all badges: unlocked = lime tile with a check; locked = dark empty tile. Labels beneath.
- **"Ce-ți luai cu banii ăștia" (calculator).** A sub line *"Cu {sumă} strânși până acum:"* then a list of concrete things his saved money equals, each as **"N× thing"** (lime count) — e.g. *2× plinuri de benzină, 3× coșuri mari la supermarket…* Only items he can afford (count ≥ 1) are shown.

*(Badges and this calculator used to be on Home; they were intentionally moved here to keep Home focused.)*

---

### 5.6 Setări (Settings)

**Purpose:** the protective controls + account. Grouped cards, each group under a small uppercase label. Reached from the tab bar (also has a back chevron to Home).

Groups, in order:
1. **PROTECȚIE — "Blochează pariurile."** A highlighted card (lime-tinted) with a lime shield icon, description *"Aplicații și site-uri de cazino și pariuri. Lista se actualizează singură."*, and a master toggle **"Blocaj activ."** Below it, a card of **category toggles**: *Cazinouri & păcănele online · Pariuri sportive · Poker & table games · Reclame la pariuri.*
2. **CEL MAI PUTERNIC PAS — "Autoexcludere ONJN."** Explanatory card: *by law, every licensed operator in Romania must stop letting him play; the request is filed officially.* A red-outline button **"Înscrie-mă în autoexcludere."** Once enrolled, it swaps to a lime confirmation strip *"Ești înscris. Operatorii nu te mai lasă."*
3. **PREFERINȚE.** *Limbă* (tapping switches **Română ⇄ English** everywhere, live) and *Temă întunecată* (toggle; app is dark-first).
4. **CONT.** *"Am recăzut — resetează seria"* (amber; honest relapse — resets the streak to zero but **keeps history**; see §6) and *"Deconectează-te"* (red; → Login).

*(Removed by request and intentionally NOT present here: "persoană de încredere / trusted person," "reality-check zilnic," and a "panic button on home" toggle. The panic button is always on Home.)*

---

### 5.7 Garage (bottom sheet, from Home)

**Purpose:** show the full car/rank ladder and where he is.

A slide-up sheet (grab handle, title **"Garajul"**, ✕ to close, tap-outside to dismiss), sub *"Fiecare rang, o mașină mai bună. Ține seria."* A vertical list of **all tiers**: each row shows the **car silhouette**, its **model**, its **rank name**, and status:
- **Current** tier: lime outline + lime tag **"ACUM CONDUCI."**
- **Unlocked** past tiers: normal.
- **Locked** future tiers: dimmed + caption *"Se deblochează la N zile."*

---

## 6. The rules & numbers (the "brain")

All of this is **UX logic**, stated plainly — implement however you like.

### 6.1 Savings

- From onboarding: **sessions/week** (from the frequency choice) and **amount/session** (the slider).
- **Weekly loss** = sessions/week × amount/session. **Yearly loss** = weekly × 52. **Daily rate** = weekly ÷ 7.
- **Amount saved** = daily rate × (time elapsed since the quit moment). It should **increase continuously and visibly** (the Home jackpot ticks in real time, including fractional lei so the last digits move each second).
- Frequency → sessions/week mapping used in the prototype: Zilnic = 7 · De câteva ori pe săptămână = 3 · O dată pe săptămână = 1 · De câteva ori pe lună = 0.5.
- Number format is Romanian: `.` for thousands, `,` for decimals (e.g. `1.131,42 lei`).

### 6.2 Streak

- **Streak = whole days since the quit moment.** Onboarding sets the quit moment to "now" (Day 0). The demo entry seeds a populated account (~Day 12) so the app looks alive.
- **Relapse** ("Am recăzut") resets the quit moment to now (streak → 0, savings recount from now) but **history is preserved** (a bad day doesn't erase everything — this is emphasized in copy).

### 6.3 Car / rank ladder (by streak days)

| From day | Car (model) | Rank name (RO) | Look |
|---|---|---|---|
| 0 | Dacie rablă ("Rabla") | **Rabla** | dull grey, boxy, exhaust smoke, red warning light |
| 1 | Dacia | **Te-ai trezit** | clean, modest, blue-grey |
| 7 | VW Golf | **Ai prins viteză** | sportier, silver |
| 30 | BMW | **Băiat serios** | lower, darker, blue accent |
| 90 | Mercedes | **Șmecher** | sleek, silver/chrome |
| 365 | Mercedes-AMG | **Legendă** | near-black, lime accents, aggressive stance |

The car on Home is the current tier; the progress bar fills toward the next threshold; "Următoarea mașină în N zile" = days remaining to next tier. At the top tier, show a "you reached the top" line instead.

### 6.4 Badges (9 total; unlocked when condition met)

Prima zi (streak ≥ 1) · Poftă învinsă (≥ 1 panic held-out) · O săptămână (≥ 7) · 1.000 lei (saved ≥ 1000) · O lună (≥ 30) · 5 pofte învinse (≥ 5 panic held-out) · 5.000 lei (saved ≥ 5000) · 90 de zile (≥ 90) · Un an întreg (≥ 365).

### 6.5 "Ce-ți luai" calculator

Each item has a lei "unit price"; **count = floor(saved ÷ unit)**; show items with count ≥ 1, richest first. Units used: plin de benzină 400 · coș mare la supermarket 300 · rată la un telefon nou 250 · zi de vacanță pe litoral 350 · rată la o mașină decentă 1500. (Tune freely; keep them concrete and locally relatable.)

### 6.6 Panic

- **Default lockout = 60 seconds** (make it configurable; 15–120s is a sensible range).
- Message rotates roughly every ~8 seconds through the set in §7; some inject the live saved total and streak.
- **Reality-check equivalence** shown = amount/session ÷ 8 ≈ **litres of fuel** (a concrete, grammar-safe unit). You may swap the equivalence, but keep it concrete.
- Leaving early does **not** break the streak; the deterrent is the wait + the message.

### 6.7 Blocking & ONJN (behavior, not mechanism)

- The blocker has a **master switch** + **category switches**; conceptually it "updates itself" for new sites. *You decide the real enforcement mechanism.*
- **ONJN self-exclusion** is presented as the strongest, legally-binding step (official request to the national regulator). Treat it as a real, separate action with a confirmed state. *Verify the real process before shipping.*

### 6.8 Privacy

No accounts-of-others, no sharing, no leaderboard, no friend graph, no visibility of losses to anyone. Keep it that way.

---

## 7. Copy & localization

The app ships **Romanian (primary) + English**, switchable live from Settings; every string exists in both. Below are the load-bearing strings (RO) plus tone. (The reference prototype contains the complete EN mirror.)

### 7.1 Key strings (RO)

- **Login headline:** "Nu fi fraierul aparatelor."
- **Login sub:** "Blochezi pariurile, vezi cât strângi și te oprești fix când erai pe cale să faci prostia."
- **Login stat:** "Românii pierd 2 miliarde € pe an la aparate."
- **Onboarding reveal:** "Aparatul e reglat să câștige. Mereu."
- **Commit:** "Gata cu fraierul. De azi banii rămân la tine." · CTA "ÎNCEP ACUM."
- **Home savings label:** "AI STRÂNS" · sub "de când nu mai hrănești aparatul."
- **Panic title:** "STAI. RESPIRĂ."
- **Family reminder:** "Băieții tăi te văd. Fii omul pe care-l admiră, nu ăla care dă salariul pe aparate."
- **Relapse:** "Am recăzut — resetează seria" · sub "Cinstit e mai bine. Istoricul rămâne, o repornim de la zero."

### 7.2 Panic messages (RO) — rotate through these

1. "Aparatul câștigă mereu. Tu ești singurul care pleacă cu buzunarele goale."
2. "Te simți norocos? Norocul e povestea pe care ți-o spune casa ca să rebagi."
3. "Peste un minut pofta trece. Banii, dacă îi dai, nu se mai întorc."
4. "Ai strâns {sumă}. Nu-i da înapoi într-o singură seară."
5. "Ce zice nevastă-ta când vede iar contul gol?"
6. "Ai fost mai deștept {streak} zile la rând. Nu strica totul acum."
7. "Singurul câștig sigur: închizi telefonul acum și pleci cu banii."

Reality-check line: "Erai pe cale să dai {sumă} lei — adică ~{N} litri de benzină, aruncați pe un ecran care oricum câștigă."

Resisted: "AI REZISTAT." · "Pofta a trecut. Banii au rămas la tine. Seria e intactă." · button "Înapoi, mai puternic."

### 7.3 Tone guide (recap)

Firm, blunt, pride/money/family — never insult. Short. Romanian slang welcome. Diacritics correct. English mirror keeps the same bite without literal-translating slang ("fraier" → "the machine's fool," not "sucker word-for-word").

### 7.4 Responsible-gaming note

A helpline line appears on the Panic screen. The prototype uses **"Joc Responsabil · 0800 800 099"** as a placeholder — **verify the correct, current national helpline** and present it responsibly. This is a serious-topic app: never make the "leave / give up" path feel punishing, and always keep a real help route reachable.

---

## 8. States, edge cases & things to decide/source

**States to handle:**
- **Day 0 / fresh account:** savings ≈ 0, car = Rabla, most badges locked, empty-ish calculator. This is intentional and motivating ("look where you start"). Make it feel like a beginning, not a bug.
- **Empty calculator** (nothing affordable yet): show an encouraging placeholder rather than a blank list.
- **Relapse:** streak resets, savings recount, history kept; confirm the action; keep tone supportive-but-firm.
- **Language switch:** must retranslate the entire UI instantly, including numbers/labels.
- **Top tier reached (365+):** replace "next car" with a "you reached the top / Legendă" state.
- **Very large savings:** the jackpot digit row must stay legible (more digits → smaller cells or graceful scaling).
- **Panic while offline / mid-craving:** the countdown must work with zero dependencies and never fail to load.

**You must decide or source (out of scope for this doc):**
- The **real blocking mechanism** and the **actual list** of Romanian betting apps/sites (kept generic in the prototype).
- The **real ONJN self-exclusion** flow and its confirmed states.
- The **verified helpline** number/partner.
- **Auth** providers/behavior for Apple/Google and any "returning user" logic.
- Whether cars stay as **minimalist silhouettes** or become richer **illustrations** (either is fine if progression reads clearly).
- Any **notifications** (a daily reality-check concept was removed from Settings UI, but you may implement it as a system-level feature if desired — keep it opt-in and private).

---

## 9. Suggested build priority

**MVP (the spine):**
1. Login → Onboarding (all 4 steps, including the house-edge reveal — it's the persuasion engine) → Home.
2. Home: rank/car, **live savings jackpot**, streak chip, **panic button**, family reminder.
3. **Panic flow** (countdown + rotating messages + reality-check + "held out" state).
4. Savings + streak + car-ladder logic (§6).

**Then:**
5. Progres page (badges + calculator).
6. Settings: blocking toggles, ONJN, language (full RO/EN), theme, relapse, sign-out.
7. Garage sheet.

**Polish last:**
8. Live-tick counter, marquee bulbs, ring depletion, bar-drain animation, entrances.
9. Real blocking + ONJN + helpline integration.

---

### One-line reminder to keep on the wall

> **Blocul ține aparatele departe · jackpotul îți arată cât aduni stând deștept · butonul de panică te oprește fix când erai pe cale să faci prostia. Nu ești bolnav — doar nu mai ești fraier.**
