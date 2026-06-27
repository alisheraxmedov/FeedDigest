# FeedDigest

A developer-news reader that aggregates topics from **Hacker News** and
**dev.to**, with search and on-demand **AI summaries** (Google Gemini) so you can
get the gist of an article quickly. Built with Flutter + Riverpod 3 (MVVM).

## Features

- 🏠 **Home feed** — your subscribed topics from Hacker News and dev.to, merged
  and de-duplicated.
- 🔀 **Source switch & sort** — pick Hacker News or dev.to; sort by newest or
  popular.
- 🔢 **Pagination** — a numbered pager at the end of the feed (`‹ 1 2 3 ›`).
- 🔁 **Pull-to-refresh** on the feed.
- ➕ **Topics** — subscribe / unsubscribe to the tags that build your feed.
- 📄 **Article detail** — full text rendered as Markdown (dev.to) or HTML
  (Hacker News), with a link to the original.
- ✨ **AI summary** — a detailed Gemini summary of the article, in your chosen
  language (Uzbek / Russian / English).
- 🔎 **Search** — search articles on the active source.
- 💾 **Saved** — bookmark articles, filterable by topic.
- ⚙️ **Settings** — Gemini API key, source, app language, AI-summary language,
  theme (system / light / dark).
- 🎨 Polished UI — Outfit + Inter typography, Lottie illustrations for
  empty/loading/error states, and localized into Uzbek, Russian and English.
- Topics, theme and language are persisted locally (Hive); the Gemini key is kept
  in secure storage.

## Architecture

Feature-first **MVVM** on **Riverpod 3** (no code generation):

```text
lib/
  core/        config, prefs, providers (DI), sources (HN + dev.to),
               storage (Hive + secure store), theme, widgets
  data/        repositories (favorites, gemini, settings, subscription,
               summary cache)
  features/
    feed/      view/ (+ widgets) · viewmodel/
    search/    view/ · viewmodel/
    favorites/ view/ · viewmodel/
    settings/  view/ · viewmodel/
    summary/   view/ · viewmodel/
    subscriptions/ view/ · viewmodel/
    shell/     view/ (bottom nav)
  l10n/        ARB files (en / ru / uz)
  models/      Article, AiSummary, Subscription
```

- A **View** (`ConsumerWidget`) renders state and forwards intents; its
  **ViewModel** (a Riverpod notifier) holds the logic and calls repositories.
- `ArticleSource` is the common interface; `HackerNewsSource` and `DevtoSource`
  implement it. Networking is `dio`; persistence is `hive_ce` +
  `flutter_secure_storage`.

## Getting started

```bash
flutter pub get
flutter run
```

- The Hacker News and dev.to APIs are public — no key required to browse.
- For AI summaries, open **Settings** and paste a Gemini API key
  (https://aistudio.google.com/apikey). The key is stored in secure storage.

## Test

```bash
flutter analyze   # clean
flutter test      # unit + widget tests
```

## Changelog

See [`CHANGESLOGS/CHANGELOG.md`](CHANGESLOGS/CHANGELOG.md) for the full history of
changes.
