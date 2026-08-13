import 'language_service.dart';

/// `t('key')` çağırarak aktif dile göre metin al. Yeni bir dil eklemek için
/// aşağıya yeni bir `Map` ekleyip [AppLanguage]'e bir değer eklemek yeterli
/// — derleme zamanı kod üretimi gerekmez.
String t(String key) => AppStrings.of(key);

class AppStrings {
  AppStrings._();

  static String of(String key) {
    final map = LanguageService.instance.language == AppLanguage.en ? _en : _tr;
    return map[key] ?? _tr[key] ?? key;
  }

  static const _tr = <String, String>{
    'common_back': 'Geri',
    'common_close': 'Kapat',
    'common_ok': 'Tamam',
    'common_cancel': 'Vazgeç',
    'common_continue': 'Devam Et',
    'common_skip': 'Geç',

    'onboarding_title_1': 'Arkadaşlarınla Eğlen',
    'onboarding_body_1':
        'Oda kodu paylaş, arkadaşların katılsın. 31 farklı oyun — strateji, '
            'parti, arcade ve hikaye — hepsi tek uygulamada.',
    'onboarding_title_2': 'Seviye Atla, Başarım Kazan',
    'onboarding_body_2':
        'Her maç sonunda XP ve coin kazan, başarımların kilidini aç, '
            'liderlik tablosunda yerini al.',
    'onboarding_title_3': 'Aynı Cihazda da Oynanır',
    'onboarding_body_3':
        'İnternet olmasa da olur — cihazı sırayla verin, bilgisayara karşı '
            'oynayın ya da tek başınıza yüksek skor kovalayın.',
    'onboarding_next': 'İleri',
    'onboarding_start': 'Başlayalım',

    'notif_permission_title': 'Bildirimlerden Haberdar Ol',
    'notif_permission_body':
        'Sıra sana geldiğinde, arkadaşın seni odaya davet ettiğinde ya da '
            'yeni bir oyun eklendiğinde haber verelim mi?',
    'notif_permission_allow': 'İzin Ver',
    'notif_permission_later': 'Daha Sonra',

    'settings_title': 'Ayarlar',
    'settings_appearance': 'GÖRÜNÜM',
    'settings_theme': 'Tema',
    'settings_theme_system': 'Sistem',
    'settings_theme_light': 'Açık',
    'settings_theme_dark': 'Koyu',
    'settings_language': 'Dil',
    'settings_account': 'HESAP',
    'settings_notifications': 'Bildirimler',
    'settings_notifications_subtitle': 'Bildirim izinlerini yönet',
    'settings_play_games': 'Google Play Games',
    'settings_play_games_connected': 'Bağlı',
    'settings_play_games_connect': 'Bağlan',
    'settings_support': 'DESTEK & TOPLULUK',
    'settings_donate': 'Bize Kahve Ismarla',
    'settings_donate_subtitle': 'Küçük bir bağış, büyük bir teşekkür',
    'settings_share': 'Uygulamayı Paylaş',
    'settings_share_subtitle': 'Arkadaşlarını davet et',
    'settings_rate': 'Uygulamayı Değerlendir',
    'settings_rate_subtitle': 'Mağazada bize puan ver',
    'settings_legal': 'YASAL',
    'settings_privacy': 'Gizlilik Politikası',
    'settings_terms': 'Kullanım Şartları',
    'settings_version': 'Sürüm',

    'language_title': 'Dil Seç',
    'language_tr': 'Türkçe',
    'language_en': 'İngilizce',

    'privacy_title': 'Gizlilik Politikası',
    'terms_title': 'Kullanım Şartları',

    'donate_title': '☕ Bize Kahve Ismarla',
    'donate_body':
        'AZ Oyun tamamen ücretsiz ve reklamsız-agresif olmama sözü '
            'veriyoruz. Uygulamayı geliştirmeye devam etmemize destek olmak '
            'istersen küçük bir bağış yapabilirsin — tamamen gönüllü, hiçbir '
            'oyun içi avantaj sağlamaz.',
    'donate_button': 'Küçük Bir Bağış Yap',
    'donate_thanks': 'Çok teşekkürler! Desteğin bizim için çok değerli. 💜',

    'settings_premium': 'Premium — 6 Ay Reklamsız',
    'settings_premium_subtitle_buy': 'Tüm reklamları 6 ay boyunca kaldır',
    'settings_premium_active': 'Premium aktif',
    'premium_thanks': 'Premium etkinleştirildi! 6 ay boyunca reklam yok. ✨',
  };

  static const _en = <String, String>{
    'common_back': 'Back',
    'common_close': 'Close',
    'common_ok': 'OK',
    'common_cancel': 'Cancel',
    'common_continue': 'Continue',
    'common_skip': 'Skip',

    'onboarding_title_1': 'Have Fun With Friends',
    'onboarding_body_1':
        'Share a room code, friends join in. 31 different games — '
            'strategy, party, arcade and story — all in one app.',
    'onboarding_title_2': 'Level Up, Earn Achievements',
    'onboarding_body_2':
        'Earn XP and coins after every match, unlock achievements, '
            'climb the leaderboard.',
    'onboarding_title_3': 'Play On One Device Too',
    'onboarding_body_3':
        'No internet? No problem — pass the device around, play against '
            'the computer, or chase a high score solo.',
    'onboarding_next': 'Next',
    'onboarding_start': "Let's Go",

    'notif_permission_title': 'Stay in the Loop',
    'notif_permission_body':
        "Want us to notify you when it's your turn, a friend invites you "
            'to a room, or a new game is added?',
    'notif_permission_allow': 'Allow',
    'notif_permission_later': 'Later',

    'settings_title': 'Settings',
    'settings_appearance': 'APPEARANCE',
    'settings_theme': 'Theme',
    'settings_theme_system': 'System',
    'settings_theme_light': 'Light',
    'settings_theme_dark': 'Dark',
    'settings_language': 'Language',
    'settings_account': 'ACCOUNT',
    'settings_notifications': 'Notifications',
    'settings_notifications_subtitle': 'Manage notification permissions',
    'settings_play_games': 'Google Play Games',
    'settings_play_games_connected': 'Connected',
    'settings_play_games_connect': 'Connect',
    'settings_support': 'SUPPORT & COMMUNITY',
    'settings_donate': 'Buy Us a Coffee',
    'settings_donate_subtitle': 'A small donation, a big thank you',
    'settings_share': 'Share the App',
    'settings_share_subtitle': 'Invite your friends',
    'settings_rate': 'Rate the App',
    'settings_rate_subtitle': 'Give us a rating on the store',
    'settings_legal': 'LEGAL',
    'settings_privacy': 'Privacy Policy',
    'settings_terms': 'Terms of Service',
    'settings_version': 'Version',

    'language_title': 'Choose Language',
    'language_tr': 'Turkish',
    'language_en': 'English',

    'privacy_title': 'Privacy Policy',
    'terms_title': 'Terms of Service',

    'donate_title': '☕ Buy Us a Coffee',
    'donate_body':
        'AZ Oyun promises to stay free and to never be aggressively '
            "ad-heavy. If you'd like to support ongoing development, you "
            'can make a small donation — completely voluntary and it never '
            'grants any in-game advantage.',
    'donate_button': 'Make a Small Donation',
    'donate_thanks': "Thank you so much! Your support means a lot to us. 💜",

    'settings_premium': 'Premium — 6 Months Ad-Free',
    'settings_premium_subtitle_buy': 'Remove all ads for 6 months',
    'settings_premium_active': 'Premium active',
    'premium_thanks': "Premium activated! No ads for 6 months. ✨",
  };
}
