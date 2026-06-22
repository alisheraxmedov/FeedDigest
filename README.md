# FeedDigest

A developer news reading application — aggregating topics from **dev.to** and **Hacker News**, with search and short summaries (post + comments separately) using **AI**.

## Features

- 🏠 **Home page** — combined feed of your favorite dev.to and Hacker News topics.
- ➕ **Subscribe / unsubscribe** — manage your topics and tags in the settings.
- 📰 **Multiple Sources** — reads articles from dev.to API and Hacker News API.
- 🔀 Sorting: latest / top / rising, infinite scroll, pull-to-refresh.
- 🖼️ Developer-friendly cards — title, source, score, comments count.
- 📄 Post detail screen — full text + top comments.
- ✨ **AI Summary** — short summary of the post and comments (separately) so you can get the gist quickly.
- 🔎 Search — search articles across supported platforms (with debounce).
- ⚙️ Settings — theme, add/edit/delete/reorder topics.
- 💾 Topics, theme, and session are saved locally on the device.

> The app also works fully with **mock data** without keys (demo mode).

## Architecture

Feature-first + **Riverpod 3**:

```text
lib/
  core/        config, theme, network, utils, models, widgets
  features/
    feed/      data(models, repository, devto_api, hn_api, mock) · application · presentation
    detail/    presentation (post + comments)
    search/    application · presentation
    settings/  data(prefs) · application · presentation
    summary/   data(ai_summary) · application · presentation
    shell/     presentation (bottom nav)
```

Each feature has three layers: **data → application (providers) → presentation**.
If there is no real API, providers automatically select mock implementation.

## Getting Started

```bash
flutter pub get
flutter run
```

- The app connects to public APIs directly, so no `.env` or API keys are required.
- If network APIs fail, the feed can gracefully fall back to **mock** data.

## Test

```bash
flutter analyze
flutter test
```

> Note: The code is written and compilation/testing is clean, but live APIs will be verified after you run the app.
