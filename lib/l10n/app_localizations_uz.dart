// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Uzbek (`uz`).
class AppLocalizationsUz extends AppLocalizations {
  AppLocalizationsUz([String locale = 'uz']) : super(locale);

  @override
  String get appTitle => 'FeedDigest';

  @override
  String get navFeed => 'Feed';

  @override
  String get navSearch => 'Qidiruv';

  @override
  String get navSaved => 'Saqlangan';

  @override
  String get navSettings => 'Sozlama';

  @override
  String get chipAll => 'Hammasi';

  @override
  String get feedNoSubscriptions =>
      'Obuna yo\'q. + tugmasi yoki Qidiruv orqali mavzu qo\'shing.';

  @override
  String get feedEmpty => 'Hech narsa topilmadi';

  @override
  String get retry => 'Qayta urinish';

  @override
  String get sourcesTitle => 'Manbalar';

  @override
  String get openOriginal => 'Asl maqolani ochish';

  @override
  String get aiSummary => 'AI xulosa';

  @override
  String get articleShort => 'Maqola';

  @override
  String get aiShort => 'AI';

  @override
  String get close => 'Yopish';

  @override
  String get settingsTitle => 'Sozlamalar';

  @override
  String get settingsSubtitle => 'Dastur va xizmat parametrlarini boshqarish';

  @override
  String get aiProviderTitle => 'AI provayder';

  @override
  String get aiKeySet => 'Kalit saqlangan';

  @override
  String get aiKeyNotSet => 'Kalit kiritilmagan';

  @override
  String get aiModelLabel => 'Model';

  @override
  String get aiKeyInvalid => 'API kalit noto\'g\'ri';

  @override
  String get aiRateLimited => 'Limit tugadi — keyinroq urinib ko\'ring';

  @override
  String get voiceInfoTitle => 'AI ovozli qidiruv';

  @override
  String get voiceInfoSubtitle => 'Gemini bilan ishlaydi';

  @override
  String get voiceInfoBody =>
      'Bosh sahifadagi mikrofon tugmasini bosib turib nimani o\'qimoqchi ekaningizni ayting — AI nutqingizni qidiruvga aylantiradi.\n\nBu funksiya audioni faqat Google Gemini orqali tushunadi, shuning uchun u Gemini AI provayder sifatida tanlangan va kaliti kiritilgan bo\'lsa ko\'rinadi.';

  @override
  String get switchToGemini => 'Gemini\'ga o\'tish';

  @override
  String get save => 'Saqlash';

  @override
  String get keySaved => 'Kalit saqlandi';

  @override
  String get keySaveFailed => 'Kalitni saqlab bo\'lmadi';

  @override
  String get notifScheduleFailed => 'Eslatmani o\'rnatib bo\'lmadi';

  @override
  String get appLanguage => 'Ilova tili';

  @override
  String get aiSummaryLanguage => 'AI xulosalari tili';

  @override
  String get theme => 'Mavzu';

  @override
  String get themeSystem => 'Tizim';

  @override
  String get themeLight => 'Yorug\'';

  @override
  String get themeDark => 'Qorong\'u';

  @override
  String get langUzbek => 'O\'zbekcha';

  @override
  String get langRussian => 'Русский';

  @override
  String get langEnglish => 'English';

  @override
  String get searchHint => 'Maqola qidirish...';

  @override
  String get searchEmpty => 'Qidiruv natijasi yo\'q';

  @override
  String get searchPrompt => 'Mavzu yoki kalit so\'z bo\'yicha qidiring';

  @override
  String searchResultsFor(String query) {
    return '\'$query\' natijalari';
  }

  @override
  String get filter => 'Filtr';

  @override
  String readingTime(int minutes) {
    return '$minutes daqiqa o\'qish';
  }

  @override
  String get savedTitle => 'Saqlanganlar';

  @override
  String get savedEmpty => 'Hali saqlangan post yo\'q';

  @override
  String get topicsTitle => 'Mavzular';

  @override
  String get topicLabel => 'Mavzu';

  @override
  String get add => 'Qo\'shish';

  @override
  String get timeNow => 'hozir';

  @override
  String get tooltipSubscribe => 'Mavzuga obuna';

  @override
  String get tooltipUnsubscribe => 'Mavzudan chiqish';

  @override
  String get summaryNoKey => 'AI API kaliti kiritilmagan';

  @override
  String get summaryFailed => 'Xulosani olishda xatolik';

  @override
  String get sourceLabel => 'Manba';

  @override
  String get sortNewest => 'Eng yangi';

  @override
  String get sortPopular => 'Mashhur';

  @override
  String get feedLoadError =>
      'Maqolalarni yuklab bo\'lmadi. Ulanishni tekshirib qayta urining.';

  @override
  String get summaryBlocked => 'AI xavfsizlik filtri tomonidan bloklandi';

  @override
  String get summaryDepthBrief => 'Qisqa';

  @override
  String get summaryDepthDetailed => 'Batafsil';

  @override
  String get summaryAddKey => 'Kalit qo\'shish';

  @override
  String get digestTitle => 'Bugungi digest';

  @override
  String get digestTooltip => 'AI kunlik digest';

  @override
  String get notifDigestLabel => 'Kunlik digest';

  @override
  String get notifDigestDesc => 'Har kuni belgilangan vaqtda o\'qish eslatmasi';

  @override
  String get notifTimeLabel => 'Vaqt';

  @override
  String get notifBody => 'Bugungi digest tayyor — o\'qishga vaqt!';

  @override
  String get notifDenied => 'Bildirishnomaga ruxsat berilmadi';

  @override
  String get notifOff => 'O\'chirilgan';

  @override
  String get translateTooltip => 'Tarjima qilish';

  @override
  String get chatTooltip => 'Maqola bilan suhbat';

  @override
  String get chatTitle => 'Maqola bilan suhbat';

  @override
  String get chatHint => 'Savol bering...';

  @override
  String get chatEmpty => 'Maqola haqida istalgan savolni bering';

  @override
  String get exportData => 'Ma\'lumotlarni eksport qilish';

  @override
  String get exportDataDesc => 'Obunalar va saqlanganlar (JSON + OPML)';

  @override
  String get exportFailed => 'Eksport qilishda xatolik';

  @override
  String get readerText => 'Matn o\'lchami';

  @override
  String get readerTextSample =>
      'Namuna matn — o\'qish qulayligi uchun o\'lchamni tanlang.';

  @override
  String streakDays(int count) {
    return '$count kun ketma-ket o\'qildi';
  }

  @override
  String get menu => 'Menyu';

  @override
  String get sortLabel => 'Saralash';

  @override
  String get streakTitle => 'O\'qish seriyasi';

  @override
  String get streakNone => 'Hali seriya yo\'q';

  @override
  String get sectionMore => 'Boshqa';

  @override
  String get about => 'Ilova haqida';

  @override
  String get aboutDescription =>
      'Hacker News + dev.to o\'qish ilovasi, Gemini AI xulosalari bilan.';

  @override
  String version(String version) {
    return 'Versiya $version';
  }

  @override
  String get shareApp => 'Ilovani ulashish';

  @override
  String get shareAppText =>
      'FeedDigest\'ni sinab ko\'ring — Hacker News + dev.to o\'qish ilovasi, AI xulosalari bilan.';

  @override
  String get rateApp => 'Ilovani baholash';

  @override
  String get privacyPolicy => 'Maxfiylik siyosati';

  @override
  String get termsOfService => 'Foydalanish shartlari';

  @override
  String get support => 'Yordam';

  @override
  String get comingSoon => 'Tez orada';

  @override
  String get sectionComingSoon => 'Bu bo\'lim tez orada mavjud bo\'ladi.';

  @override
  String get onboardingTagline =>
      'Hacker News va dev.to maqolalari — soniyalarda AI qisqartirib beradi.';

  @override
  String get onboardingFeatureAiTitle => 'AI qisqacha, o\'z tilingizda';

  @override
  String get onboardingFeatureAiSub => 'O\'zbekcha · Ruscha · Inglizcha';

  @override
  String get onboardingFeatureSourcesTitle => 'Ikki manba, bitta lenta';

  @override
  String get onboardingFeatureSourcesSub => 'Birlashtirilgan va takrorsiz';

  @override
  String get onboardingFeatureSaveTitle => 'Saqlab, keyin o\'qing';

  @override
  String get onboardingFeatureSaveSub => 'Xatcho\'plar, mavzu bo\'yicha filtr';

  @override
  String get onboardingGetStarted => 'Boshlash';

  @override
  String get onboardingKeyHint =>
      'AI xususiyatlari uchun Sozlamalarda Gemini API kalitini qo\'shing.';

  @override
  String get onboardingOpenSettings => 'Sozlamalarni ochish';

  @override
  String get netOffline => 'Internet aloqasi yo\'q';

  @override
  String get netOnline => 'Internet tiklandi';

  @override
  String get voiceHoldHint => 'Gapirish uchun bosib turing';

  @override
  String get voiceListening => 'Tinglayapman…';

  @override
  String get voiceProcessing => 'Tushunyapman…';

  @override
  String get voiceEmpty => 'Tushunolmadim — qayta urinib ko\'ring';

  @override
  String get voiceNoPermission => 'Mikrofon uchun ruxsat kerak';

  @override
  String get voiceFailed => 'Ovozli qidiruv ishlamadi';

  @override
  String get interestsTitle => 'Qiziqishlaringizni tanlang';

  @override
  String get interestsSubtitle =>
      'Lentangiz uchun bir nechta mavzu tanlang. Keyin sozlamalarda istalgan vaqt o\'zgartirasiz.';

  @override
  String get interestsContinue => 'Davom etish';

  @override
  String get interestsSkip => 'Hozircha o\'tkazib yuborish';
}
