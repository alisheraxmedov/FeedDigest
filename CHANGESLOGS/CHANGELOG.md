# FeedDigest — Changelog

All notable changes to this project, newest first. Dates are ISO (UTC).

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
