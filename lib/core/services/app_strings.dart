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
    'settings_theme_system': 'Sistem',
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
    'settings_theme_system': 'System',
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
    'settings_theme_system': 'Système',
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
    'settings_theme_system': 'Sistema',
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
    'settings_theme_system': 'Системная',
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
