# FeedDigest

Reddit o'qish ilovasi — mavzular bo'yicha postlar, qidiruv va **Gemini AI** yordamida
o'zbek tilidagi qisqa xulosalar (post + izohlar alohida).

## Imkoniyatlar

- 🔐 **Reddit bilan login** (OAuth) — shaxsiy hisobingiz.
- 🏠 **Bosh sahifa** — obunalaringiz birlashgan feed; tablar = real obunalaringiz.
- ➕ **Obuna / bekor qilish** — har subreddit feedi va post detailida.
- ⬆️⬇️ **Ovoz berish** (upvote / downvote) — kartada va detailda, optimistik.
- 📰 Login qilmaganda — qo'lda qo'shilgan mavzular (IT, Flutter, AI, Android, iOS…).
- 🔀 Saralash: hot / new / top / rising, cheksiz scroll, pull-to-refresh.
- 🖼️ Reddit uslubidagi kartalar — rasm, ovoz, izohlar soni.
- 📄 Post detail ekrani — to'liq matn + eng yaxshi izohlar.
- ✨ **AI Xulosa** — postning va izohlarning o'zbekcha qisqa xulosasi (alohida-alohida).
- 🔎 Qidiruv — Reddit bo'ylab maqola qidirish (debounce bilan).
- ⚙️ Sozlamalar — hisob, theme, mavzularni qo'shish/tahrir/o'chir/tartiblash.
- 💾 Mavzular, theme va sessiya qurilmada saqlanadi.

> Kalitlarsiz/loginsiz ham ilova **mock ma'lumot** bilan to'liq ishlaydi (demo rejim).

## Arxitektura

Feature-first + **Riverpod 3**:

```
lib/
  core/        config, theme, network, utils, models, widgets
  features/
    feed/      data(models, repository, mock, auth) · application · presentation
    detail/    presentation (post + izohlar)
    search/    application · presentation
    settings/  data(prefs) · application · presentation
    summary/   data(gemini, ai_summary) · application · presentation
    shell/     presentation (bottom nav)
```

Har bir feature uch qatlam: **data → application (providerlar) → presentation**.
Real API bo'lmasa, providerlar avtomatik mock implementatsiyani tanlaydi.

To'liq dizayn: [`docs/superpowers/specs/2026-06-08-reddit-ai-reader-design.md`](docs/superpowers/specs/2026-06-08-reddit-ai-reader-design.md)

## Ishga tushirish

```bash
flutter pub get
cp .env.example .env     # keyin kalitlarni to'ldiring
flutter run
```

### API kalitlari (`.env`)

| Kalit | Tavsif |
|-------|--------|
| `GEMINI_API_KEY` | Gemini kaliti — https://aistudio.google.com/apikey |
| `GEMINI_MODEL` | Model (default `gemini-2.5-flash`) |
| `REDDIT_CLIENT_ID` | Reddit "installed app" client id — https://www.reddit.com/prefs/apps |
| `REDDIT_USER_AGENT` | `platform:appid:version (by /u/siz)` ko'rinishida |
| `REDDIT_USE_PUBLIC` | `true` — client id'siz public `.json` endpointlardan foydalanish |

- `GEMINI_API_KEY` bo'sh bo'lsa — AI xulosa **demo** matn qaytaradi.
- `REDDIT_CLIENT_ID` bo'sh va `REDDIT_USE_PUBLIC=false` bo'lsa — feed **mock** ma'lumot ko'rsatadi.

### Reddit hisobiga login (obuna + ovoz berish)

Login OAuth talab qiladi. Reddit app'ingizni shu tarzda sozlang:

1. https://www.reddit.com/prefs/apps → **"create app"** → turi: **installed app** (secret yo'q).
2. **redirect uri** (aynan shunday):
   ```
   feeddigest://oauth2redirect
   ```
3. `client_id` (app nomi ostidagi qator) ni `.env` dagi `REDDIT_CLIENT_ID` ga qo'ying.
4. Ilovada: **Sozlamalar → Reddit bilan kirish**.

Scope'lar: `identity mysubreddits read vote subscribe` (izoh yozish yo'q).
Platforma sxemasi (`feeddigest`) `AndroidManifest.xml` va iOS `Info.plist` da
allaqachon ro'yxatdan o'tkazilgan.

#### Qurilmada ishlamasa — tekshiring
- **Redirect mos kelmadi** → Reddit'dagi redirect uri `feeddigest://oauth2redirect` bilan aynan bir xilmi?
- **1 soatdan keyin chiqib ketadi** → auth URL'da `duration=permanent` borligini tekshiring (kodda bor).
- **429 / bloklash** → `REDDIT_USER_AGENT` to'ldirilganmi (`platform:appid:version (by /u/siz)`).
- **Callback qaytmaydi (Android)** → manifestdagi `android:scheme` = `feeddigest` ekanini tekshiring.

## Test

```bash
flutter analyze
flutter test
```

> Eslatma: Reddit va Gemini real chaqiruvlarini bu muhitda sinab bo'lmaydi (kalit yo'q +
> Reddit ba'zi serverlarni bloklaydi). Kod yozilgan va kompilyatsiya/test toza, lekin
> jonli API'lar siz kalit qo'shganingizdan keyin tekshiriladi.
