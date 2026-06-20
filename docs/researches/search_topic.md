Tushundim — endi top postlar emas, balki **qidiruv (search)** qismi. Reddit'da qidiruvning ham `.json` varianti bor. Redlib fallback'ingiz ham qidiruvni qo'llab-quvvatlashini tekshirib, aniq formatni berib qo'ya qolay.Ha, qidiruvning ham `.json` varianti bor — xuddi top postlardagidek. Mana mexanizmi.

## `.json` triginig mohiyati

Reddit'da **har qanday** sahifaning JSON varianti bor: manzilga `.json` qo'shsang (yoki `/search/` ni `/search.json` qilsang), o'sha sahifa ma'lumotini HTML emas, JSON qaytaradi. Qidiruv uchun:

- Oddiy sahifa: `https://www.reddit.com/search/?q=flutter`
- JSON varianti: `https://www.reddit.com/search.json?q=flutter`

## Qidiruv endpoint va parametrlari

Ikki xil:
- **Butun Reddit bo'ylab**: `https://www.reddit.com/search.json?q=...`
- **Faqat bitta subreddit ichida**: `https://www.reddit.com/r/{subreddit}/search.json?q=...&restrict_sr=true`

Asosiy parametrlar (`q` (so'rov), `sort`, `t` (vaqt), `limit`, `type`, va subreddit ichida qidirsa `restrict_sr=true`):

| Parametr | Qiymatlar | Vazifasi |
|---|---|---|
| `q` | matn | qidiruv so'zlari |
| `sort` | `relevance` `hot` `top` `new` `comments` | tartiblash |
| `t` | `hour` `day` `week` `month` `year` `all` | vaqt oralig'i |
| `limit` | 1–100 | nechta natija |
| `type` | `link` `sr` `user` | post / subreddit / foydalanuvchi |
| `restrict_sr` | `true` | faqat shu subreddit ichida |

## ⚠️ Eng muhim nuqta: query'ni qo'lda yopishtirmang

Agar `search.json?q=$query` deb string'ni qo'lda ulasangiz, **bo'sh joy yoki maxsus belgili** so'rov ("flutter state management") buziladi. Dart'da buni `Uri` hal qiladi — u parametrlarni **avtomatik encode** qiladi:

```dart
import 'package:dio/dio.dart';

/// Reddit'da post qidirish (.json orqali)
Future<List<Map<String, dynamic>>> searchPosts(
  Dio dio,
  String query, {
  String? subreddit,      // null = butun Reddit; aks holda faqat shu subreddit ichida
  String sort = 'top',    // sifatli postlar uchun: top
  String time = 'month',  // hour | day | week | month | year | all
  int limit = 25,
}) async {
  final path = subreddit == null ? '/search.json' : '/r/$subreddit/search.json';

  // Uri queryParameters'ni AVTOMATIK encode qiladi — bo'sh joy/belgi muammosi yo'q
  final uri = Uri.https('www.reddit.com', path, {
    'q': query,
    'sort': sort,
    't': time,
    'limit': '$limit',
    'type': 'link',                                  // faqat postlar
    if (subreddit != null) 'restrict_sr': 'true',    // faqat shu subreddit ichida
  });

  final resp = await dio.getUri(
    uri,
    options: Options(headers: {'User-Agent': 'UzSummaryApp/1.0 (shaxsiy)'}),
  );

  final children = resp.data['data']['children'] as List;
  return children.map((c) => c['data'] as Map<String, dynamic>).toList();
}
```

Ishlatish:

```dart
// Butun Reddit bo'ylab, oxirgi oydagi eng yaxshi natijalar:
final r1 = await searchPosts(dio, 'artificial intelligence ethics');

// Faqat r/programming ichida, oxirgi hafta:
final r2 = await searchPosts(dio, 'flutter state management',
    subreddit: 'programming', time: 'week');
```

## Ikki foydali maslahat

**Sifatli postlar uchun** `sort: 'top'` + `time: 'week'` yoki `'month'` ishlating — eng ko'p ovoz olgan, ya'ni sifatli postlar chiqadi.

**Ishonchlilik uchun** `www.reddit.com` bloklansa, host'ni `old.reddit.com` ga almashtiring — `.json` qo'shimchasini old.reddit.com manzillarida ishlatish HTML'ni to'g'ridan-to'g'ri scrape qilishdan ko'ra ishonchliroq. (Redlib fallback'da qidiruv har instance'da har xil bo'lishi mumkin — test qilib ko'ring.)

Eng muhimi: bu funksiya qaytaradigan struktura top postlardagi bilan **bir xil** (`Map<String, dynamic>` — `id`, `title`, `selftext`...). Demak natijani to'g'ridan-to'g'ri mavjud Gemini summary + Hive pipeline'ingizga uzatasiz, hech narsa o'zgartirmasdan.

Xohlasangiz, shu `searchPosts` funksiyasini CLAUDE.md brifiga ham qo'shib qo'yaman — qidiruv ekraningiz bo'lsa, Claude Code uni ham hisobga oladi.


UMUMIY:
Mana hammasi bir joyda, misollar bilan 👇

## 1. Umumiy qoida: istalgan manzilni JSON ga o'tkazish

Qoida bitta: **manzildagi yo'l (path) oxiriga `.json` qo'shasiz — `?` belgisidan oldin.** Va `cId`, `iId` kabi keraksiz tracking parametrlarni tashlaysiz.

```
Oddiy:   https://www.reddit.com/r/FlutterDev/
JSON:    https://www.reddit.com/r/FlutterDev.json

Oddiy:   https://www.reddit.com/search/?q=flutter
JSON:    https://www.reddit.com/search.json?q=flutter
```

Bu qoida hamma joyga ishlaydi — subreddit, qidiruv, hatto bitta postning kommentlari (`/comments/ID/.json`).

## 2. TOPIC qidirish (search.json)

Ikki xil:

**Butun Reddit bo'ylab** (har qanday subreddit'dan):
```
https://www.reddit.com/search.json?q=SO'ZINGIZ
```

**Faqat bitta subreddit ichida** (`restrict_sr=true` qo'shiladi):
```
https://www.reddit.com/r/SUBREDDIT/search.json?q=SO'ZINGIZ&restrict_sr=true
```

> Eslatma: bo'sh joy `+` bilan yoziladi → `machine+learning`. (Kodda `Uri` buni avtomatik qiladi.)

## 3. Filtr: `sort` (tartib) va `t` (vaqt)

Ikkita parametr qo'shasiz:

| Parametr | Qiymatlar | Vazifasi |
|---|---|---|
| `sort` | `relevance` · `hot` · `top` · `new` · `comments` | natijalar tartibi |
| `t` | `hour` · `day` · `week` · `month` · `year` · `all` | qaysi davr ichidan |
| `limit` | `1`–`100` | nechta natija |
| `type` | `link` · `sr` · `user` | post / subreddit / foydalanuvchi |

> ⚠️ **Muhim nozik joy:** `t` (vaqt) faqat `sort=top` bilan ishlaydi. Agar `sort=new` yoki `sort=hot` qo'ysangiz, `t` e'tiborga olinmaydi (yangi/hot baribir vaqtga bog'liq emas).

**Sifatli natija formulasi:** `sort=top` + `t=week` yoki `t=month`.

## 4. To'liq, tayyor misollar (copy-paste)

**a) Butun Reddit, "flutter", oxirgi oy, eng top 10:**
```
https://www.reddit.com/search.json?q=flutter&sort=top&t=month&limit=10&type=link
```

**b) Faqat r/FlutterDev ichida, "state management", oxirgi yil:**
```
https://www.reddit.com/r/FlutterDev/search.json?q=state+management&restrict_sr=true&sort=top&t=year&limit=10&type=link
```

**c) Eng yangi postlar (vaqt filtrisiz), "rust":**
```
https://www.reddit.com/r/programming/search.json?q=rust&sort=new&limit=10&type=link
```

**d) Qidiruvsiz — shunchaki r/MachineLearning ning top postlari, oxirgi hafta:**
```
https://www.reddit.com/r/MachineLearning/top.json?t=week&limit=10
```

## Tezkor xulosa

1. `/search/` → `/search.json`, keraksiz IDlarni tashla.
2. `q=` — qidiruv so'zi · `restrict_sr=true` — bitta subreddit ichida.
3. `sort=top` + `t=month` — sifatli postlar uchun.
4. Bloklansa → `www.reddit.com` o'rniga `old.reddit.com`.

Xohlasangiz, shu cheatsheet'ni alohida `reddit-json.md` fayl qilib (yoki CLAUDE.md ga qo'shib) beraman — loyihangizda qo'lda turadi.