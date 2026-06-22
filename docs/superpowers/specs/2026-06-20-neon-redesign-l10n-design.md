# FeedDigest — Neon Redesign + Trilingual l10n + AI Summary Language

**Date:** 2026-06-20
**Branch:** `rebuild/mvvm-scraping`
**Source of truth:** `stitch_feeddigest_ai_reader/` (Stitch exports: `screen.png` + `code.html` per screen, plus two `DESIGN.md` token sets).

## Goal

Redesign the existing FeedDigest Flutter app 1:1 with the Stitch "Neon Professional"
mockups, add UZ/RU/EN localization (l10n), and add a Settings UI to pick the app
language **and** the AI-summary language. Keep all existing functionality (sources,
feed aggregation, favorites, topics, search, Gemini summaries).

## Design system

Two themes built straight from the Stitch tokens:

- **Neon Dark (default).** bg/surface `#111319`, input bg `#0F1117`, cards
  `#191b22` + 1px `#2D313D` border, icon circles `#33343b`, accent **Electric Cyan
  `#00F0FF`**, hover cyan `#7df4ff`, text `#e2e2eb`, dim text `#A0A7B5`,
  on-surface-variant `#b9cacb`. Inter font. Cards radius 20px; chips/buttons pill or
  12px. Active states = cyan border / cyan fill, no heavy shadows.
- **Lumina Light.** bg `#f8f9ff`, white cards w/ soft shadow, accent `#00BDCC`
  (AA-tuned), navy text `#0b1c30`, dim `#3c494b`, border `#bbc9cb`.

Exposed to widgets via an `AppPalette` `ThemeExtension` (accent, accentSoft,
mutedBorder, textDim, cardColor, inputFill, iconCircle, chipSelectedBorder…) so both
themes render exactly. Component themes set on `ThemeData`: card, chip,
navigationBar, inputDecoration, filledButton, outlinedButton, appBar, text (Inter).

## Localization

- `flutter_localizations` + `intl`, `generate: true`, `l10n.yaml`,
  `lib/l10n/app_{en,uz,ru}.arb` (en = template) holding every UI string.
- `AppLocalizations` replaces all hardcoded Uzbek literals across every screen/widget.
- UI labels stay natural per language; the three native names are
  `O'zbekcha / Русский / English`.

## State / persistence (Hive `meta` box)

New providers in `lib/core/prefs/preferences.dart`:

| Provider | Key | Default | Drives |
|---|---|---|---|
| `localeProvider` (`AppLanguage`) | `app_locale` | `uz` | `MaterialApp.locale` |
| `themeModeProvider` (`ThemeMode`) | `theme_mode` | `dark` | `MaterialApp.themeMode` |
| `aiSummaryLangProvider` (`AppLanguage?`, null = follow app) | `ai_summary_lang` | null | Gemini prompt + cache key |

`AppLanguage { uz, ru, en }` → `code` + `nativeLabel`. Effective AI language =
`aiSummaryLang ?? appLanguage`.

`app.dart` becomes a `ConsumerWidget`; `MaterialApp` gets `localizationsDelegates`,
`supportedLocales`, `locale`, `theme`, `darkTheme`, `themeMode`.

## AI summary language

- `GeminiRepository.summarize(article, langCode)` builds a per-language prompt
  ("summarize in <lang>, respond only in <lang>"). Replaces the hardcoded UZ prompt.
- `summary_viewmodel` resolves effective lang and passes it; **cache key becomes
  `${article.id}-$langCode`** so switching language never returns a stale
  wrong-language summary. `SummaryCacheRepository.get/put` already key on a string id.

## Screen-by-screen (1:1 with PNG/HTML)

| Screen | File | Mockup |
|---|---|---|
| Bottom nav | `home_shell.dart` | Frosted bar, 1px top border, cyan **filled** active icon (drop-shadow glow) + cyan label; home/search/bookmark/settings. |
| Feed | `feed_screen.dart` | Brand app bar: `hub` cyan icon · **FeedDigest** bold · `keyboard_arrow_down`. Sticky header: source row + chips. |
| Source row + sheet | `source_switcher.dart` | Row: filled `local_fire_department` cyan + label + caret → opens **Manbalar** sheet (title + ✕; selected = cyan border + `check_circle`). |
| Chips | `subscription_bar.dart` | Pills: active = cyan border + cyan/10 bg + glow; idle = surface + muted border. "Hammasi" + topics + trailing `+` (opens topic editor). |
| Card | `post_card.dart` | 20px radius, 1px border, hover→cyan. Meta row `source • #topic(cyan/70) • time` with dot separators; bold `headline-md` title; optional 60–80px thumbnail (cover image or favicon box); action row ▲score / 💬comments / bookmark+favorite+share. Tap → detail. |
| Detail | `article_detail_screen.dart` | Back · source · favorite. Hero image, topic chip line, big title, author avatar+meta + counts, body; buttons **ASL MAQOLANI OCHISH** (cyan filled) + **AI XULOSA** (cyan ghost, `auto_awesome`). |
| Summary sheet | `summary_sheet.dart` | `auto_awesome` + "AI XULOSA" label, title, summary in bordered box, **Yopish** filled button. |
| Search | `search_screen.dart` | Neon search field + filter; results header; rich cards (thumb, topic chip, time, title, snippet, reading-time + bookmark). |
| Saved | `favorites_screen.dart` | "Saqlanganlar" header; filter tabs (Barchasi + topics); feature cards (big image, chip, time, title, snippet). |
| Settings | `settings_screen.dart` | "Sozlamalar" + subtitle. Gemini card: title + "Kalit o'rnatilgan" pulse badge + subtitle + password field w/ eye + **Saqlash**. Rows: **Ilova tili**, **AI xulosalari tili**, **Mavzu (theme)** — each icon-circle + title + value + chevron → option sheet. **No** Obunalar / Bildirishnomalar (Stitch filler, per user). |

Shared widgets: `AppPalette` (theme ext), `CategoryChip`, `SettingsTile`,
`OptionPickerSheet` (generic single-select bottom sheet), brand header pieces.

## Decisions

1. **Topic management** keeps its home via a trailing `+` chip in the feed chip row
   (opens existing `SubscriptionEditorSheet`); the settings "Obunalar" row is dropped.
2. **Summary cache** keyed by language (above).
3. **Search/Saved** match the mockup *layout*; colors follow the active theme (neon in
   dark, Lumina in light) rather than being hard light-mode.
4. Material Symbols in the mockups map to the closest Flutter `Icons`.

## Out of scope

No Reddit (blocked by design), no payments/premium, no push notifications, no new
data sources. Data-layer changes limited to the Gemini prompt, summary cache key, and
three persisted prefs.

## Verification

`flutter pub get` → `flutter gen-l10n` → `flutter analyze` (clean) →
`flutter test` (update tests that assert changed strings) green. Manual: switch
theme, switch all three app languages, switch AI-summary language and confirm Gemini
responds in it; walk every screen against its PNG.
