# FeedDigest — MVVM Scraping Rebuild — Design

Date: 2026-06-20
Status: Approved

## Goal

Rebuild `lib/` as a clean, serverless Flutter app that scrapes Reddit via the
public `.json` endpoints (no OAuth), summarizes posts into Uzbek with the Gemini
API (BYOK), and lets the user save favorites. Architecture is MVVM with Riverpod
Notifiers as ViewModels. All Dart code is comment-free.

Source of truth for behavior: `docs/researches/plans.md`. Reddit JSON shapes:
`docs/researches/structures.md`, `search_structure.md`, with real samples in
`example.json` and `search_example.json`.

## Decisions (locked)

1. Scope: strip to the brief. Anonymous `.json` scraping, no OAuth. Screens:
   Feed, Search, Favorites, Settings, plus an on-demand Summary sheet. Drop
   OAuth login, voting, subscriptions, and the comment-detail view.
2. ViewModel layer: Riverpod 3.x `Notifier` / `AsyncNotifier` classes.
3. Local storage: `hive_ce` + `hive_ce_flutter`. Two boxes — `favorites`
   (permanent) and `summaries` (dedup cache) — plus a `topics` box.
4. Models: lean. Only the fields the UI uses, with tolerant `fromJson`.
5. Feed source: multi-topic, user-managed. User maintains a list of subreddits
   in Settings; Feed shows top-of-week posts for the selected topic. Search
   finds posts to read or topics to add.
6. Summaries: on-demand (tap to summarize). Result cached/deduped in Hive so a
   post is summarized at most once. Protects the ~250/day free tier.

## Architecture

MVVM with a shared Model layer and feature-scoped ViewModel/View (structure
option A).

- Model = `models/` (pure data classes) + `data/` (repositories and services).
  Repositories have no Flutter UI imports.
- ViewModel = Riverpod `Notifier`/`AsyncNotifier`, one per feature. Holds state,
  calls repositories, exposes actions. No widget imports.
- View = screens and widgets. Read state via `ref.watch`; trigger actions via
  `ref.read(...).method()`. No business logic.

### File tree

```
lib/
  main.dart                     bootstrap: Hive init, secure store, ProviderScope
  app.dart                      MaterialApp + theme + HomeShell
  core/
    config/app_config.dart      host list, default topics, User-Agent, gemini model id
    network/reddit_client.dart  dio wrapper: UA header + host fallback (www -> old -> redlib)
    storage/hive_boxes.dart     box-name consts + openBoxes()
    storage/secure_store.dart   flutter_secure_storage wrapper (Gemini key)
    theme/app_colors.dart
    theme/app_theme.dart
    utils/formatters.dart       timeAgo, compactScore
    widgets/state_views.dart    loading / error / empty
  models/
    reddit_post.dart            lean scraping class + tolerant fromJson
    topic.dart                  label + subreddit
    ai_summary.dart             postId + summary text
  data/
    reddit_repository.dart      topPosts(sub, t, limit) + searchPosts(q, sub?, sort, t, limit)
    gemini_repository.dart      summarize(post) -> Uzbek text (BYOK)
    favorites_repository.dart   Hive box 'favorites': add/remove/list/contains
    summary_cache_repository.dart Hive box 'summaries': get/put by post id
    topic_repository.dart       Hive box 'topics': CRUD topics
    settings_repository.dart    Gemini key get/set via secure_store
  features/
    shell/view/home_shell.dart            bottom nav: Feed / Search / Favorites / Settings
    feed/viewmodel/feed_viewmodel.dart    AsyncNotifier: top posts for selected topic
    feed/view/feed_screen.dart
    feed/view/widgets/post_card.dart
    feed/view/widgets/post_image.dart
    feed/view/widgets/post_skeleton.dart
    feed/view/widgets/topic_bar.dart
    search/viewmodel/search_viewmodel.dart  Notifier: query -> results
    search/view/search_screen.dart
    favorites/viewmodel/favorites_viewmodel.dart  Notifier: list + toggle
    favorites/view/favorites_screen.dart
    summary/viewmodel/summary_viewmodel.dart  family Notifier: cache -> Gemini -> store
    summary/view/summary_sheet.dart
    settings/viewmodel/settings_viewmodel.dart  Gemini key + topics CRUD
    settings/view/settings_screen.dart
    settings/view/topic_editor_sheet.dart
```

## Models (lean)

### RedditPost
Fields: `id`, `title`, `selftext`, `url`, `permalink`, `author`, `subreddit`,
`subredditNamePrefixed`, `score`, `numComments`, `createdUtc`, `thumbnail`,
`isSelf`, `over18`, `domain`, `upvoteRatio`, `linkFlairText`.

Helpers: `fullPermalink` (`https://www.reddit.com` + permalink), `hasThumbnail`
(thumbnail is a real http url, not `self`/`default`/`nsfw`/empty), `contentText`
(selftext when self-post else url).

`fromJson` tolerant: missing fields default to empty/zero; numeric fields read
through `num` then `.toInt()`/`.toDouble()`; never cast `Map<String,dynamic>`
directly off a Hive read.

### Topic
Fields: `label`, `subreddit`. `displayName => 'r/$subreddit'`. Equality keyed on
lowercase subreddit. `fromJson`/`toJson` for Hive.

### AiSummary
Fields: `postId`, `summary`. `fromJson`/`toJson` for the summaries box.

## Data layer

### reddit_client
- dio instance with base options and required `User-Agent` header
  (`UzSummaryApp/1.0 (shaxsiy)`).
- Host fallback: try `www.reddit.com`, then `old.reddit.com`, then a Redlib
  mirror. On a non-2xx / connection error, advance to the next host. Throw a
  typed failure only after all hosts fail.
- Always builds requests with `Uri.https(host, path, queryParams)` so query
  strings (e.g. `flutter state management`) are encoded correctly.

### reddit_repository
- `topPosts(subreddit, {t = 'week', limit = 10})` -> GET
  `/r/{sub}/top.json` -> parse `data.children[].data` -> `List<RedditPost>`.
- `searchPosts(query, {subreddit, sort = 'top', t = 'month', limit = 25})` ->
  GET `/search.json` or `/r/{sub}/search.json` with `restrict_sr=true`,
  `type=link`. Same parse path. Search response is a single Listing object.
- Both filter out stickied / non-post children defensively.

### gemini_repository
- `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- Headers: `x-goog-api-key` from secure store, `Content-Type: application/json`.
- Body: `{ "contents": [ { "parts": [ { "text": <prompt> } ] } ] }`.
- Prompt: ask for a 3-4 sentence Uzbek summary, return only the summary. Feed it
  title + selftext (fall back to url for link posts).
- Parse `candidates[0].content.parts[0].text`. Throw a typed failure when the key
  is missing or the response shape is unexpected.

### favorites_repository / summary_cache_repository / topic_repository
- Hive-backed. Read maps with `Map<String,dynamic>.from(...)`.
- favorites: keyed by post id, stores the full `RedditPost.toJson`.
- summaries: keyed by post id, stores `AiSummary.toJson` (dedup).
- topics: stores the user topic list; seeded with `AppConfig.defaultTopics` on
  first run.

### settings_repository
- `getGeminiKey()` / `setGeminiKey(value)` via `secure_store`.

## ViewModels

- `FeedViewModel` (AsyncNotifier): holds selected topic + posts; `load()`,
  `selectTopic(topic)`, `refresh()`.
- `SearchViewModel` (Notifier): `query`, results, loading; `search(query)`,
  `clear()`.
- `FavoritesViewModel` (Notifier): list of saved posts; `toggle(post)`,
  `isFavorite(id)`, `remove(id)`.
- `SummaryViewModel` (family by post id, AsyncNotifier): resolves cache first,
  else calls Gemini, else stores.
- `SettingsViewModel` (Notifier): Gemini key presence + topics CRUD
  (`addTopic`, `removeTopic`, `saveKey`).

## Views

- `HomeShell`: bottom navigation across Feed / Search / Favorites / Settings.
- `FeedScreen`: topic bar + post list; each card shows title, meta, thumbnail,
  Summarize action, favorite toggle. Loading -> skeletons; error/empty ->
  `state_views`.
- `SearchScreen`: search field + results list (same post card).
- `FavoritesScreen`: saved posts with remove.
- `SummarySheet`: bottom sheet showing the Uzbek summary with loading/error.
- `SettingsScreen`: Gemini key field (masked) + topic list editor
  (`TopicEditorSheet`).

## Data flow examples

- Summarize: View tap -> `summaryViewModel(postId)` -> cache `get(id)`; hit ->
  return; miss -> `geminiRepository.summarize(post)` -> cache `put` -> state ->
  sheet renders.
- Feed load: `FeedViewModel.load()` -> `redditRepository.topPosts(selected.sub)`
  -> state `AsyncData(posts)`; favorites box consulted per card for the toggle.

## Dependencies

- ADD: `hive_ce`, `hive_ce_flutter`.
- REMOVE: `flutter_web_auth_2`, `shared_preferences`, `flutter_dotenv` (and the
  `.env` asset entry). BYOK key lives in secure storage; no `.env` default.
- KEEP: `dio`, `flutter_riverpod`, `flutter_secure_storage`,
  `cached_network_image`, `url_launcher`, `google_fonts`, `cupertino_icons`.

## Removed from current lib

OAuth (`features/auth/`), voting, subscriptions, mock repository, and the
comment-detail view (`post_detail_screen`, `comment_tile`). Salvaged and
rewritten clean: theme, formatters, state views, post card/image/skeleton,
Gemini logic, topic editor.

## Testing

Rewrite unit tests:
- `RedditPost.fromJson` against the real `example.json` and `search_example.json`
  fixtures (top listing is an array of 2 listings; search is a single listing).
- Formatters (`timeAgo`, `compactScore`).
- Repository parsing with stubbed dio responses.
- Drop OAuth / vote / comment tests.

## Non-goals

No backend, no OAuth, no voting/subscriptions, no nested comment rendering, no
auto-summarize of whole feeds.
