# Subscriptions Feature — Design

Date: 2026-06-20
Status: Approved (revised per docs/researches/notes.txt review)

## Goal

Let the user subscribe to subreddits (one-tap) from two places — subreddit
search results and post cards — persist subscriptions locally, and show an
aggregated "all subscriptions" news feed on next launch.

`clan = subreddit` (a single community, like a Telegram/YouTube channel). No
groups, no multireddit → no many-to-many → no normalization.

## Decisions (locked)

1. Subscribe from BOTH subreddit search (communities) and post cards.
2. Data model: single `subscriptions` Hive box. Each record =
   `{ id (subreddit lowercase), label, subreddit, createdAt }`. No Topic
   catalog, no FK, no ensureTopic (YAGNI for a single-user local app).
3. Feed: aggregated. "Hammasi" merges top posts from all subscriptions; chips
   filter to one subreddit.
4. Aggregation safety: each per-subreddit fetch wrapped in
   `.catchError((_) => <RedditPost>[])` so one failing subreddit never collapses
   the whole feed.
5. Fetch concurrency limited to `AppConfig.fetchConcurrency = 5` (batched) to
   avoid Reddit blocking many parallel `.json` calls.
6. Summaries stay lazy/on-demand (already the case) — never auto-summarize the
   feed (protects Gemini quota).
7. Seeding is idempotent: default subreddits seeded only on true first run,
   guarded by a `seeded` flag in a `meta` box. Unsubscribing everything and
   reopening does not re-add defaults.
8. Merge order: sort by `score` desc, dedup by post id. Known tradeoff: large
   subreddits dominate; acceptable for MVP.

## Replaces

`Topic` model, `topic_repository.dart`, `topics` box, `topic_editor_sheet.dart`,
and the `topicsViewModelProvider` / `selectedTopicProvider` concepts. They are
removed and replaced by the subscription equivalents below.

## Models

### Subscription (`lib/models/subscription.dart`)
Fields: `id`, `label`, `subreddit`, `createdAt` (DateTime).
- `Subscription.create(subreddit, label, createdAt)` factory sets
  `id = subreddit.toLowerCase()`.
- `fromJson`/`toJson` — `createdAt` stored as millisecondsSinceEpoch int.
- Equality keyed on `id`.

### Subreddit (`lib/models/subreddit.dart`, transient — not persisted)
Fields: `name` (display_name), `namePrefixed` (display_name_prefixed), `title`,
`subscribers` (int), `icon`, `publicDescription`.
- `hasIcon` getter (icon is a real http url).
- tolerant `fromJson` (reads `community_icon` else `icon_img`).

## Storage

`HiveBoxes`: `favorites`, `summaries`, `subscriptions`, `meta`. (drop `topics`)
- `meta` box holds `seeded` flag.

## Repositories

### SubscriptionRepository (`lib/data/subscription_repository.dart`)
Constructed with the `subscriptions` box and the `meta` box.
- `all()` → `List<Subscription>` sorted by `createdAt` ascending.
- `isSubscribed(String id)`.
- `subscribe(String subreddit, {String? label})` — keyed by lowercase id; sets
  `createdAt` now; label defaults to subreddit.
- `unsubscribe(String id)`.
- `toggle(String subreddit, {String? label})`.
- `seedDefaultsIfNeeded()` — if `meta.get('seeded') != true`, add
  `AppConfig.defaultSubreddits`, then set `seeded = true`.

### RedditRepository (extend)
- `searchSubreddits(String query, {int limit})` → GET
  `/subreddits/search.json?q=...&limit=...` → parse t5 children →
  `List<Subreddit>`.

## Config

`AppConfig`:
- `defaultTopics` → `defaultSubreddits`: `const` list of records
  `({String label, String subreddit})` (Flutter/FlutterDev, programming,
  technology).
- add `fetchConcurrency = 5`.

## ViewModels

### SubscriptionsViewModel (`lib/features/subscriptions/viewmodel/subscriptions_viewmodel.dart`)
`NotifierProvider<SubscriptionsViewModel, List<Subscription>>`.
- `build()` → `repo.seedDefaultsIfNeeded(); return repo.all();`
- `isSubscribed(id)`, `toggle(subreddit, {label})`, `unsubscribe(id)` — each
  mutates the repo then sets `state = repo.all()`.

### FeedViewModel (rework)
- `selectedSubredditProvider` (`NotifierProvider<SelectedSubreddit, String?>`):
  `null` = "Hammasi". Resets to null if the selected id is no longer subscribed.
- `FeedViewModel.build()`:
  - subs = `ref.watch(subscriptionsViewModelProvider)`; sel =
    `ref.watch(selectedSubredditProvider)`.
  - if subs empty → `[]`.
  - if sel != null → `topPosts(sel)`.
  - else → batched fetch (chunk = `fetchConcurrency`) of `topPosts` per sub, each
    `.catchError((_) => <RedditPost>[])`, then `aggregate(results)`.
- `aggregate(List<List<RedditPost>>)` (pure static): flatten, dedup by id, sort by
  score desc. Unit-tested.
- `refresh()` re-runs the current build.

### SubredditSearchViewModel (`lib/features/search/viewmodel/subreddit_search_viewmodel.dart`)
`AsyncNotifier<List<Subreddit>>`: `search(query)`, `clear()`.

### SettingsViewModel
Remove topic management (moved to SubscriptionsViewModel). Keep Gemini key
actions.

## Views

- `subscription_bar.dart` (replaces `topic_bar.dart`): chips `["Hammasi"]` +
  one per subscription; tap sets `selectedSubredditProvider`.
- `feed_screen.dart`: use the subscription bar; if no subscriptions → EmptyView
  "Obuna bo'ling — qidiruvdan hamjamiyat qo'shing".
- `post_card.dart`: add a follow toggle (person_add / person_remove) bound to
  `subscriptionsViewModelProvider` for `post.subreddit`.
- `search_screen.dart`: `SegmentedButton` — "Postlar" | "Hamjamiyatlar".
  Communities mode lists `subreddit_tile.dart` rows (icon, r/name, subscriber
  count, subscribe toggle).
- `subscription_editor_sheet.dart` (replaces `topic_editor_sheet.dart`): add a
  subreddit by name + list current subscriptions with unsubscribe.
- `settings_screen.dart`: "Mavzularni boshqarish" → "Obunalarni boshqarish".

## Testing

- `Subscription.fromJson`/`toJson`/equality/default id.
- `Subreddit.fromJson` (community_icon and icon_img fallback).
- `SubscriptionRepository`: subscribe/unsubscribe/toggle + idempotent seeding
  (temp Hive, subscriptions + meta boxes).
- `RedditRepository.searchSubreddits` parse (inline t5 fixture).
- `FeedViewModel.aggregate` pure function (dedup + sort).
- Widget tests stay pure (no ProviderScope graph — that hangs the test isolate).

## Non-goals

No multireddit/groups, no recommended-communities screen, no reference counting,
no auto-summary of the feed.
