# Oyuncu ilerlemesi ve oda temizliği

## Aile Masası ve web

Web sıralaması, Aile Masası sunucusunun tamamladığı maçları kullanır. Kurucunun kapattığı ve terk edilen masalar ödül vermez. Tamamlanmış her maçın ayrı kimliği vardır. Aynı sonuç yeniden işlenirse puan ve rozet tekrarlanmaz. Oda dosyası silindikten sonra profil ve sonuç kayıtları ayrı kalıcı dosyada kalır. [Sunucu kurulumu](FAMILY_TABLE.md)

Web ve mobil Aile Masası’nda aynı sunucuya bağlanırken aynı oyuncu anahtarı kullanılabilir. Bu profil AZ Oyun’un tarayıcı tabanlı sıralaması içindir. Google Play Games profili Android’de ayrıca çalışır. Web’deki tek kişilik ve yerel oyun sonuçları Aile Masası sıralamasına dahil edilmez.

Aile Masası sıralaması, tamamlanan maçlardan biriken XP’yi gösterir. Oyun başına beceri puanı ileride ayrı bir veri olabilir. Lichess, beceri puanını oyun türüne göre tutar. Board Game Arena, terk edilen oyunları oyuncu itibarıyla ilişkilendirir. Chess.com kazanılan madalyaları profilde gösterir. [Lichess](https://lichess.org/faq) · [Board Game Arena](https://en.studio.m.boardgamearena.com/faq) · [Chess.com](https://support.chess.com/en/articles/8724664-what-are-medals-on-chess-com)

## Firebase’deki mobil odalar

`sweepLegacyGameRooms` beş dakikada bir çalışır. Güvenilir bağlantı kaydı bulunan ve boş kalan mobil odalar 10 dakikalık yeniden bağlanma süresinden sonra, bitmiş odalar ilk görüldükten yaklaşık iki saat sonra silinir. Silmeden önce oda Firebase işlemi içinde yeniden kontrol edilir. Bağlantı bilgisi eksik eski aktif odalar korunur.

Kurulum ve test için `npm --prefix functions ci` ve `npm --prefix functions test` çalıştır. Firebase’de zamanlanmış iş etkinleştirmek için ilgili proje ve Cloud Scheduler erişimi gerekir. `firebase deploy --only functions:legacy-rooms --project azoyun-569b2` oda temizliği kod tabanını yayınlar. Bağlantı takibi için mobil uygulamanın güncellenmesi gerekir.

## Android ve Google Play Games

AZ Oyun profili, Android’de aynı Play Games hesabıyla açıldığında Saved Games üzerinden XP, seviye, istatistik ve rozetleri geri yükler. Play Console’da **Saved Games** etkin olmalı. AZ Oyun içi XP ile Google Play Games profil XP’si ayrı ilerler. Play Games XP’si, Play Console’da tanımlanan başarımlar açıldığında Google tarafından verilir.

Mobilde tamamlanan maç 2 AZ XP, galibiyet 5 AZ XP verir. Rozet hedefleri ayrıca bonus verebilir. Jeton bakiyesi cihazda tutulur.

Birleştirme için en son 512 maç kimliği saklanır. İki cihaz çevrimdışı oynarsa her cihazın yeniden bağlanıp senkronize olması gerekir. Bu pencerenin dışındaki eşzamanlı sonuçlar maç kimliğiyle birleştirilemez.

Gerçek başarı ve XP sıralama kimlikleri Play Console’dan alınır. Henüz tanımlanmamış olanlar GitHub depo değişkenlerine eklendikten sonra yeni Android paketiyle doğrulanır. [Play Games başarımları](https://developer.android.com/games/pgs/achievements) · [Saved Games](https://developer.android.com/games/pgs/savedgames)
