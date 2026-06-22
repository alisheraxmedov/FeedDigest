# FeedDigest — Ma'lumot manbasi muammosi va yechimlar rejasi

> Holat: 2026-06-20 da yozildi. Reddit `.json` scraping ishlamayapti (403 Blocked).

---

## 1. Muammo (Root Cause)

App hozir Reddit'ning **autentifikatsiyasiz** `.json` endpointini ishlatadi:

- `lib/core/network/reddit_client.dart` → `Uri.https(host, '/r/$sub/top.json', ...)`
- `lib/core/config/app_config.dart` → `userAgent = 'UzSummaryApp/1.0 (shaxsiy)'`

**Test natijasi (2026-06-20):**

| So'rov | Natija |
|---|---|
| `www.reddit.com/r/FlutterDev/top.json` (har qanday User-Agent bilan) | **403 — `<title>Blocked</title>`** |
| `old.reddit.com/.../top.json` | 403 |
| `.rss` feed | 403 |
| `www.reddit.com/api/v1/access_token` (OAuth) | 401 (tirik, token kutyapti) |

**Xulosa:** Bu User-Agent muammosi emas. Reddit autentifikatsiyasiz kirishni butunlay yopgan.
Datacenter IP'lar qattiq bloklangan; mobil/residential IP'da ham 403 (foydalanuvchi tasdiqladi).

### Reddit siyosati (2025–2026)
- **2023:** bepul cheksiz API yopildi, tijoriy foydalanish pulli bo'ldi (Apollo va boshqalar yopildi).
- **2025-11-11 — "Responsible Builder Policy":** endi **HAR QANDAY** API kirish (shaxsiy/hobby loyihalar ham) Reddit'dan **oldindan ruxsat (pre-approval)** talab qiladi.
- Bepul tier hali bor: OAuth client uchun **daqiqasiga ~100 so'rov**, lekin faqat ruxsat olgandan keyin.
- Autentifikatsiyasiz / OAuth'siz trafik **bloklanadi**.

---

## 2. Reddit'ni ishlatish yo'llari (research natijasi)

### Variant R1 — Rasmiy OAuth API (to'g'ri yo'l) ⭐ tavsiya, agar Reddit shart bo'lsa
1. https://www.reddit.com/prefs/apps → **"create app"** formasini to'liq to'ldirish
   (siyosat havolasi shunchaki ogohlantirish; formani to'ldirib pastdagi tugmani bossangiz
   `client_id` **darhol beriladi** — manbalarga ko'ra hali ishlaydi).
   - Tur: **installed app** (mobil client, secret kerak emas).
   - redirect uri: `http://localhost:8080`
2. App-only (anonim) token olish:
   `POST https://www.reddit.com/api/v1/access_token`
   - Basic auth: `base64(client_id + ":")`
   - body: `grant_type=https://oauth.reddit.com/grants/installed_client&device_id=<random-uuid>`
3. Maqolalarni token bilan olish:
   `GET https://oauth.reddit.com/r/<sub>/top?t=week&limit=10`
   - headers: `Authorization: Bearer <token>`, `User-Agent: android:com.feeddigest:1.0 (by /u/<user>)`

**Artilari:** rasmiy, barqaror, har joyda ishlaydi (datacenter IP ham).
**Kamchiligi:** Reddit akkaunt + (ehtimol) "Responsible Builder" ruxsat formasi kerak;
ruxsat bir necha kun (ba'zan 2–4 hafta) ketishi mumkin. Token har ~1 soatda yangilanadi.

### Variant R2 — Redlib-uslubi "OAuth token spoofing" (gray area, tavsiya etilmaydi)
Redlib (ochiq manbali Reddit frontend) Reddit'ning rasmiy **Android ilovasini taqlid qiladi**:
Android client'ning ommaviy token oqimidan foydalanib anonim token oladi, rasmiy app
headerlarini yuboradi, tokenni 24 soatda yangilaydi. Shu tariqa ruxsatsiz ham ishlaydi.

**MUHIM:** bu Reddit ToS'iga zid (access control'ni aylanib o'tish), mo'rt (Reddit istalgan
vaqt to'sib qo'yishi mumkin) va portfolio ilovada ish beruvchiga ko'rsatish uchun yaxshi emas.
Faqat tadqiqot uchun qayd etildi — production'da ishlatmaymiz.

### Variant R3 — Public Redlib instance orqali o'qish
Tayyor public Redlib instance'iga so'rov yuborish (instance ro'yxati: `redlib-instances` repo).
Lekin: instancelar mo'rt/o'zgaruvchan, rate-limit bor, JSON formati Reddit'nikidan farq qiladi,
ko'pi ishonchsiz. Production uchun tavsiya etilmaydi.

---

## 3. Reddit'siz bepul manbalar (tasdiqlangan ✅ — hozir ishlaydi)

Bularning hech biri kalit/login/ruxsat talab qilmaydi va hech qachon bloklanmaydi.
2026-06-20 da real test qilindi — HTTP 200, haqiqiy maqolalar qaytdi.

### A — Hacker News (Algolia Search API) ⭐
- `GET https://hn.algolia.com/api/v1/search?query=<topic>&tags=story&hitsPerPage=10`
- Topic = istalgan qidiruv so'zi (Reddit'dagidek erkin).
- Qaytaradi: `title`, `url`, `points`, `num_comments`, `author`, `created_at`, `objectID`.
- Mavjud `RedditPost` modeliga deyarli 1:1 mos (score = points).

### B — dev.to (Forem API)
- `GET https://dev.to/api/articles?tag=<tag>&per_page=10`
- Topic = oldindan belgilangan teg (flutter, programming, technology...).
- Qaytaradi: `title`, `url`, `positive_reactions_count`, `description`, `cover_image`, `tags`.

> AI summary (Gemini) funksiyasi har ikki holatda ham o'zgarishsiz qoladi —
> faqat ma'lumot manbasi (data source) almashadi.

---

## 4. Tavsiya / Reja

1. **Asosiy manba:** Hacker News (Variant A) — portfolio uchun "doim ishlaydi", professional ko'rinadi.
   `RedditClient` o'rniga `ArticleSource` abstraksiyasi qilib, HN implementatsiyasini ulash.
2. **Reddit'ni ixtiyoriy qilib qoldirish:** agar foydalanuvchi xohlasa va `client_id` kiritsa,
   Variant R1 (rasmiy OAuth) orqali Reddit'ni qo'shimcha manba sifatida yoqish mumkin.
3. `feed_viewmodel.dart:42` dagi jim `catchError((_) => [])` ni log/xato ko'rsatishga almashtirish —
   kelajakda muammolar yashirin qolmasligi uchun.

---

## 5. Manbalar (research)
- Reddit Responsible Builder Policy (2025-11-11) — replydaddy.com, wappkit.com
- Reddit Data API Wiki — support.reddithelp.com
- Rate limits (100 QPM free tier) — apidog.com, painonsocial.com
- Redlib OAuth token spoofing — github.com/redlib-org/redlib
- Test natijalari — bevosita `curl` (2026-06-20)
