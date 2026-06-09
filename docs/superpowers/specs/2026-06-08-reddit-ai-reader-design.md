# FeedDigest — Reddit + Gemini AI Reader — Design Spec

- **Date:** 2026-06-08
- **Status:** Approved
- **Primary goal:** A real, daily-use Reddit reader with Uzbek AI summaries.
  Priorities: reliable live Reddit + Gemini, pagination, robust error handling,
  speed. Mock data is a fallback only.

## 1. Scope

**In scope (v1)**
- Topic tabs on the home screen, configurable in Settings.
- Sortable feed (hot / new / top / rising) with cursor pagination + pull-to-refresh.
- Reddit-style post cards (subreddit, author, time, title, body preview, image,
  score, comments).
- Post detail screen: full text/image + best (top) comments.
- Two-part Uzbek AI summary (post summary + comments summary), shown separately.
- Search across Reddit (debounced).
- Settings: manage topics (add / edit / delete / reorder / reset), theme mode,
  API key status.
- Persistence of topics + theme via `shared_preferences`.

**Out of scope (v1)**
- Reddit account login, voting (upvote/downvote), personalized home feed.
  The app is built around user-configured subreddits, not a personal account.
- Fetching & summarizing external linked-article bodies (possible v2).
- Offline article caching beyond image caching.

## 2. Architecture

Feature-first + Riverpod 3 (verified against installed riverpod 3.2.1 /
flutter_riverpod 3.3.1). Each feature has three layers:

- `data/` — models, repository interface + implementations, services.
- `application/` — Riverpod providers / notifiers (state + orchestration).
- `presentation/` — screens and widgets.
- `core/` — shared config, theme, network, utils, cross-cutting models.

When no credentials are present the providers select **mock** implementations,
so the entire app is demoable offline.

```
lib/
  main.dart                 # load .env + prefs, ProviderScope overrides
  app.dart                  # MaterialApp, theme, themeMode
  core/
    config/   (env, app_config)
    theme/    (app_theme, app_colors)
    network/  (dio_client, ApiException)
    utils/    (formatters)
    models/   (topic)
    widgets/  (state_views)
  features/
    feed/      data(models, repository[+impl,+mock], auth) | application | presentation
    detail/    presentation (post detail)            # comments live in feed/data
    search/    application | presentation
    settings/  data(settings_repository) | application | presentation
    summary/   data(gemini_service, ai_summary) | application | presentation
    shell/     presentation (bottom nav)
```

## 3. Screens & navigation

Bottom navigation: **Asosiy (Home) / Qidiruv (Search) / Sozlamalar (Settings)**,
backed by an `IndexedStack` to preserve tab state.

- **Home** — `DefaultTabController` over the topic list; a sort `PopupMenu` in the
  app bar; each tab renders `FeedList(FeedQuery(subreddit, sort))`.
- **Post detail** — full post (title, body, image), then a list of top comments;
  an "AI Xulosa" action and "Open in browser". Reached by tapping a card.
- **Search** — debounced (450 ms) text field → `searchResultsProvider`.
- **Settings** — theme `SegmentedButton`, API status card, reorderable topic list
  with edit/delete, add, and reset-to-defaults.

## 4. Data layer

### Reddit
- `RedditRepository` interface: `fetchFeed`, `search`, `fetchComments`.
- `RedditRepositoryImpl`:
  - Auth: **installed_client** OAuth (client_id only, no secret) →
    `oauth.reddit.com`. Token cached ~1h, refreshed 60s early.
  - Fallback: public `www.reddit.com/*.json` when `REDDIT_USE_PUBLIC=true`.
  - All requests: descriptive `User-Agent`, `raw_json=1`.
  - Errors mapped to localized `ApiException` (403 / 404 / 429 / timeout).
- `MockRedditRepository`: realistic sample posts + comments, simulated latency,
  one extra page for pagination, query-aware search.

### Models
- `RedditPost` — defensive `fromJson` from a `t3` thing; extracts the best preview
  image; `summarizableText` getter for AI input. Equality by `id`.
- `RedditPage` — `posts` + `after` cursor; parses a `Listing`.
- `RedditComment` — id, author, body, score, time, depth; parsed from the comments
  endpoint, top-level only (top N by score).

## 5. AI summary (two-part)

- `commentsProvider.family<List<RedditComment>, RedditPost>` fetches comments once
  and is shared by both the detail screen and the summary, so comments are not
  fetched twice.
- `summaryProvider.family<AiSummary, RedditPost>`:
  1. awaits `commentsProvider(post)` for the top comments,
  2. calls `GeminiService.summarize(post, comments)`.
- **Single Gemini call, JSON response** (`responseMimeType: application/json`):
  returns `{ "post_summary": "...", "comments_summary": "..." }`. Prompt forces
  Uzbek, plain language; when there are no comments, `comments_summary` says so.
- `AiSummary { postSummary, commentsSummary }` model parses the JSON defensively
  (falls back to treating raw text as the post summary if JSON is malformed).
- `GeminiServiceImpl` (HTTP via dio, stable `generateContent` endpoint) vs
  `MockGeminiService` (clearly labeled DEMO output for both sections).
- The summary bottom sheet renders two sections: **📝 Post** and **💬 Izohlar**,
  with loading / error+retry / data states and copy.

## 6. State & persistence

- `topicsProvider` (Notifier<List<Topic>>) + `themeModeProvider`
  (Notifier<ThemeMode>), both backed by `SettingsRepository` over
  `shared_preferences`; every mutation persists. `sharedPreferencesProvider` is
  overridden in `main()`.
- `feedSortProvider` (Notifier<FeedSort>), `feedProvider`
  (AsyncNotifier.autoDispose.family) with `loadMore()`, `searchQueryProvider` +
  `searchResultsProvider`.

## 7. Error handling

Typed `ApiException` carries a localized Uzbek message and optional status. Every
async surface (feed, detail, search, summary) renders a friendly error with a
"Qayta urinish" retry. Reddit 403/429 and Gemini 400/403/429 have specific copy.

## 8. Configuration (`.env`)

Loaded by `flutter_dotenv` (registered as an asset). Optional — empty values →
mock. Keys: `GEMINI_API_KEY`, `GEMINI_MODEL` (default `gemini-2.5-flash`),
`REDDIT_CLIENT_ID`, `REDDIT_USER_AGENT`, `REDDIT_USE_PUBLIC`. A documented
`.env.example` ships alongside.

## 9. Testing & verification

- **Unit tests:** `RedditPost.fromJson`, `RedditComment.fromJson`,
  `RedditPage.fromListing`, `AiSummary` JSON parsing (incl. malformed),
  `Formatters` (compact number, time-ago), `ApiException` status mapping.
- **Widget smoke test:** app boots into the mock feed and renders cards.
- **Verification bar:** `flutter analyze` clean + successful compile + app runs
  against mock data. Live Reddit/Gemini cannot be exercised in this environment
  (no keys; Reddit blocks the sandbox), so they are wired but reported as
  untested-pending-keys — not claimed working.

## 10. Dependencies

`flutter_riverpod`, `dio`, `cached_network_image`, `shared_preferences`,
`flutter_dotenv`, `google_fonts`, `url_launcher`,
`flutter_web_auth_2`, `flutter_secure_storage` (added in the §11 addendum).

## 11. Addendum (2026-06-09): Reddit account features

Scope change approved by the user: §1 originally excluded account login/voting.
The user requested **login, real subscriptions, voting, and a personalized home
feed** (no comment-writing). Added:

- **OAuth** (Authorization Code, installed app) via `flutter_web_auth_2`.
  Scopes `identity mysubreddits read vote subscribe`; `duration=permanent`.
  Redirect `feeddigest://oauth2redirect` (registered in Android manifest +
  iOS Info.plist). Refresh token in `flutter_secure_storage`; access token in
  memory with **single-flight** refresh (`RedditUserSession`).
- **Live token provider** (`RedditTokenProvider`) read per-request by the repo:
  user token → app-only token → public. `redditRepositoryProvider` watches
  `isLoggedInProvider`, and feeds watch the repository, so login/logout
  **reactively** refetches everything (no manual invalidation).
- **Repo additions:** `fetchHomeFeed` (`/{sort}` on oauth = front page),
  `fetchMySubreddits` (`/subreddits/mine/subscriber`), `setSubscribed`
  (`/api/subscribe`), `vote` (`/api/vote`).
- **UI:** logged-in tabs = `[Bosh sahifa] + real subscriptions`; login/logout in
  Settings; subscribe button on each subreddit feed header + post detail;
  optimistic up/down vote on card + detail (`votesProvider` override map).
- **Untestable here:** the OAuth/vote/subscribe round-trips need a real browser +
  account + device deep-link. Token/URL/parse/vote-delta logic is unit-tested;
  the live flow is device-only. Setup + on-device failure checklist in README.
