import 'language_service.dart';

/// `t('key')` çağırarak aktif dile göre metin al. Yeni bir dil eklemek için
/// aşağıya yeni bir `Map` ekleyip [AppLanguage]'e bir değer eklemek yeterli
/// — derleme zamanı kod üretimi gerekmez.
String t(String key) => AppStrings.of(key);

class AppStrings {
  AppStrings._();

  static String of(String key) {
    final map = _maps[LanguageService.instance.language] ?? _tr;
    return map[key] ?? _tr[key] ?? key;
  }

  static const Map<AppLanguage, Map<String, String>> _maps = {
    AppLanguage.tr: _tr,
    AppLanguage.en: _en,
    AppLanguage.de: _de,
    AppLanguage.fr: _fr,
    AppLanguage.es: _es,
    AppLanguage.ru: _ru,
  };

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
    'settings_theme_dynamic': 'Telefonun Teması',
    'settings_theme_light': 'Açık',
    'settings_theme_dark': 'Koyu',
    'settings_theme_custom': 'Özel',
    'settings_theme_custom_pick': 'Bir renk seç',
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
    'language_de': 'Almanca',
    'language_fr': 'Fransızca',
    'language_es': 'İspanyolca',
    'language_ru': 'Rusça',

    'privacy_title': 'Gizlilik Politikası',
    'terms_title': 'Kullanım Şartları',
    'privacy_body': _privacyBodyTr,
    'terms_body': _termsBodyTr,

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
    'settings_theme_dynamic': 'Device Theme',
    'settings_theme_light': 'Light',
    'settings_theme_dark': 'Dark',
    'settings_theme_custom': 'Custom',
    'settings_theme_custom_pick': 'Pick a color',
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
    'language_de': 'German',
    'language_fr': 'French',
    'language_es': 'Spanish',
    'language_ru': 'Russian',

    'privacy_title': 'Privacy Policy',
    'terms_title': 'Terms of Service',
    'privacy_body': _privacyBodyEn,
    'terms_body': _termsBodyEn,

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

  static const _de = <String, String>{
    'common_back': 'Zurück',
    'common_close': 'Schließen',
    'common_ok': 'OK',
    'common_cancel': 'Abbrechen',
    'common_continue': 'Weiter',
    'common_skip': 'Überspringen',

    'onboarding_title_1': 'Spaß mit Freunden',
    'onboarding_body_1':
        'Teile einen Raumcode, Freunde treten bei. 31 verschiedene Spiele — '
            'Strategie, Party, Arcade und Geschichte — alles in einer App.',
    'onboarding_title_2': 'Steig auf, sammle Erfolge',
    'onboarding_body_2':
        'Verdiene nach jedem Spiel XP und Münzen, schalte Erfolge frei, '
            'klettere in der Bestenliste.',
    'onboarding_title_3': 'Auch auf einem Gerät spielbar',
    'onboarding_body_3':
        'Kein Internet? Kein Problem — gebt das Gerät reihum weiter, '
            'spielt gegen den Computer oder jagt allein einen Highscore.',
    'onboarding_next': 'Weiter',
    'onboarding_start': "Los geht's",

    'notif_permission_title': 'Bleib auf dem Laufenden',
    'notif_permission_body':
        'Sollen wir dich benachrichtigen, wenn du am Zug bist, ein Freund '
            'dich zu einem Raum einlädt oder ein neues Spiel hinzukommt?',
    'notif_permission_allow': 'Erlauben',
    'notif_permission_later': 'Später',

    'settings_title': 'Einstellungen',
    'settings_appearance': 'DARSTELLUNG',
    'settings_theme': 'Design',
    'settings_theme_dynamic': 'Gerätethema',
    'settings_theme_light': 'Hell',
    'settings_theme_dark': 'Dunkel',
    'settings_theme_custom': 'Eigene',
    'settings_theme_custom_pick': 'Farbe auswählen',
    'settings_language': 'Sprache',
    'settings_account': 'KONTO',
    'settings_notifications': 'Benachrichtigungen',
    'settings_notifications_subtitle': 'Benachrichtigungsberechtigungen verwalten',
    'settings_play_games': 'Google Play Games',
    'settings_play_games_connected': 'Verbunden',
    'settings_play_games_connect': 'Verbinden',
    'settings_support': 'SUPPORT & COMMUNITY',
    'settings_donate': 'Spendiere uns einen Kaffee',
    'settings_donate_subtitle': 'Eine kleine Spende, ein großes Dankeschön',
    'settings_share': 'App teilen',
    'settings_share_subtitle': 'Lade deine Freunde ein',
    'settings_rate': 'App bewerten',
    'settings_rate_subtitle': 'Gib uns eine Bewertung im Store',
    'settings_legal': 'RECHTLICHES',
    'settings_privacy': 'Datenschutzerklärung',
    'settings_terms': 'Nutzungsbedingungen',
    'settings_version': 'Version',

    'language_title': 'Sprache wählen',
    'language_tr': 'Türkisch',
    'language_en': 'Englisch',
    'language_de': 'Deutsch',
    'language_fr': 'Französisch',
    'language_es': 'Spanisch',
    'language_ru': 'Russisch',

    'privacy_title': 'Datenschutzerklärung',
    'terms_title': 'Nutzungsbedingungen',

    'donate_title': '☕ Spendiere uns einen Kaffee',
    'donate_body':
        'AZ Oyun verspricht, kostenlos zu bleiben und nie aufdringlich '
            'Werbung zu zeigen. Wenn du die Weiterentwicklung unterstützen '
            'möchtest, kannst du eine kleine Spende machen — völlig '
            'freiwillig und ohne jeden Spielvorteil.',
    'donate_button': 'Kleine Spende machen',
    'donate_thanks': 'Vielen herzlichen Dank! Deine Unterstützung bedeutet uns sehr viel. 💜',

    'settings_premium': 'Premium — 6 Monate werbefrei',
    'settings_premium_subtitle_buy': 'Entferne alle Werbung für 6 Monate',
    'settings_premium_active': 'Premium aktiv',
    'premium_thanks': 'Premium aktiviert! 6 Monate lang keine Werbung. ✨',
  };

  static const _fr = <String, String>{
    'common_back': 'Retour',
    'common_close': 'Fermer',
    'common_ok': 'OK',
    'common_cancel': 'Annuler',
    'common_continue': 'Continuer',
    'common_skip': 'Passer',

    'onboarding_title_1': 'Amuse-toi avec tes amis',
    'onboarding_body_1':
        'Partage un code de salon, tes amis rejoignent. 31 jeux différents '
            '— stratégie, soirée, arcade et histoire — tous dans une seule '
            'appli.',
    'onboarding_title_2': 'Monte de niveau, débloque des succès',
    'onboarding_body_2':
        "Gagne de l'XP et des pièces après chaque partie, débloque des "
            'succès, grimpe dans le classement.',
    'onboarding_title_3': 'Jouable aussi sur un seul appareil',
    'onboarding_body_3':
        "Pas d'internet ? Pas de problème — faites passer l'appareil à "
            "tour de rôle, jouez contre l'ordinateur ou visez le meilleur "
            'score en solo.',
    'onboarding_next': 'Suivant',
    'onboarding_start': "C'est parti",

    'notif_permission_title': 'Reste informé',
    'notif_permission_body':
        "On te prévient quand c'est ton tour, qu'un ami t'invite dans un "
            'salon, ou qu\'un nouveau jeu est ajouté ?',
    'notif_permission_allow': 'Autoriser',
    'notif_permission_later': 'Plus tard',

    'settings_title': 'Paramètres',
    'settings_appearance': 'APPARENCE',
    'settings_theme': 'Thème',
    'settings_theme_dynamic': 'Thème du téléphone',
    'settings_theme_light': 'Clair',
    'settings_theme_dark': 'Sombre',
    'settings_theme_custom': 'Personnalisé',
    'settings_theme_custom_pick': 'Choisir une couleur',
    'settings_language': 'Langue',
    'settings_account': 'COMPTE',
    'settings_notifications': 'Notifications',
    'settings_notifications_subtitle': 'Gérer les autorisations de notification',
    'settings_play_games': 'Google Play Games',
    'settings_play_games_connected': 'Connecté',
    'settings_play_games_connect': 'Se connecter',
    'settings_support': 'SOUTIEN & COMMUNAUTÉ',
    'settings_donate': 'Offre-nous un café',
    'settings_donate_subtitle': 'Un petit don, un grand merci',
    'settings_share': "Partager l'appli",
    'settings_share_subtitle': 'Invite tes amis',
    'settings_rate': "Évaluer l'appli",
    'settings_rate_subtitle': 'Laisse-nous une note sur le store',
    'settings_legal': 'MENTIONS LÉGALES',
    'settings_privacy': 'Politique de confidentialité',
    'settings_terms': "Conditions d'utilisation",
    'settings_version': 'Version',

    'language_title': 'Choisir la langue',
    'language_tr': 'Turc',
    'language_en': 'Anglais',
    'language_de': 'Allemand',
    'language_fr': 'Français',
    'language_es': 'Espagnol',
    'language_ru': 'Russe',

    'privacy_title': 'Politique de confidentialité',
    'terms_title': "Conditions d'utilisation",

    'donate_title': '☕ Offre-nous un café',
    'donate_body':
        'AZ Oyun promet de rester gratuit et de ne jamais afficher de '
            'publicité envahissante. Si tu veux soutenir le développement '
            'continu, tu peux faire un petit don — entièrement volontaire '
            'et sans aucun avantage en jeu.',
    'donate_button': 'Faire un petit don',
    'donate_thanks': 'Merci beaucoup ! Ton soutien compte énormément pour nous. 💜',

    'settings_premium': 'Premium — 6 mois sans pub',
    'settings_premium_subtitle_buy': 'Supprime toutes les publicités pendant 6 mois',
    'settings_premium_active': 'Premium actif',
    'premium_thanks': 'Premium activé ! Plus de pub pendant 6 mois. ✨',
  };

  static const _es = <String, String>{
    'common_back': 'Atrás',
    'common_close': 'Cerrar',
    'common_ok': 'Aceptar',
    'common_cancel': 'Cancelar',
    'common_continue': 'Continuar',
    'common_skip': 'Omitir',

    'onboarding_title_1': 'Diviértete con tus amigos',
    'onboarding_body_1':
        'Comparte un código de sala, tus amigos se unen. 31 juegos '
            'diferentes — estrategia, fiesta, arcade e historia — todo en '
            'una sola app.',
    'onboarding_title_2': 'Sube de nivel, gana logros',
    'onboarding_body_2':
        'Gana XP y monedas después de cada partida, desbloquea logros, '
            'sube en la clasificación.',
    'onboarding_title_3': 'También se juega en un solo dispositivo',
    'onboarding_body_3':
        '¿Sin internet? No hay problema — pasen el dispositivo por turnos, '
            'jueguen contra la computadora o persigan un puntaje alto en '
            'solitario.',
    'onboarding_next': 'Siguiente',
    'onboarding_start': 'Empecemos',

    'notif_permission_title': 'Mantente al tanto',
    'notif_permission_body':
        '¿Quieres que te avisemos cuando sea tu turno, un amigo te invite '
            'a una sala o se añada un nuevo juego?',
    'notif_permission_allow': 'Permitir',
    'notif_permission_later': 'Más tarde',

    'settings_title': 'Ajustes',
    'settings_appearance': 'APARIENCIA',
    'settings_theme': 'Tema',
    'settings_theme_dynamic': 'Tema del teléfono',
    'settings_theme_light': 'Claro',
    'settings_theme_dark': 'Oscuro',
    'settings_theme_custom': 'Personalizado',
    'settings_theme_custom_pick': 'Elegir un color',
    'settings_language': 'Idioma',
    'settings_account': 'CUENTA',
    'settings_notifications': 'Notificaciones',
    'settings_notifications_subtitle': 'Gestionar permisos de notificación',
    'settings_play_games': 'Google Play Games',
    'settings_play_games_connected': 'Conectado',
    'settings_play_games_connect': 'Conectar',
    'settings_support': 'APOYO Y COMUNIDAD',
    'settings_donate': 'Invítanos un café',
    'settings_donate_subtitle': 'Una pequeña donación, un gran agradecimiento',
    'settings_share': 'Compartir la app',
    'settings_share_subtitle': 'Invita a tus amigos',
    'settings_rate': 'Valorar la app',
    'settings_rate_subtitle': 'Danos una calificación en la tienda',
    'settings_legal': 'LEGAL',
    'settings_privacy': 'Política de privacidad',
    'settings_terms': 'Términos de servicio',
    'settings_version': 'Versión',

    'language_title': 'Elegir idioma',
    'language_tr': 'Turco',
    'language_en': 'Inglés',
    'language_de': 'Alemán',
    'language_fr': 'Francés',
    'language_es': 'Español',
    'language_ru': 'Ruso',

    'privacy_title': 'Política de privacidad',
    'terms_title': 'Términos de servicio',

    'donate_title': '☕ Invítanos un café',
    'donate_body':
        'AZ Oyun promete seguir siendo gratis y no mostrar nunca '
            'publicidad invasiva. Si quieres apoyar el desarrollo continuo, '
            'puedes hacer una pequeña donación — totalmente voluntaria y '
            'sin ninguna ventaja dentro del juego.',
    'donate_button': 'Hacer una pequeña donación',
    'donate_thanks': '¡Muchas gracias! Tu apoyo significa mucho para nosotros. 💜',

    'settings_premium': 'Premium — 6 meses sin anuncios',
    'settings_premium_subtitle_buy': 'Elimina todos los anuncios durante 6 meses',
    'settings_premium_active': 'Premium activo',
    'premium_thanks': '¡Premium activado! Sin anuncios durante 6 meses. ✨',
  };

  static const _ru = <String, String>{
    'common_back': 'Назад',
    'common_close': 'Закрыть',
    'common_ok': 'ОК',
    'common_cancel': 'Отмена',
    'common_continue': 'Продолжить',
    'common_skip': 'Пропустить',

    'onboarding_title_1': 'Веселись с друзьями',
    'onboarding_body_1':
        'Поделись кодом комнаты, друзья присоединятся. 31 разная игра — '
            'стратегии, вечеринки, аркады и истории — всё в одном '
            'приложении.',
    'onboarding_title_2': 'Повышай уровень, получай достижения',
    'onboarding_body_2':
        'Зарабатывай опыт и монеты после каждого матча, открывай '
            'достижения, поднимайся в таблице лидеров.',
    'onboarding_title_3': 'Можно играть и на одном устройстве',
    'onboarding_body_3':
        'Нет интернета? Не проблема — передавайте устройство по очереди, '
            'играйте против компьютера или в одиночку бейте рекорд.',
    'onboarding_next': 'Далее',
    'onboarding_start': 'Начнём',

    'notif_permission_title': 'Будь в курсе',
    'notif_permission_body':
        'Уведомлять тебя, когда наступает твой ход, друг приглашает в '
            'комнату или добавляется новая игра?',
    'notif_permission_allow': 'Разрешить',
    'notif_permission_later': 'Позже',

    'settings_title': 'Настройки',
    'settings_appearance': 'ВНЕШНИЙ ВИД',
    'settings_theme': 'Тема',
    'settings_theme_dynamic': 'Тема телефона',
    'settings_theme_light': 'Светлая',
    'settings_theme_dark': 'Тёмная',
    'settings_theme_custom': 'Своя',
    'settings_theme_custom_pick': 'Выбрать цвет',
    'settings_language': 'Язык',
    'settings_account': 'АККАУНТ',
    'settings_notifications': 'Уведомления',
    'settings_notifications_subtitle': 'Управление разрешениями на уведомления',
    'settings_play_games': 'Google Play Игры',
    'settings_play_games_connected': 'Подключено',
    'settings_play_games_connect': 'Подключить',
    'settings_support': 'ПОДДЕРЖКА И СООБЩЕСТВО',
    'settings_donate': 'Угости нас кофе',
    'settings_donate_subtitle': 'Небольшое пожертвование — большое спасибо',
    'settings_share': 'Поделиться приложением',
    'settings_share_subtitle': 'Пригласи друзей',
    'settings_rate': 'Оценить приложение',
    'settings_rate_subtitle': 'Поставь нам оценку в магазине',
    'settings_legal': 'ПРАВОВАЯ ИНФОРМАЦИЯ',
    'settings_privacy': 'Политика конфиденциальности',
    'settings_terms': 'Условия использования',
    'settings_version': 'Версия',

    'language_title': 'Выбрать язык',
    'language_tr': 'Турецкий',
    'language_en': 'Английский',
    'language_de': 'Немецкий',
    'language_fr': 'Французский',
    'language_es': 'Испанский',
    'language_ru': 'Русский',

    'privacy_title': 'Политика конфиденциальности',
    'terms_title': 'Условия использования',

    'donate_title': '☕ Угости нас кофе',
    'donate_body':
        'AZ Oyun обещает оставаться бесплатным и никогда не показывать '
            'навязчивую рекламу. Если хочешь поддержать дальнейшую '
            'разработку, можешь сделать небольшое пожертвование — '
            'полностью добровольно и без каких-либо игровых преимуществ.',
    'donate_button': 'Сделать небольшое пожертвование',
    'donate_thanks': 'Большое спасибо! Твоя поддержка очень много значит для нас. 💜',

    'settings_premium': 'Премиум — 6 месяцев без рекламы',
    'settings_premium_subtitle_buy': 'Убрать всю рекламу на 6 месяцев',
    'settings_premium_active': 'Премиум активен',
    'premium_thanks': 'Премиум активирован! 6 месяцев без рекламы. ✨',
  };
}

// ═══════════════════════════════════════════════════════════════════════════
// GİZLİLİK POLİTİKASI + KULLANIM ŞARTLARI — uygulama içi tam metinler.
// Web sürümüyle (web/privacy-policy.html, web/terms.html ve İngilizce
// karşılıkları web/en/) aynı içeriği taşır — biri değişirse diğeri de
// güncellenmelidir. Şu an sadece TR ve EN dolu; diğer diller TR'ye düşer
// (bkz. AppStrings.of fallback'i).
// ═══════════════════════════════════════════════════════════════════════════

const _legalLastUpdatedTr = '4 Kasım 2026';
const _legalLastUpdatedEn = 'November 4, 2026';

const _privacyBodyTr = '''
Son güncelleme: $_legalLastUpdatedTr

AZ Oyun ("biz", "uygulama"), geliştiricisi Ferdi Durgun tarafından işletilir. Gizliliğinize önem veriyoruz. Bu Gizlilik Politikası, AZ Oyun'u (Android, iOS ve azoyun.web.app web sürümü) kullanırken hangi verilerin toplandığını, nasıl kullanıldığını, kimlerle paylaşıldığını ve haklarınızın ne olduğunu açıklar.

1. TOPLADIĞIMIZ VERİLER

• Oyuncu adı: Kendi seçtiğiniz takma ad; cihazınızda saklanır ve online oyunlarda diğer oyunculara gösterilir. Hesap/e-posta/şifre istemiyoruz, misafir olarak oynanabilir.
• Oyun içi verileri: Online oda oyunlarında oda kodu, hamleler ve skorlar Firebase Realtime Database üzerinde oyun süresince geçici olarak tutulur, oda kapandığında silinir.
• İlerleme verileri: Seviye, XP, coin ve başarımlar cihazınızda yerel olarak (shared_preferences / secure storage) saklanır.
• Teknik ve kullanım verileri: Firebase Analytics ile anonimleştirilmiş kullanım istatistikleri (açılan ekranlar, oynanan oyun türü, oturum süresi) ve Firebase Crashlytics ile çökme/hata raporları (cihaz modeli, işletim sistemi sürümü, hata yığın izi) topluyoruz. Bu veriler uygulamayı iyileştirmek için kullanılır ve kimliğinizi doğrudan belirlemez.
• Reklam verileri: Google AdMob (mobil) ve Google AdSense (web) reklamları göstermek için cihazınızın reklam kimliğini (Advertising ID/GAID, IDFA) ve web'de çerezleri kullanabilir. Bkz. Bölüm 4.
• Bildirim jetonu: Bildirim izni verirseniz Firebase Cloud Messaging cihazınıza özgü bir jeton oluşturur; bu jeton sadece size bildirim göndermek için kullanılır.
• Google Play Games Services / Game Center: Bağlanmayı seçerseniz, Google/Apple hesabınızla ilişkili oyuncu kimliği, liderlik tablosu ve başarım verileri bu servislerle paylaşılır.
• Satın alma verileri: Uygulama içi satın alma (reklam kaldırma, coin paketi, 6 aylık premium, gönüllü bağış) Google Play / App Store üzerinden işlenir. Kredi kartı veya ödeme bilgilerinizi biz görmeyiz, saklamayız; sadece işlemin başarılı olup olmadığı bilgisini alırız.

2. VERİLERİ NASIL KULLANIYORUZ

Verileriniz şu amaçlarla kullanılır: uygulamanın çalışması (oda eşleştirme, ilerleme takibi), hata ayıklama ve performans iyileştirme (Crashlytics/Analytics), bildirim gönderme, reklam gösterimi ve satın alma haklarının teslimi. Verilerinizi satmıyoruz ve pazarlama amacıyla üçüncü taraflara aktarmıyoruz.

3. ÜÇÜNCÜ TARAF HİZMET SAĞLAYICILAR

Uygulama aşağıdaki üçüncü taraf hizmetleri kullanır; her biri kendi gizlilik politikasına tabidir:

• Google Firebase — Analytics, Crashlytics, Realtime Database, Cloud Messaging (privacy.google.com)
• Google AdMob — mobil uygulama içi reklamlar (policies.google.com/technologies/ads)
• Google AdSense — web sürümü (azoyun.web.app) reklamları
• Google Play Games Services / Apple Game Center — liderlik tablosu ve başarımlar
• Google Play Billing / Apple In-App Purchase — uygulama içi satın almaların işlenmesi

4. REKLAMLAR, ÇEREZLER VE KİŞİSELLEŞTİRİLMİŞ REKLAM TERCİHLERİ

Google dahil üçüncü taraf reklam satıcıları, reklam sunmak için çerezler ve mobil reklam kimlikleri kullanır. Google'ın reklam çerezlerini kullanması, Google'ın ve iş ortaklarının kullanıcılara AZ Oyun'daki ve/veya internetteki diğer sitelerdeki önceki ziyaretlerine dayanarak reklam sunmasına olanak tanır.

Kişiselleştirilmiş reklamları devre dışı bırakmak isterseniz:
• Web'de Google Reklam Ayarları (adssettings.google.com) veya www.aboutads.info üzerinden üçüncü taraf satıcı çerezlerini devre dışı bırakabilirsiniz.
• Mobilde cihazınızın işletim sistemi ayarlarından (Android: Ayarlar → Gizlilik → Reklamlar; iOS: Ayarlar → Gizlilik → Reklam) reklam kişiselleştirmesini sınırlayabilir veya reklam kimliğinizi sıfırlayabilirsiniz.
• Reklamsız deneyim için uygulama içinden kalıcı "Reklamları Kaldır" veya "6 Ay Premium" satın alabilirsiniz.

5. ÇOCUKLARIN GİZLİLİĞİ

AZ Oyun genel kitleye yöneliktir ve 13 yaş altı kullanıcılardan bilerek kişisel veri toplamıyoruz. 13 yaşından küçük bir çocuğun bize veri sağladığını fark edersek bu veriyi sileriz. Bir veli/vasi olarak çocuğunuzun bize veri sağladığını düşünüyorsanız Bölüm 9'daki iletişim bilgilerinden bize ulaşın.

6. VERİ GÜVENLİĞİ

Verileriniz Google Firebase altyapısında endüstri standardı güvenlik önlemleriyle (şifreli aktarım, erişim kontrolü) saklanır. Hiçbir sistem %100 güvenli değildir; makul güvenlik önlemleri alsak da mutlak güvenlik garanti edilemez.

7. VERİ SAKLAMA VE SİLME

Yerel verileri (ilerleme, tema, dil tercihi) uygulamayı cihazınızdan silerek kaldırabilirsiniz. Online oda verileri, oda kapandığında veya belirli bir süre işlem görmediğinde sunucudan otomatik silinir. Analytics/Crashlytics verileri Google'ın kendi saklama politikalarına göre periyodik olarak anonimleştirilir veya silinir.

8. HAKLARINIZ (KVKK ve GDPR)

6698 sayılı KVKK ve ilgili olduğu ölçüde GDPR kapsamında; verilerinizin işlenip işlenmediğini öğrenme, işlenmişse bilgi talep etme, düzeltilmesini veya silinmesini isteme ve işlemeye itiraz etme hakkına sahipsiniz. Bu taleplerinizi Bölüm 9'daki iletişim yollarıyla bize iletebilirsiniz; makul bir süre içinde yanıtlarız.

9. İLETİŞİM

Bu Gizlilik Politikası veya kişisel verilerinizle ilgili sorularınız için Google Play / App Store'daki uygulama sayfamızdaki geliştirici (Ferdi Durgun) iletişim bilgilerini kullanabilir veya azoyun.web.app üzerinden bize ulaşabilirsiniz.

10. DEĞİŞİKLİKLER

Bu politikayı zaman zaman güncelleyebiliriz. Önemli değişiklikler uygulama içinde duyurulur ve bu sayfadaki "Son güncelleme" tarihi yenilenir.
''';

const _termsBodyTr = '''
Son güncelleme: $_legalLastUpdatedTr

Bu Kullanım Şartları ("Şartlar"), geliştiricisi Ferdi Durgun olan AZ Oyun uygulamasını (Android, iOS, azoyun.web.app) kullanırken uymanız gereken kuralları belirler. Uygulamayı indirip kullanarak bu Şartları kabul etmiş olursunuz.

1. HİZMETİN TANIMI

AZ Oyun; Dama, Okey, çok oyunculu sosyal çıkarım oyunları ve tek-cihaz parti oyunları dahil 30'dan fazla oyunu içeren, hesap gerektirmeyen (misafir olarak oynanabilen) ücretsiz bir eğlence uygulamasıdır. Hizmet reklam destekli sunulur; isteğe bağlı uygulama içi satın almalar mevcuttur.

2. UYGUNLUK

Uygulama genel kitleye yöneliktir. 13 yaşından küçükseniz uygulamayı bir ebeveyn/vasi gözetiminde kullanmalısınız.

3. HİZMETİN KULLANIMI

AZ Oyun'u yasalara uygun, saygılı ve adil bir şekilde kullanmayı kabul edersiniz. Aşağıdakiler yasaktır: hile/bot kullanımı, diğer oyuncuları taciz etme, uygunsuz/hakaret içeren kullanıcı adı veya içerik paylaşma, uygulamayı tersine mühendislikle incelemeye çalışma veya sunucu/oda altyapısını kötüye kullanma.

4. HESAP VE İÇERİK

Hesap oluşturmadan (misafir olarak) oynayabilirsiniz; girdiğiniz takma addan ve paylaştığınız içerikten siz sorumlusunuz. Uygunsuz kullanıcı adları veya davranışlar bildirilebilir ve ilgili odadan/oturumdan engellenebilirsiniz.

5. REKLAMLAR

Uygulama Google AdMob (mobil) ve Google AdSense (web) aracılığıyla banner ve geçiş (interstitial) reklamlar gösterir. Reklam içeriği Google ve reklam verenler tarafından belirlenir; reklam içeriğinden veya reklama tıklayarak gittiğiniz üçüncü taraf sitelerden sorumlu değiliz. Reklamsız deneyim satın alarak reklamları kaldırabilirsiniz.

6. UYGULAMA İÇİ SATIN ALMALAR

Reklam kaldırma, coin paketleri, 6 aylık premium ve gönüllü bağış satın almaları tamamen isteğe bağlıdır ve hiçbir oyun içi rekabet avantajı (pay-to-win) sağlamaz — AZ Oyun'un temel ilkesi budur. Satın almalar Google Play / App Store üzerinden işlenir ve ilgili mağazanın iade/fatura politikalarına tabidir; biz ödeme bilgilerinizi tutmayız.

7. FİKRİ MÜLKİYET

Uygulamanın tasarımı, kodu, logosu ve özgün içerikleri (örn. Dedektif Kampanyası hikâyesi) AZ Oyun'a aittir. İzinsiz kopyalama, dağıtma veya ticari amaçla kullanma yasaktır.

8. ÜÇÜNCÜ TARAF HİZMETLER

Uygulama Google Firebase, Google Play Games Services, Apple Game Center ve ilgili mağaza ödeme sistemlerini kullanır; bu hizmetlerin kendi kullanım şartları ayrıca geçerlidir.

9. HİZMETİN DEĞİŞTİRİLMESİ VEYA SONLANDIRILMASI

Hizmeti, özellikleri veya belirli oyunları önceden bildirmeden ekleyebilir, değiştirebilir veya kaldırabiliriz. Kötüye kullanım tespit edilirse bir kullanıcının/oturumun erişimini kısıtlayabiliriz.

10. GARANTİ REDDİ

Uygulama "olduğu gibi" ve "mevcut haliyle" sunulur. Kesintisiz, hatasız veya her cihazla uyumlu çalışacağını garanti etmiyoruz.

11. SORUMLULUĞUN SINIRLANDIRILMASI

Yürürlükteki kanunların izin verdiği azami ölçüde, uygulamanın kullanımından veya kullanılamamasından doğabilecek dolaylı, arızi veya sonuç niteliğindeki zararlardan sorumlu değiliz.

12. GEÇERLİ HUKUK

Bu Şartlar Türkiye Cumhuriyeti kanunlarına tabidir; uyuşmazlıklarda Türkiye mahkemeleri yetkilidir.

13. DEĞİŞİKLİKLER

Bu Şartları zaman zaman güncelleyebiliriz; önemli değişiklikler uygulama içinde duyurulur ve bu sayfadaki "Son güncelleme" tarihi yenilenir. Güncelleme sonrası uygulamayı kullanmaya devam etmeniz yeni Şartları kabul ettiğiniz anlamına gelir.

14. İLETİŞİM

Sorularınız için Google Play / App Store'daki uygulama sayfamızdaki geliştirici (Ferdi Durgun) iletişim bilgilerini kullanabilir veya azoyun.web.app üzerinden bize ulaşabilirsiniz.
''';

const _privacyBodyEn = '''
Last updated: $_legalLastUpdatedEn

AZ Oyun ("we", "the app") is developed and operated by Ferdi Durgun. We care about your privacy. This Privacy Policy explains what data is collected, how it is used, who it is shared with, and what your rights are when you use AZ Oyun (Android, iOS, and the azoyun.web.app web version).

1. DATA WE COLLECT

• Player name: A nickname of your choosing; stored on your device and shown to other players in online games. We don't require an account, email, or password — you can play as a guest.
• In-game data: In online room games, the room code, moves, and scores are temporarily held in Firebase Realtime Database for the duration of the game and deleted when the room closes.
• Progress data: Level, XP, coins, and achievements are stored locally on your device (shared_preferences / secure storage).
• Technical and usage data: We use Firebase Analytics for anonymized usage statistics (screens viewed, game types played, session length) and Firebase Crashlytics for crash/error reports (device model, OS version, error stack trace). This data is used to improve the app and does not directly identify you.
• Advertising data: Google AdMob (mobile) and Google AdSense (web) may use your device's advertising identifier (Advertising ID/GAID, IDFA) and, on web, cookies, to serve ads. See Section 4.
• Notification token: If you grant notification permission, Firebase Cloud Messaging generates a token unique to your device, used solely to send you notifications.
• Google Play Games Services / Game Center: If you choose to connect, your player ID, leaderboard, and achievement data linked to your Google/Apple account are shared with these services.
• Purchase data: In-app purchases (remove ads, coin packs, 6-month premium, voluntary donation) are processed via Google Play / the App Store. We never see or store your card or payment details — we only receive confirmation of whether the transaction succeeded.

2. HOW WE USE DATA

Your data is used to: operate the app (room matchmaking, progress tracking), debug and improve performance (Crashlytics/Analytics), send notifications, serve ads, and fulfill purchases. We do not sell your data and do not transfer it to third parties for marketing purposes.

3. THIRD-PARTY SERVICE PROVIDERS

The app uses the following third-party services, each subject to its own privacy policy:

• Google Firebase — Analytics, Crashlytics, Realtime Database, Cloud Messaging (privacy.google.com)
• Google AdMob — in-app mobile ads (policies.google.com/technologies/ads)
• Google AdSense — ads on the web version (azoyun.web.app)
• Google Play Games Services / Apple Game Center — leaderboards and achievements
• Google Play Billing / Apple In-App Purchase — processing in-app purchases

4. ADVERTISING, COOKIES, AND PERSONALIZED AD CHOICES

Third-party ad vendors, including Google, use cookies and mobile advertising identifiers to serve ads. Google's use of advertising cookies enables Google and its partners to serve ads based on your prior visits to AZ Oyun and/or other sites on the internet.

If you'd like to opt out of personalized ads:
• On the web, you can disable third-party vendor cookies via Google Ad Settings (adssettings.google.com) or www.aboutads.info.
• On mobile, you can limit ad personalization or reset your advertising identifier from your device's OS settings (Android: Settings → Privacy → Ads; iOS: Settings → Privacy → Advertising).
• For an ad-free experience, you can purchase a permanent "Remove Ads" or "6-Month Premium" from within the app.

5. CHILDREN'S PRIVACY

AZ Oyun is intended for a general audience and we do not knowingly collect personal data from users under 13. If we become aware that a child under 13 has provided us with data, we will delete it. If you are a parent/guardian and believe your child has provided us with data, please contact us using the details in Section 9.

6. DATA SECURITY

Your data is stored on Google Firebase infrastructure with industry-standard security measures (encrypted transit, access control). No system is 100% secure; while we take reasonable precautions, absolute security cannot be guaranteed.

7. DATA RETENTION AND DELETION

You can remove local data (progress, theme, language preference) by uninstalling the app from your device. Online room data is automatically deleted from the server when the room closes or after a period of inactivity. Analytics/Crashlytics data is periodically anonymized or deleted according to Google's own retention policies.

8. YOUR RIGHTS (Turkish KVKK Law No. 6698 and, where applicable, GDPR)

Under Turkish Law No. 6698 on the Protection of Personal Data (KVKK) and, where applicable, the GDPR, you have the right to learn whether your data is being processed, request information about it, request correction or deletion, and object to processing. You may submit these requests to us using the contact details in Section 9; we will respond within a reasonable time.

9. CONTACT

For questions about this Privacy Policy or your personal data, you can use the developer (Ferdi Durgun) contact details on our Google Play / App Store listing, or reach us via azoyun.web.app.

10. CHANGES

We may update this policy from time to time. Significant changes will be announced in the app, and the "Last updated" date on this page will be refreshed.
''';

const _termsBodyEn = '''
Last updated: $_legalLastUpdatedEn

These Terms of Service ("Terms") set out the rules you must follow when using AZ Oyun (Android, iOS, azoyun.web.app), developed by Ferdi Durgun. By downloading and using the app, you agree to these Terms.

1. DESCRIPTION OF SERVICE

AZ Oyun is a free entertainment app offering 30+ games, including Checkers, Okey, multiplayer social-deduction games, and single-device party games, with no account required (you can play as a guest). The service is ad-supported; optional in-app purchases are available.

2. ELIGIBILITY

The app is intended for a general audience. If you are under 13, you should use the app under the supervision of a parent or guardian.

3. USE OF THE SERVICE

You agree to use AZ Oyun lawfully, respectfully, and fairly. The following are prohibited: using cheats/bots, harassing other players, using inappropriate or offensive usernames or content, attempting to reverse-engineer the app, or abusing the server/room infrastructure.

4. ACCOUNT AND CONTENT

You can play without creating an account (as a guest); you are responsible for the nickname you enter and the content you share. Inappropriate usernames or behavior may be reported and you may be blocked from the relevant room/session.

5. ADVERTISING

The app displays banner and interstitial ads via Google AdMob (mobile) and Google AdSense (web). Ad content is determined by Google and advertisers; we are not responsible for ad content or for third-party sites you reach by clicking an ad. You can remove ads by purchasing an ad-free experience.

6. IN-APP PURCHASES

Purchases such as removing ads, coin packs, 6-month premium, and voluntary donations are entirely optional and provide no in-game competitive advantage (pay-to-win) — this is a core principle of AZ Oyun. Purchases are processed via Google Play / the App Store and are subject to that store's refund/billing policies; we do not retain your payment details.

7. INTELLECTUAL PROPERTY

The app's design, code, logo, and original content (e.g. the Detective Campaign storyline) belong to AZ Oyun. Unauthorized copying, distribution, or commercial use is prohibited.

8. THIRD-PARTY SERVICES

The app uses Google Firebase, Google Play Games Services, Apple Game Center, and the relevant store payment systems; each of these services' own terms of service also apply.

9. MODIFICATION OR TERMINATION OF SERVICE

We may add, change, or remove the service, features, or specific games without prior notice. We may restrict a user's/session's access if abuse is detected.

10. DISCLAIMER OF WARRANTIES

The app is provided "as is" and "as available." We do not guarantee that it will be uninterrupted, error-free, or compatible with every device.

11. LIMITATION OF LIABILITY

To the maximum extent permitted by applicable law, we are not liable for any indirect, incidental, or consequential damages arising from your use or inability to use the app.

12. GOVERNING LAW

These Terms are governed by the laws of the Republic of Türkiye; Turkish courts have jurisdiction over any disputes.

13. CHANGES

We may update these Terms from time to time; significant changes will be announced in the app, and the "Last updated" date on this page will be refreshed. Continuing to use the app after an update means you accept the new Terms.

14. CONTACT

For questions, you can use the developer (Ferdi Durgun) contact details on our Google Play / App Store listing, or reach us via azoyun.web.app.
''';
