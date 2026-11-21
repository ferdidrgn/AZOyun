# Oyun istemci matrisi

Bu dosya oyun başlıklarının benzerliğini, kural kodunun ortak olduğu anlamına getirmez. İstemciler arası eşitlik, ortak senaryolarla doğrulanana kadar açık kabul edilir.

## Motor ve ağ sınırları

| Kapsam | Android | Web | Kural/veri sınırı |
| --- | --- | --- | --- |
| 3D Arcade: `runway`, `drones`, `orbit`, `maze`, `bowling`, `freeKick`, `penalty` | Flutter ekran kabuğu içinde `assets/arcade3d` WebView | Statik HTML/CSS sayfası aynı `assets/arcade3d` motorunu iframe içinde çalıştırır | Görsel simülasyon ve tek oyunculu skor motorun içinde; oda sunucusuna bağlı değil |
| 30 benzersiz web klasiği ve 2 eski URL takma adı | Eşleşen oyunlarda ayrı Dart ekranı; bazı oyunların mobil karşılığı yok | `web/salon/classic-games.mjs` içindeki JavaScript | Eşleşen kurallar ayrı dillerde; XOX ortak vektör sözleşmesine alındı |
| Hızlı çok oyunculu oyunlar | `lib/core/quickplay` ve özellik ekranları; çevrimdışı/aynı cihaz | Web'de bazı eşdeğer tek kişilik veya yerel oyunlar var | Bu oyunlar için ortak çevrimiçi oda iddiası yok; UI/puan sözleşmesi ayrıca eşlenecek |
| Firebase çevrimiçi oyunları | `RoomService`, oyun özellikleri ve Firebase oda verisi | Aile masası arayüzü `web/salon/table.mjs`; oda API'si `family-server` | Oda sunucusunu tek doğruluk kaynağı tut; istemci yalnızca görünür oyun durumunu gösterir |

## Web klasiği → Flutter karşılığı

| Web anahtarı | Flutter kimliği / ekranı | Durum |
| --- | --- | --- |
| `xox` | `tictactoe` / `tic_tac_toe_screen.dart` | Aynı kural vektörleriyle denetleniyor |
| `dortlu` | `connect4` / `connect_four_screen.dart` | Yatay/dikey/çapraz kazanma çizgileri ve en alt boş hücre ortak senaryolara bağlandı |
| `nim` | `nim` / `nim_screen.dart` | Dört yığın, hamle sınırları ve son taş kazanımı ortak senaryolara bağlandı |
| `reversi` | `reversi` / `reversi_screen.dart` | Paralel kural kodu; hamle/geçiş durumları ayrıca eşlenecek |
| `noktalar` | `dotsboxes` / `dots_boxes_screen.dart` | Paralel kural kodu |
| `tkm` | `rps` / `rps_screen.dart` | Aynı oyun ailesi; tur/galibiyet sonucu eşlenecek |
| `zar` | `diceparty` / `dice_party_screen.dart` | Aynı oyun ailesi; zar ve puan kuralları karşılaştırılacak |
| `hafiza` | `memory` / `memory_match_screen.dart` | Aynı oyun ailesi; deste üretimi ve eşleşme kuralı karşılaştırılacak |
| `uclu` | `triplematch` / `triple_match_screen.dart` | Aynı oyun ailesi; eşleşme kuralı karşılaştırılacak |
| `2048` | `2048` / `game_2048_screen.dart` | Ortak JSON vektörleri kaydırma/birleşme, puan, no-op, bitiş ve 2048 hedefine ulaşmayı kapsıyor; Flutter ve web CI testleri eklendi |
| `yapboz` | `slidingpuzzle` / `sliding_puzzle_screen.dart` | Aynı oyun ailesi; karıştırma/çözüm durumu karşılaştırılacak |
| `sayi` | `count123` / `count_numbers_screen.dart` | Aynı oyun ailesi; sıra/puan karşılaştırılacak |
| `matematik` | `mathpuzzle` / `math_puzzle_screen.dart` | Aynı oyun ailesi; soru ve puan kaynağı karşılaştırılacak |
| `sayi-tahmin` | `bullscows` / `bulls_cows_screen.dart` | Aynı oyun ailesi; tahmin ipucu sözleşmesi karşılaştırılacak |
| `balon` | `balloonpop` / `balloon_pop_screen.dart` | 20 sn tur, 1,1 sn hedef ömrü, başarılı dokunuşa 1 puan ve bitiş kuralı ortak vektörlere bağlı |
| `yilan` | `snake` / `snake_screen.dart` | 14×14 tahta, başlangıç ve elma puanı eşit; dönüş, duvar/kuyruk çarpışması ve boşalan kuyruk hücresi ortak vektörlere bağlı |
| `oje` | `nailsalon` / `nail_salon_screen.dart` | Benzer tek kişilik deneyim; ortak kural sözleşmesi gerekmiyor |
| `ciz` | `drawsmash` / `draw_smash_screen.dart` | Benzer yerel parti deneyimi; çizim aktarımı ve süre eşlenecek |
| `maymun` | `monkeytap` / `monkey_touch_screen.dart` | 3×3 hedef, 700 ms hedef hareketi, 20 sn tur ve hedef isabetine 1 puan ortak vektörlere bağlı |
| `scuba` | `scubasweep` / `scuba_sweep_screen.dart` | Web’de 4×4 hedef tıklama, mobilde kaydırmalı dalış sahnesi var; aynı oyun olacak şekilde web sahnesi henüz taşınmadı |
| `zipla` | `jumpdash` / `jump_dash_screen.dart` | Borulu uçuş web’de de kuruldu; yerçekimi, zıplama, boru akışı, puan ve çarpışma ortak vektörlerde |
| `kaplan` | `tigerrun` / `tiger_run_screen.dart` | Aynı tür; engel/toplama vektörleri karşılaştırılacak |
| `serit` | `lanerace` / `lane_race_screen.dart` | Aynı tür; şerit/çarpışma vektörleri karşılaştırılacak |
| `bovling` | `minibowling` / `mini_bowling_screen.dart` | Benzer başlık; iki oyunun nişan ve skor kuralları aynı kabul edilmiyor |
| `futbol` | `football_quiz_screen.dart` | Başlık benzerliği dışında eşdeğerlik doğrulanmadı |
| `asmaca`, `sehir`, `kelime`, `bilgi`, `refleks` | Yakın adlı Dart/çevrimiçi modlar olabilir | Kural eşdeğerliği doğrulanmadı; eşleştirme otomatik yapılmamalı |

Eski `penalti` ve `frikik` URL'leri artık eski seçim/quiz simülasyonlarını çalıştırmıyor; canonical 3D oyun sayfalarına bağlantı veriyor. Ana katalogda çift başlık görünmüyor.

## Flutter'da olup web kataloğunda karşılığı olmayanlar

Hızlı oyun kimlikleri arasında satranç, karambol, renk hafızası, Hedef Atışı, Denge Hattı, çocuk partisi oyunları, Hıçkırık Kulesi, Geri Sar Çorba, Saçtaki Yaprak, Tek Terlik ve Dedektif Dosyaları bulunuyor. Bunlar ancak web'e aynı oyun gerçekten uygulanınca eşdeğer sayılacak.

## Çevrimiçi oyunlar

Flutter çevrimiçi kimlikleri `racing`, `impostor`, `golf`, `word`, `dama`, `okey`, `fighter`, `hangman`, `city`, `vampire`, `liar`, `soccer`. Bunların oda hamleleri QuickPlay ile karıştırılmamalı. Web Aile Masası API'si yalnızca server tarafında desteklenen masa türlerini kullanır; her çevrimiçi Dart oyununun tarayıcı istemcisi varmış gibi kabul edilmemelidir.

## Sonraki eşitleme sırası

1. XOX ortak kural vektörlerini Flutter ve web'de çalıştır.
2. Dörtlü Diz ve Nim için sıra/hamle/bitiş vektörlerini ekle.
3. 2048, yılan ve mini oyunlarda üretim kuralı ile skor/result sözleşmesini karşılaştır.
4. Ortak Firebase oyunlarında oda revizyonu, tekrar bağlanma ve sonuç durumlarını Android/web arasında temsilî senaryolarla doğrula.

