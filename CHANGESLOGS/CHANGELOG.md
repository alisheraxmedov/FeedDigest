# FeedDigest — Changelog

All notable changes to this project, newest first. Dates are ISO (UTC).

---

## 2026-07-03 (sources)

### Feed sources — Lobsters, Habr, VC.ru

- **Three new article sources** behind the existing `ArticleSource` interface,
  raising the feed from Hacker News + dev.to to five sources. Selectable from the
  Settings "Manbalar" picker; the choice persists in Hive.
- **Lobsters** (`lobste.rs` open JSON API, no auth) — `LobstersSource` uses the
  `/t/<tag>.json` feed for real tags (rust, go, ai, security, …) and the
  `/hottest`|`/newest` feed otherwise. Link posts fetch their readable body on
  demand (like Hacker News).
- **Habr** and **VC.ru** (Russian IT / IT-business) via a new **generic RSS 2.0
  adapter** `RssSource` — one reusable class driven by a per-request feed-URL
  builder. Parses title/link/`content:encoded`/`dc:creator`/`enclosure` images and
  both ISO-8601 and RFC-822 dates. The full `content:encoded` HTML is cached per
  item so the reader/summary avoid a second fetch. Adds the `xml` package.
- **Topic filtering honors each source's real capability** (not a blanket
  client-side filter): Habr queries its full-text **search RSS** per topic
  (`order=date` newest / `relevance` popular); Lobsters uses the tag feed for real
  tags and a keyword filter for the rest; VC.ru (no per-topic RSS exists) keyword-
  filters its general feed. No fallback to unrelated items — a topic a source
  doesn't cover (e.g. Flutter on Lobsters/VC.ru) returns nothing rather than
  misleading general news.
- `FeedSource` gained `lobsters` / `habr` / `vcru`; the `activeSourceProvider` and
  `sourceIcon` switches handle every case. No Hive migration — `FeedSource.fromId`
  already falls back for unknown ids.
- Tests: parse coverage for `LobstersSource` and `RssSource` (ids, author forms,
  RFC-822 → UTC, content sink, malformed XML). `flutter analyze` clean.

---

## 2026-07-03 (later)

### Assets

- Force-tracked the in-app logo `assets/icons/feeddigest-1b-monogram-f.png`. The
  `assets/icons/` folder stays gitignored, but the monogram is loaded by the feed,
  settings, and onboarding screens and registered in `pubspec.yaml`, so a fresh
  clone or CI build previously failed with "asset does not exist". Tracking just
  the used file fixes the build without un-ignoring the whole folder.

---

## 2026-07-03

A full visual redesign to match the app icon, plus three new capabilities —
onboarding, connectivity awareness, and voice search. `flutter analyze` clean.

### UI redesign ("Neon Professional" dark / "Lumina Tech" light)

- **Icon-matched theme.** Rebuilt the dark and light `AppColors` / `AppPalette`
  tokens around the app icon's deep navy-teal surfaces and added a teal→cyan
  `brandGradient` (with `copyWith` / `lerp` support), plus `scrim`, `navBar`, and
  `bgGlow` tokens.
- **Shared widgets.** `NeonButton` now paints the brand gradient with a cyan glow
  and takes optional `height` / `radius`; added `Wordmark`, `GradientSparkTile`,
  `AiPill`, and `BrandSegmented`; `IconCircle` gained an optional rounded-square
  form.
- **Screens.** Restyled the feed (brand-logo header, redesigned post card with a
  source avatar and an AI pill), bottom nav, article reader (3-item app bar,
  inline reader toolbar, frosted action bar), AI summary sheet, search, saved,
  and the skeleton + empty states. No provider, view-model, or navigation logic
  was changed — presentation only.

### Settings

- The settings app bar shows the app icon as a tab and a **back button when the
  screen is pushed** — previously a fixed hub icon overrode the back button and
  stranded users who opened settings from the chat "add key" shortcut.
- Compacted the Gemini API-key card to match the design handoff.

### Onboarding

- Added a first-run intro screen (app icon, wordmark, tagline, three feature
  rows). Shown once via an `onboarding_seen` flag in the Hive `meta` box, with a
  gradient "Get started" action and a text shortcut into Settings for the API key.

### Connectivity

- Added an app-wide offline/online banner. `connectivity_plus` watches interface
  changes and a lightweight `generate_204` probe confirms real reachability, so a
  Wi-Fi with no uplink still reads as offline. Going offline shows a persistent
  banner; reconnecting shows a brief "back online" one.

### Voice search

- Added a hold-to-talk microphone button on the feed and search screens. It
  records a short WAV, sends the audio to Gemini, which returns a concise search
  query; the query then fills the search field and switches to the Search tab.
  The recorder and its temp file are always disposed and deleted, and the pulse
  animation controller is disposed with the widget.

---

## 2026-07-02

Feature work from the FEATURES.md roadmap: Sprint 1 (BYO-key hardening + summary
controls), Sprint 2 (AI daily digest + reminder), Sprint 3 (AI reading tools),
Sprint 4 (reading state, offline, data export), Sprint 5 (reading comfort), and
Sprint 6 (engagement + read-aloud).

### Post-review hardening (round 2)

A second full multi-agent review of the branch, fixing defects the analyzer and
the existing tests didn't catch. `flutter analyze` clean; **52 tests** (40 → +12
regression); `dart format` applied.

**Correctness (blocking)**

- **Cache eviction was not FIFO.** Both the summary and article-body caches
  derived eviction from `Box.keys`, which hive_ce sorts lexicographically rather
  than by insertion order — so the "oldest" evicted was really the
  alphabetically smallest key, and a newly written entry could be dropped the
  instant it was cached (e.g. a `devto-` key while the box was full of `hn-`
  keys), permanently defeating the cache and burning the user's Gemini quota.
  Each value now carries a `cachedAt` stamp and eviction removes the genuinely
  oldest entry; legacy plain-string body values are still read.
- **Uncaught async errors on disposed notifiers.** The chat and translation view
  models wrote `state` after an `await` with no `ref.mounted` guard, and the
  `catch` re-threw the same error — surfacing an uncaught async error whenever
  the sheet or detail screen was closed mid-request. Every post-await state write
  is now guarded.

**Correctness (should-fix)**

- **Chat could get permanently stuck.** A failed send left an unanswered user
  turn in the history, so the next request carried two consecutive `user` roles
  (a malformed multi-turn payload) and every following question failed too.
  Trailing unanswered user turns are stripped before the request is built.
- **Reading streak broke around DST.** The day index divided a local-midnight
  epoch by ms-per-day; across a DST transition consecutive local midnights aren't
  24h apart, so the streak wrongly reset or skipped a day twice a year. It is now
  computed from a UTC-anchored calendar date.
- **Gemini output-side blocks were mislabeled.** A response blocked by the safety
  filter *after* generation (candidate `finishReason` SAFETY/RECITATION) was
  reported as a generic `parse` error; it now maps to `blocked`.
- **Silent async failures are surfaced.** Saving the API key and
  enabling/scheduling the daily reminder could throw with no feedback; failures
  now show a SnackBar, and the notification preference is persisted only once the
  OS (re)schedule succeeds, so the switch can't show "on" while nothing is
  actually scheduled.

**Robustness / hygiene**

- The chat composer ignores submits while a send is in flight, so the input no
  longer clears and silently drops the typed question.
- `seedDefaultsIfNeeded` awaits its writes instead of firing them unawaited.
- The article-body cache write is best-effort — a Hive write failure no longer
  turns a successfully fetched body into an error for the reader.
- The detail "open article" button routes through the safe link helper
  (`Uri.tryParse`) instead of an unguarded `Uri.parse`.

**Tests**

- New regression tests: cache overflow eviction (summary + body, including legacy
  migration), Gemini `finishReason` mapping, DST-stable streak day index, and
  chat-history sanitization. Suite: **52 tests**, `flutter analyze` clean.

### Engagement & read-aloud (Sprint 6)

- **Reading streak** — consecutive days on which you opened an article, tracked
  locally (no account); a flame chip in the feed app bar shows the current
  streak.
- **Reading-time badge** — feed cards with enough body text show an estimated
  minutes-to-read badge for faster triage.
- **Read-aloud (TTS)** — AI summaries and the daily digest can be played aloud.
  Voice availability is checked per language and the control hides itself when no
  voice exists for the target locale (Uzbek TTS is absent on most devices), and
  Markdown is stripped before speaking.

Deferred: **§16 share-as-image-card** (off-screen RepaintBoundary capture +
native share, better validated on a device) and the full **§17 AI-scripted audio
digest** (the read-aloud above already narrates the digest text).

### UI polish

- Read articles dim in the search results too (consistent with the feed).
- Whole `lib/` reformatted for consistent style.

> Visual fine-tuning (spacing, motion, screenshot-driven refinement) was not done
> in this pass: it needs a device/emulator build, which was intentionally out of
> scope here. All new UI reuses the existing design system (AppPalette, NeonCard,
> shared sheet headers), so it is consistent with the current look.

### Reading comfort (Sprint 5)

- **Text size control** — the article detail screen has a text-size action that
  opens a slider; the chosen scale is persisted and composed with the system
  text scale (accessibility-friendly), so the whole article reflows live.

Deferred from Sprint 5, with reasons: **§15 generic RSS** (the `FeedSource` enum
is a single-select with an exhaustive switch; per-URL RSS needs an enum→registry
refactor plus a topic/search/pagination shim that can't be safely validated
without a device build), and **§11 highlights / §12 explain-a-term** (both need
in-rendered-text selection UX that is impractical to verify without a device).

### Reading state, offline & data ownership (Sprint 4)

- **Read state** — opening an article marks it read (local Hive); read cards dim
  in the feed so you can see what's new at a glance.
- **Offline read** — a resolved article body is cached (FIFO-capped at 200); if a
  later open fails with no network, the cached body is served, so previously
  opened articles still read offline.
- **Data export** — a Settings action exports subscriptions + saved articles as a
  JSON backup and the topics as an OPML file, then opens the share sheet. No
  backend or account: the user owns and can move their data.

### AI reading tools — translation + chat (Sprint 3)

- **Full-article translation** — the article detail screen can translate the
  whole body into the user's language (Uzbek/Russian/English), not just the AI
  summary. A translate action in the app bar toggles between the original and
  the translation; the Gemini prompt preserves Markdown and leaves code blocks
  and URLs untouched. Aimed at the underserved uz/ru dev audience reading
  English-only Hacker News / dev.to content. Translated once, then cached in
  state so toggling is free.
- **Chat with the article** — a per-article chat sheet (app bar action) where the
  reader asks follow-up questions ("explain this", "give a Python example") and
  Gemini answers grounded in the article text, multi-turn, in the user's
  language. Missing-key state routes to Settings.

### Security — BYO-key hardening

- Removed the bundled Gemini key fallback. The key now lives only in secure
  storage, entered by the user; the `.env` asset, `flutter_dotenv` dependency,
  and the dotenv bootstrap were removed so no key ships inside the APK/IPA.
- The summary sheet's "no key" state now shows an **Add key** button that routes
  to Settings instead of a dead retry.

### AI summaries

- **Summary depth toggle** — Brief (TL;DR) ↔ Detailed, persisted in Hive. The
  Gemini prompt is chosen per depth and language; the cache key now includes the
  depth so the two lengths don't collide.
- **Multi-article daily digest** — a one-tap "today's top stories" digest built
  from the feed's top 5 articles in a single Gemini call (titles + short snippets
  only, to stay within context and spare the user's quota), rendered as Markdown
  in a bottom sheet. Opened from an accent action in the feed app bar, shown only
  when the feed has items. Cached by language + article-id set.

### Notifications

- **Daily digest reminder** — an opt-in, fixed-time local notification
  (`flutter_local_notifications` + `timezone`) that reminds the user to open the
  app and read the digest. Toggle and time picker live in Settings; enabling
  requests OS permission first and re-arms the schedule with localized text. It
  is a reminder, not push content: the fresh digest is generated on demand when
  the user opens the app. Android boot receiver re-arms it after a restart.

### UI

- **Feed card redesigned (LinkedIn-style)** — full-width cover image, an author
  header (domain avatar, author, source · time, topic tag), the title, then a
  body snippet. Replaces the small side thumbnail.
- Shared `TopicBadge` moved to `core/widgets` so the feed, search, and saved
  cards render the tag identically.

### Data / storage

- Summary cache is capped at 200 entries with FIFO eviction so it can't grow
  unbounded on disk.

### Tooling

- Added `flutter_local_notifications`, `timezone`, `flutter_timezone`; enabled
  Android core-library desugaring (required by the notification plugin). Removed
  `flutter_dotenv`.
- `flutter analyze` clean; 40 tests pass; debug APK builds.

---

## 2026-06-26

### Post-review hardening

Fixes applied after a full multi-agent code review of the branch.

**Correctness**
- **Feed pagination dead-end fixed.** A page was reported as "has next" whenever
  it returned exactly `feedLimit` items, so tapping *next* could land on an empty
  page that replaced the list and the pager, trapping the user. The feed now
  fetches one extra probe item (`feedLimit + 1`); a next page exists only when
  that probe comes back, guaranteeing the next page is non-empty.
- **Feed error state.** When every subscribed topic fails to load, the feed now
  surfaces an error with retry instead of a misleading empty "nothing found".
- **Search race guard.** A slow earlier query can no longer overwrite the result
  of a newer one (monotonic request token).
- **Gemini safety-block handling.** A safety-filtered response is reported with a
  dedicated `blocked` code and a localized message instead of a generic parse
  error.

**Networking**
- Added `connectTimeout` / `receiveTimeout` / `sendTimeout` to the shared Dio
  client; Gemini requests use a longer receive timeout. Requests can no longer
  hang forever on a stalled socket.

**State / memory**
- `summaryViewModelProvider` and `articleBodyProvider` are now `autoDispose`, so
  opened summaries and full article bodies are released instead of being retained
  for the app lifetime.
- The default-topic seeding moved out of the subscriptions notifier's `build()`
  into `main()`, keeping the notifier build pure.
- Feed source/sort preferences are now awaited and flushed before state changes
  so they reliably persist.

**Architecture**
- Added `ArticleSource.fullBody(article)` so the article-body resolver no longer
  downcasts to the concrete `DevtoSource`.

**UI / UX**
- Localized the feed and search error messages (were raw exception strings).
- Pull-to-refresh keeps the current list visible instead of flashing the skeleton
  (`skipLoadingOnReload`).
- Overflow guards (maxLines/ellipsis/Flexible) on the article-detail topic line,
  author row, feed-card title and meta topic, so long localized text can't
  overflow.
- Search clear (✕) button now updates live while typing.
- Subscription editor and feed/saved lists respect the safe area / floating-nav
  inset (the AI summary sheet already did).
- Accessibility: bottom-nav tabs announce selected state; the add-topic and
  remove-bookmark icon buttons have tooltips/labels.
- The Lottie loader falls back to a spinner if the animation asset fails to load.

**Tooling / tests**
- Stricter lints enabled (`avoid_print`, `unawaited_futures`,
  `use_build_context_synchronously`, `prefer_final_locals`).
- New tests: feed pagination (`pageFromRaw` trim + has-next, including the
  exactly-`feedLimit` no-trap case) and source page indexing (Hacker News
  0-indexed, dev.to 1-indexed, search pinned to first page). Suite: 32 tests,
  `flutter analyze` clean.

### UI redesign — ente-inspired aesthetic

- **Typography:** Outfit (display/titles) + Inter (body); titles routed through
  the theme `TextTheme` at weight 600.
- **Lottie illustrations** for the loading, empty (feed/search/saved) and error
  states (`assets/lottie/`).
- **hugeicons** line icons for the bottom navigation and the AI summary header.
- **Numbered pagination** footer at the end of the feed list (`‹ 1 2 3 ›`), with
  `page` support added to the Hacker News and dev.to sources.
- Card press micro-interaction (scale 0.98), 18px button radius, removed the neon
  glow for a calmer surface; AI summary sheet `useSafeArea` + drag handle.
- Fixed bottom-navigation label overflow in Russian (single line + `FittedBox`).

### Data source

- Replaced the dead Reddit `.json` scraping (HTTP 403 since 2025) with Hacker News
  (Algolia Search API) and dev.to (Forem API). See `../PLANS.md` for the history.

> Note: the Gemini API key is provided by the user in Settings (stored in secure
> storage). A real key must not be bundled in the app binary.
