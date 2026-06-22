# Reddit → O'zbekcha Summary ilovasi — Loyiha brifi (Claude Code uchun)

## Maqsad
Shaxsiy Flutter ilovasi: Reddit'dagi sifatli (inglizcha) postlarni olib, ularni
Gemini orqali **o'zbek tilida qisqacha (summary)** qilib ko'rsatadi. Foydalanuvchi
yoqqan postlarni saqlab qo'yishi mumkin. Ilova **to'liq serversiz** — hamma narsa
ilovaning ichida, backend yo'q.

## Texnologiyalar (stack)
- **Flutter / Dart**
- **dio** — HTTP so'rovlar uchun (`http` EMAS, aynan dio)
- **Gemini API** — summary + o'zbekcha tarjima (`gemini-2.5-flash`)
- **hive_ce + hive_ce_flutter** — lokal saqlash
  (asl `hive` EMAS — u 2+ yildan beri yangilanmagan; CE — uning faol davomi)
- **flutter_secure_storage** — Gemini API kalitini xavfsiz saqlash

## Arxitektura
- Serverless: barcha ish (data olish + LLM + saqlash) ilovada bajariladi, backend yo'q.
- **BYOK** (bring your own key): foydalanuvchi o'z Gemini kalitini Settings'da
  kiritadi → `flutter_secure_storage`'da saqlanadi → kalit kod ichiga yozilmaydi.

---

## 1. Data olish (Reddit parsing)
- Asosiy endpoint: `https://www.reddit.com/r/{subreddit}/top.json?t=week&limit=10`
- **User-Agent SHART** (Reddit umumiy UA'ni rad etadi): mas. `UzSummaryApp/1.0 (shaxsiy)`
- **Zaxira (fallback)**: Reddit 403 qaytarsa, public Redlib mirror'ga o't —
  `https://redlib.catsarch.com/r/{subreddit}/top.json?t=week&limit=10`
  (bir nechta mirror ro'yxatini ketma-ket sina, biri ishlamasa keyingisiga o't).
- dio JSON'ni avtomatik parse qiladi → `resp.data` Map bo'ladi (jsonDecode kerak emas).
- Postlar: `resp.data['data']['children']` → har biri `['data']`.
  Kerakli maydonlar: `id`, `title`, `selftext`, `url`, `permalink`, `author`,
  `subreddit`, `score`.
- **Eslatma**: *text-post* kontenti `selftext`'da bo'ladi; *link-post* kontenti
  tashqi `url`'da (kerak bo'lsa uni alohida fetch qilish lozim).

## 2. Summary + o'zbekcha tarjima (Gemini)
- `POST https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent`
- Header: `x-goog-api-key: <foydalanuvchi kaliti>`, `Content-Type: application/json`
- Body: `{ "contents": [ { "parts": [ { "text": <prompt> } ] } ] }`
- Prompt namunasi:
  `"Quyidagi inglizcha Reddit postini o'zbek tilida 3-4 jumlada qisqacha yoz.`
  `Faqat o'zbekcha summary qaytar. Sarlavha: {title}. Matn: {selftext}"`
- Javob: `resp.data['candidates'][0]['content']['parts'][0]['text']`
- **Bepul tier ~250 so'rov/kun (Flash)** → kvotani tejash uchun dedup qil (3-bo'lim).
  Ko'proq kerak bo'lsa `gemini-2.5-flash-lite` (~1000/kun).

## 3. Saqlash (Hive CE)
- **Ikkita ALOHIDA box**:
  - `summaries` — feed cache (vaqtinchalik).
  - `favorites` — yoqqan postlar (doimiy). Alohida bo'lishi SHART — aks holda
    cache tozalanganda saqlangan postlar ham o'chib ketadi.
- **Dedup** (Gemini kvotasini tejaydi): yangi postni summary qilishdan oldin
  `if (box.containsKey(id)) continue;` — eski postni qayta yubormaydi.
- **Tuzoq (gotcha)**: Hive'dan Map o'qiganda u `Map<dynamic, dynamic>` bo'lib
  qaytadi. To'g'ridan-to'g'ri `as Map<String, dynamic>` cast XATO beradi →
  har doim `Map<String, dynamic>.from(...)` ishlat.

---

## Ekranlar
1. **Feed** — top postlar ro'yxati, har birida o'zbekcha summary + ❤️ (saqlash) tugmasi.
2. **Favorites** — saqlangan postlar ro'yxati, har birida "o'chirish" tugmasi.
3. **Settings** — Gemini API kalitini kiritish (flutter_secure_storage'ga saqlanadi).

## Muhim eslatmalar (xulosa)
- Reddit uchun tavsiflovchi User-Agent shart; bloklansa Redlib mirror'ga o't.
- dio: `resp.data` allaqachon parse qilingan (Map/List).
- Hive map cast: doim `Map<String, dynamic>.from(...)`.
- cache va favorites — alohida box.
- Gemini bepul kvota cheklangan → albatta dedup qil.
- Maxfiylik: Gemini bepul tier ma'lumotni o'qitishga ishlatishi mumkin
  (Reddit postlari baribir ochiq, shuning uchun muammo emas).

## Birinchi qadam (Claude Code uchun)
1. Flutter loyihasini sozla, paketlarni qo'sh: `dio`, `gemini` o'rniga raw dio,
   `hive_ce`, `hive_ce_flutter`, `flutter_secure_storage`.
2. Reddit fetch + Redlib fallback funksiyasini yoz.
3. Gemini summary funksiyasini yoz (BYOK).
4. Hive CE'ni sozla (2 ta box) + dedup.
5. 3 ta ekranni qur (Feed, Favorites, Settings).