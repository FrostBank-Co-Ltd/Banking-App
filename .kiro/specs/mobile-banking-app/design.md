# Design Document

## Overview

FrostBank Mobile is a Flutter application that runs fully offline against a mock repository layer. This design covers the **MVP slice**: a polished read only showcase that runs on Android, iOS, and Flutter web.

MVP scope (in this slice):

- Splash with session resolution
- Demo login with validation and inline errors
- Dashboard with account chips, balance, cards carousel, quick actions, Finance Hub links, recent transactions, promotions
- Account detail, card detail, transaction history with search and filters, transaction detail
- Profile with theme control, balance masking, logout
- Design system, motion system, loading / empty / error states, accessibility, mock data layer

Deferred to later slices (documented, not built here): transfer, deposit, QR payment, register, forgot password, savings, crypto, split bills, time deposit, notifications write paths, PIN and biometric App Lock, disk persistence. Finance Hub entries and mutating quick actions route to a shared "not in this build" screen so no control is a dead end.

## Architecture

Layered, one direction of dependency: presentation depends on domain, domain owns the repository contracts, data implements them.

```
lib/
  main.dart                      app entry, ProviderScope
  core/
    design/tokens.dart           color, radius, spacing, elevation tokens
    design/typography.dart       Outfit / Geist / GeistMono scale
    design/theme.dart            light and dark ThemeData from tokens
    design/motion.dart           durations, curves, reduced motion resolution
    format/money.dart            currency and quantity formatting
    format/dates.dart            day headers and relative timestamps
  domain/
    models/                      Account, BankCard, Txn, Promo, UserProfile
    repositories/                abstract contracts
  data/
    seed/mock_seed.dart          seeded believable data, marked as mock
    mock_repositories.dart       in memory implementations with latency
  state/
    providers.dart               Riverpod providers for every read
    session_controller.dart      auth state, demo credential check
    preferences_controller.dart  theme mode, balance masking
  presentation/
    router.dart                  go_router config, guard, shell
    shell/app_shell.dart         floating pill bottom navigation
    screens/                     one file per screen
    widgets/                     shared presentation widgets
```

### Rationale

- **Riverpod** for state: `AsyncNotifier` free `FutureProvider` families give loading, data, and error branches for free, which maps directly onto the required loading skeleton, empty state, and error state.
- **go_router** for navigation: declarative routes plus a single `redirect` callback is the cheapest correct place for the authentication guard, and `StatefulShellRoute.indexedStack` preserves each branch's navigation stack and scroll offset.
- **Repository interfaces** keep every widget free of data source knowledge, so a real API becomes a second implementation of the same contracts.

## Design System

### Color tokens

Transcribed exactly from the brand palette. `FrostBankColors` holds the raw values, `AppTokens` exposes the light and dark semantic resolution through a `ThemeExtension`, so widgets read `context.tokens.textSecondary` and never a raw hex.

| Group | Tokens |
| --- | --- |
| Primary | deepNavy `#0B0D2B`, primaryPurple `#2B1E6B`, primaryBlue `#1565E0`, vibrantBlue `#6A5CFF`, skyBlue `#BFD6FF` |
| Gradients | primary `#0B0D2B` to `#1565E0`, secondary `#2B1E6B` to `#BFD6FF`, card `#1E1B4B` to `#00D4FF` |
| Neutral | textPrimary `#0F1123`, textSecondary `#475569`, border `#CBD5E1`, surface `#F1F5F9`, backgroundLight `#F8FAFF`, background `#FFFFFF` |
| Semantic | success `#22C55E`, info `#1976D2`, warning `#F59E0B`, error `#EF4444` |
| Interactive | primary `#2B1E6B`, hover `#3C2A8C`, active `#6A5CFF`, secondary `#EEF0FF`, disabled `#E2E8F0` |

Dark mode keeps brand identity by darkening surfaces toward `deepNavy` and lifting text to a near white, holding at least 4.5:1 for body text and 3:1 for large text and interactive boundaries. The single accent is `vibrantBlue`; every active indicator, underline, and focus ring resolves to it.

### Radius, spacing, typography

- Radius scale, five steps: `xs 8`, `sm 12`, `md 16`, `lg 24`, `xl 32`, plus a `pill` helper for fully rounded controls.
- Spacing scale on a 4 logical pixel unit: `x1 4` through `x16 64`.
- Type scale: `display`, `headline`, `title`, `body`, `label`, `numeric`. Outfit for display and headline, Geist for title, body, and label, GeistMono for every monetary figure, quantity, and card digit. The fonts ship as variable TTFs, so each step sets `fontVariations` alongside `fontWeight` to get the true weight instance rather than a synthesised one.

Missing token lookups fail loudly: `AppTokens.of(context)` asserts with a named message when the theme extension is absent.

## Motion System

`Motion` exposes three duration bands (`short 180ms`, `medium 300ms`, `long 600ms`) and exactly three curves (`standard`, `emphasized`, `linear`). Only opacity, translation, scale, and rotation are animated.

Reduced motion is resolved once from `MediaQuery` (`disableAnimations` or `accessibleNavigation`) and collapses every duration to zero, so transitions render their end state immediately. The splash indicator is the only repeating animation in the application and its controller is disposed when the sequence completes. Every animation carries a one line comment stating whether it serves hierarchy, storytelling, feedback, or state transition.

## Data Layer

`MockDataSource` is a single seeded in memory store shared by all repositories. Reads resolve after a randomised 300ms to 900ms delay so skeletons are observable. An `errorSimulation` set lets a developer force a domain error per repository to exercise error states.

Seed content, all marked as mock in code:

- 3 accounts: Everyday Wallet, Horizon Savings, Crypto Wallet, with Luhn valid masked identifiers
- 2 cards plus card metadata, one active and one frozen
- 44 transactions across 64 days, non rounded amounts, varied intervals, named merchants with categories, including one failed and one pending
- 4 promotions referencing named offers

For the MVP the store is in memory only. `PreferencesController` and `SessionController` hold state for the running session; swapping in a `Persistence_Store` is a later task and does not change any widget.

## Navigation

```
/splash                          resolve session, then redirect
/login                           demo credentials, guarded away when signed in
StatefulShellRoute.indexedStack  pill bottom navigation
  /                              dashboard
  /activity                      transaction history
  /hub                           Finance Hub index
  /profile                       profile and settings
/account/:id                     account detail
/card/:id                        card detail
/txn/:id                         transaction detail
/soon/:feature                   deferred capability notice
*                                error screen with a route back to the dashboard
```

The guard sends unauthenticated requests to `/login` and authenticated requests for `/login` to `/`. Tapping the active destination pops that branch to its first route. Shell transitions use opacity and translation inside the medium band.

## Presentation Patterns

- `AsyncSection<T>` wraps every asynchronous region and renders a shape matched skeleton, an empty state with one action, or an inline error with retry. This is the one place those three states are implemented.
- `Skeleton` blocks are wrapped in `IgnorePointer` and shimmer with a single opacity animation.
- `Pressable` gives every card, tile, row, and button a 0.98 scale on press for tactile feedback.
- `MoneyText` renders GeistMono figures, honours the masking preference, and exposes a semantic label that speaks the amount and currency in words.
- `ResponsiveShell` centres content and caps width at 520 logical pixels on wide viewports so the web build reads as a designed application rather than a stretched phone layout.
- Every tap target is at least 48 by 48 logical pixels, every icon only control carries a semantic label, and layouts are verified at a 1.3 text scale.

## Error Handling

| Failure | Handling |
| --- | --- |
| Repository error | `AsyncSection` inline message plus retry that returns to the skeleton state |
| Session resolution failure | Splash routes to login and states that the session could not be restored |
| Invalid credentials | Inline message above the primary action, entered email retained |
| Unknown route | Error screen with a control that returns to the dashboard |
| Deferred capability | Explicit notice screen naming the capability, with a route back |

## Testing Strategy

- Unit: money and date formatting, credential validation, transaction filtering.
- Widget: dashboard renders skeleton then data, login rejects a malformed email, transaction filter narrows the list, masking hides figures.
- Verification: `flutter analyze` clean, `flutter test` green, and a web build to confirm the three target platforms compile from one source.
