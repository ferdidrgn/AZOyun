class MysteryEvidence {
  const MysteryEvidence(this.title, this.account);
  final String title;
  final String account;
}

class MysteryChapter {
  const MysteryChapter({
    required this.number,
    required this.title,
    required this.scenes,
    required this.evidence,
    required this.question,
    required this.answers,
    required this.solution,
    required this.reconstruction,
  });

  final int number;
  final String title;
  final List<String> scenes;
  final List<MysteryEvidence> evidence;
  final String question;
  final List<String> answers;
  final int solution;
  final String reconstruction;

  String get id => 'silt_defteri_$number';
}

const kMysteryChapters = [
  MysteryChapter(
    number: 1,
    title: 'Gece Postası',
    scenes: [
      'Sarnıç Garı’nda sabaha karşı deniz kokusu raylara kadar çıkardı. Arşivci Selim Işık, o kokudan hoşlanmadığını mektuplarında üç kez yazmıştı. Cesedi bulunduğunda paltosu kupkuru, botlarının bağlarına kadar tuz tutmuştu. Kondüktör, adamın gece postasına tek başına bindiğine yemin ediyordu. Selim’in bileğindeki saat 02.17’de durmuştu.',
      'Başkomiser Cem beni peronda buldu. On sekiz yıl önce kardeşim Ali’yi 6. İskele’deki taşkında kaybettiğimizde de ilk tutanağı o yazmıştı. Elindeki kâğıdı bana uzatmadı. “Kaza diye kapatmamı istiyorlar, Derya,” dedi. Selim’in cebindeki bilet koçanını açtım. Arka yüzünde bir tarih, bir depo numarası ve Ali’nin adı vardı.',
    ],
    evidence: [
      MysteryEvidence('Adli ön inceleme',
          'Akciğerlerde tuzlu su ve kırmızı boya pulları var. Vagon zemini kuru. Selim suya girdiğinde hayattaydı.'),
      MysteryEvidence('Kondüktörün ifadesi',
          '“Yüzünü görmedim. Şapkası gözlerine inmişti. Yanındaki hamal, hastalandığını söyledi.”'),
      MysteryEvidence('Vagonun kapısı',
          'Kapı altındaki temiz çarşaf, sedyenin teker izini örtüyor. Bilet delgeci 02.31’i gösteriyor.'),
    ],
    question: 'Tren, soruşturmanın neresinde duruyor?',
    answers: [
      'Selim vagonda boğuldu.',
      'Vagon, başka yerde işlenen cinayetin sahnesi olarak kullanıldı.',
      'Selim trenden hiç inmediği için boya kondüktöre ait.'
    ],
    solution: 1,
    reconstruction:
        'Selim önce tuzlu suda boğuldu. Bilet, ölüm saatinden sonra delinmişti. Kondüktör bir yolcu değil, örtülü bir beden görmüştü. Koçanın arkasındaki 24 numara bizi garın arkasındaki pompa deposuna götürdü.',
  ),
  MysteryChapter(
    number: 2,
    title: 'Kırmızı Tortu',
    scenes: [
      'Depo 24’ün kapısında babamın çalıştığı tersanenin amblemi vardı. Altında yeni bir tabela asılıydı: Meral Kıyı Vakfı. Anahtarı taşıyan Nermin Akın, yıllarca pompalara bakım yapmıştı. “Selim buraya gece değil, öğleden sonra geldi,” dedi. Bir şey söylemek için ağzını açtı, sonra duvardaki kameraya baktı.',
      'Bodrumda iki havuz bulduk. Birinde yağmur suyu birikmişti. Ötekinin kırmızı kapağı daha sabah boyanmış gibi parlaktı. Eldivenimin ucu kapağa değdiğinde, boyanın üstünde şeffaf bir katman kalktı. Biri kurumasını beklemeden izleri silmişti.',
    ],
    evidence: [
      MysteryEvidence('Havuz örnekleri',
          'Batı havuzu tatlı su. Doğu havuzu, gelgit vanasına bağlı ve Selim’in akciğerlerindeki boya pullarıyla aynı pigmenti taşıyor.'),
      MysteryEvidence('Vana kaydedicisi',
          'Doğu havuzunda 02.12–02.18 arasında olağan dışı debi var. 02.21’de kapak dışarıdan kilitlenmiş.'),
      MysteryEvidence('Nermin’in bakım defteri',
          'Kayıt silinmeden önce debi raporunu basmış. Çıktıda vananın yerinden değil, saat kulesindeki kumanda panosundan açıldığı görülüyor.'),
    ],
    question: 'Hangi bulgular Selim’in öldürüldüğü yeri birlikte gösteriyor?',
    answers: [
      'Doğu havuzunun su ve boyası, ayrıca ölüm saatindeki akış kaydı.',
      'Batı havuzunun suyu ve depo tabelası.',
      'Kondüktörün ifadesi ve Nermin’in anahtarı.'
    ],
    solution: 0,
    reconstruction:
        'Doğu havuzu, bedendeki iki izi de açıklıyordu. Debi ve dış kilit, suyun birinin müdahalesiyle yükseldiğini gösterdi. Nermin cebime saat kulesinin çizimini bıraktı. Çizimde birbirine bağlanmaması gereken iki hat işaretliydi.',
  ),
  MysteryChapter(
    number: 3,
    title: 'Saat Kulesinin Kör Dakikası',
    scenes: [
      'Saat kulesine merdivenden değil, çan halatının geçtiği dar boşluktan çıktık. Belediye restorasyonunda duvarı örmüşler, kabloyu bırakmışlardı. Tepede, Selim’in el yazısını taşıyan küçük bir kâğıt buldum: “Saatin kaç olduğuna bakma. Kimin saatine baktığını sor.”',
      'Vakıf avukatı Rauf Gencer aşağıda bizi bekliyordu. Müdürü İhsan Meral’in o gece gala salonunda olduğunu, kule kamerasında Nermin’in göründüğünü söyledi. Cem görüntüyü durdurdu. Nermin’in elindeki bisiklet lambası yanıp sönüyordu. Arkadaki tramvay ise çizelgede yazan saatte çoktan seferini bitirmiş olmalıydı.',
    ],
    evidence: [
      MysteryEvidence('Kule kaydı',
          'Nermin görüntüde 02.14’te geçiyor. Arkasından son tramvay geliyor ve hat numarası okunuyor.'),
      MysteryEvidence('Tramvay verisi',
          'Son tramvay kule önünden 01.56’da geçmiş. Konum kaydı, bağımsız hat sunucusundan alınmış.'),
      MysteryEvidence('Pano zaman çizelgesi',
          'Vanayı açan komut 02.12’de verilmiş. Bu pano kendi saatini kullanıyor. Komut, bir sonraki güne kadar kendini silmeyen M-04 donanım anahtarıyla imzalı.'),
    ],
    question: 'Kamera kaydı Nermin’i neden vanayı açan kişi olarak gösteremez?',
    answers: [
      'Nermin kuleyi hiç ziyaret etmedi.',
      'Tramvay arşiviyle vana panosu aynı cihazda tutuluyor.',
      'Kamera 18 dakika ileride. Görüntü, açma komutundan önce çekildi.'
    ],
    solution: 2,
    reconstruction:
        'Görüntü Nermin’i 01.56’da gösteriyordu. Asıl iz, kopyalanması zor M-04 anahtarıydı. Pano kablosunu duvar boyunca izleyince hattın vakıf galası için kiralanan misafirhaneye uzandığını gördük.',
  ),
  MysteryChapter(
    number: 4,
    title: 'Misafirhanede Bir Ses',
    scenes: [
      'Misafirhanenin pencereleri denize bakıyordu. O gece gala konuklarına ayrılmış 6 numaralı odada şömine yanmış, bir köşede projektör fanı duvar kâğıdını karartmıştı. Görevli Meryem, Selim’in bir ay önce kendisine ses kaydedici verdiğini söyledi. “Bana bir şey olursa, önce Derya’ya dinlet,” demiş.',
      'Kayıtta Selim, on sekiz yıl önceki taşkından söz ediyordu. “Tahliye listesinin iki kopyası var,” dedi. “Asıl emir, silt tabakası kurumuş eski işletme defterinde. Ben ona Silt Defteri diyorum.” Ardından kapı açıldı. İçeri giren kişinin yüzü yoktu ama kulaklıkta, müzikten daha yakında duran bir ses vardı: şöminenin kapanan demir kapağı.',
    ],
    evidence: [
      MysteryEvidence('Galadan canlı yayın',
          'İhsan 02.12’de ekranda. Çekim geniş salonda gibi görünüyor, fakat kahkaha ve alkış aynı biçimde 14 saniye sonra tekrarlanıyor.'),
      MysteryEvidence('Meryem’in ses kaydı',
          'Şömine kapağı sesinin hemen ardından İhsan’ın sesi duyuluyor. Selim, kaydın başında konumu ve tarihi yüksek sesle söylüyor. Bu kayıt cinayetten bir gün önce alınmış.'),
      MysteryEvidence('Projektör günlüğü',
          '6 numaralı odadaki oynatıcı 02.06’da bir video döngüsü başlatmış. Aynı cihazın ağ adresi gala yayınına kaynak olmuş.'),
    ],
    question: 'Gala yayınıyla ilgili neyi kanıtlayabiliyoruz?',
    answers: [
      'Yayın önceden kaydedilmiş; İhsan’ın o saatte salonda olduğunu kanıtlamıyor.',
      'Ses kaydı, İhsan’ın cinayet anında odada olduğunu kanıtlıyor.',
      'Gala salonundaki herkes işin içinde.'
    ],
    solution: 0,
    reconstruction:
        'İhsan’ın mazereti çöktü, ancak mazeretin sahte olması henüz katili belirlemiyordu. Selim’in sözünü ettiği tahliye listesinin ikinci kopyasını bulmak için misafirhanenin eski kiracısı olan gazeteci Leyla’yı aradım.',
  ),
  MysteryChapter(
    number: 5,
    title: 'Tahliye Listesi',
    scenes: [
      'Leyla matbaayı kapatmamış, yalnızca tabelasını indirmişti. Kurşun harf kasalarının arasında eski bir belediye bülteni uzattı. İlk sayfada kıyı taşkınından önce boşaltıldığı söylenen evler vardı. Sonraki sayfada vakfın o evleri kaç paraya satın aldığı yazıyordu. İki sayfanın arasında iki gün değil, iki saat vardı.',
      'İkinci listeyi önüme serdiğinde Ali’nin soyadı yoktu. Bir süre bunun yanlış liste olduğunu düşündüm. Leyla kâğıdı çevirdi. Arka yüzde bir çocuğun avucu kadar küçük bir el izi ve bir not vardı: “Ali’yi annesine götürmek istedim. Sokağa polis dizmişlerdi. Kuzey Feneri’ne götürdüm. — N.”',
    ],
    evidence: [
      MysteryEvidence('İmzalı tahliye kopyası',
          'On bir kişi planlı su bırakımından önce çıkarılmamış. Resmî nüshada aynı haneler boş gösterilmiş.'),
      MysteryEvidence('Kıyı ihale haritası',
          'Su basan parseller, taşkın planı onaylanmadan önce vakfın satın alma listesine alınmış.'),
      MysteryEvidence('Kuzey Feneri nöbet çizelgesi',
          'Nermin’in babası Nihat, taşkın gecesi 03.40’ta yaralı bir çocuğu içeri aldığını kaydetmiş. Çocuk için ad yazmamış.'),
    ],
    question: 'Belgelerin birlikte ortaya çıkardığı düzen ne?',
    answers: [
      'Vakıf, taşkından sonra tesadüfen boş arazileri satın aldı.',
      'İskelede kimsenin yaşamadığı kaydı doğruydu.',
      'Taşkın önceden planlandı ve boşaltılmayan evler kayıtlarda boş gösterildi.'
    ],
    solution: 2,
    reconstruction:
        'Selim cinayeti araştırırken aynı düzeni bulmuştu: vana, arazi alımı, sahte kayıt. Ali’nin öldüğünü gösteren bir belge yoktu. Kuzey Feneri’ne giden ilk minibüse bindim.',
  ),
  MysteryChapter(
    number: 6,
    title: 'Kuzey Feneri',
    scenes: [
      'Fenerin merceği yıllardır dönmüyordu. Yine de bekçi, her akşam onu temizliyordu. Mutfak duvarındaki çocuk fotoğraflarından birinde çizgili bir kazak gördüm. O kazağın kolunu annem örmüş, benimkinden bir sıra kısa bırakmıştı. Fotoğrafın altında “Arda, yeni okul günü” yazıyordu.',
      'Bekçi başka bir dosya çıkardı. Nihat çocuğu kurtardıktan sonra, Cem’in imzaladığı ölüm tutanağının bir kopyasını almış. Kıyıdaki diğer aileleri tehdit eden adamlardan çocuğu saklamak için onu ablasının yanına göndermiş. Ali’nin hayatta olmasını on sekiz yıl dilemiştim. Dileğim gerçekleşince ilk hissettiğim şey sevinç değil, bunca yılın ağırlığı oldu.',
    ],
    evidence: [
      MysteryEvidence('Fener fotoğrafı',
          'Çocuğun sol kulak altında yanık izi var. Ali’nin aile fotoğrafında aynı yerde iz görünüyor.'),
      MysteryEvidence('Hastane kaydı',
          'Nihat’ın teslim ettiği çocuk, eski kırık ve doğum işareti bakımından Ali’nin pediatri kaydıyla eşleşiyor. “Arda” adı daha sonraki okul naklinde kullanılmış.'),
      MysteryEvidence('Yakın tarihli mektup',
          'Arda, Nihat’ın sakladığı ses bandını duyduğunu yazmış. Selim’e doğrudan ulaşamayıp bandı tuz fabrikasının 9 numaralı dolabına koymuş.'),
    ],
    question: 'Ali konusunda hangi sonuca dayanarak ilerleyebiliriz?',
    answers: [
      'Yalnızca kazak fotoğrafına bakarak çocuğun kimliğini kesinleştirdik.',
      'Bağımsız hastane ve fener kayıtları, Ali’nin sağ kurtulan çocuk olduğunu destekliyor.',
      'Ölüm tutanağı varsa diğer kayıtların önemi yok.'
    ],
    solution: 1,
    reconstruction:
        'Ali hayatta kalmıştı. Kardeşimle görüşmeyi istemem onun beni görmeye hazır olduğu anlamına gelmiyordu. Önce mektubunda istediğini yaptım ve bandın peşine düştüm.',
  ),
  MysteryChapter(
    number: 7,
    title: 'Dokuz Numaralı Dolap',
    scenes: [
      'Tuz fabrikasında üretim durmuştu ama çatıdaki rüzgâr santrifüjleri çeviriyordu. Dokuz numaralı dolap açıktı. Rafın tozunda boş bir kasetin izi duruyordu. Bir alt rafta, suyu emmek için konmuş bezin altında bir fiş bulduk. Kaseti alan kişi aceleyle gitmişti.',
      'Cem fişe baktığında cebindeki telefonu susturdu. Arayan Leyla’ydı. “Rauf arşivden çıktı,” dedi. “Bana kayıp kasetle ilgili konuşmak istediğini söyledi. Kaseti çaldığını düşünmemi istiyor. Ama fişin tarihi ne?”',
    ],
    evidence: [
      MysteryEvidence('Aktarım fişi',
          'Selim, cinayetten üç gün önce özgün bandı bağımsız ses laboratuvarına teslim etmiş. Fişte makaraya işlenmiş seri numarası var.'),
      MysteryEvidence('Dolap görüntüsü',
          'Rauf, cinayetten sonraki sabah boş kaset kutusunu alıyor. Kameranın saati fabrika vardiya verisiyle uyuşuyor.'),
      MysteryEvidence('Laboratuvar tutanağı',
          'Özgün makaraya ait seri numarası fişle aynı. Mühür, teslimden beri açılmamış.'),
    ],
    question: 'Kanıt zincirini nasıl korursun?',
    answers: [
      'Rauf’un aldığı kutuyu özgün kayıt kabul ederim.',
      'Kaset boş olduğuna göre bandı hiç aramam.',
      'Fiş ve mühürlü laboratuvar tutanağıyla özgün makarayı resmî olarak teslim alırım.'
    ],
    solution: 2,
    reconstruction:
        'Kutunun çalınması izi kesmek içindi. Özgün bantta, eski taşkın emrini veren ses ve belediye telsizinin çağrı kodu vardı. Cem kaydı bitirmeden kulaklığını çıkardı. Kodu tanımıştı.',
  ),
  MysteryChapter(
    number: 8,
    title: 'Cem’in Tutanakları',
    scenes: [
      'Cem bütün gece istasyonun merdivenlerinde oturdu. Sabah bana eski telsizini getirdi. “Kıyı yolunu kapatmamı söylediler. Evler tahliye edildi dediler. Üç çocuğun adını ilk defa tutanağı imzalarken gördüm.” Arka cebinden bir zarf çıkardı. İmzasının yanında bir de başka imza vardı.',
      'Bana yardım etmek için değil, Selim’e borcunu kapatmak için konuştuğunu söyledi. Ondan hangisinin daha doğru olduğunu sormadım. Zarfın içindeki erişim kaydında M-04 anahtarının kime verildiği ve kim tarafından iade edildiği yazıyordu. İlk kez, bir kuşkuyu iki bağımsız kanıtla doğrulayabileceğimiz yere gelmiştik.',
    ],
    evidence: [
      MysteryEvidence('Telsiz çağrı defteri',
          'Taşkın gecesi duyulan 04 çağrı kodu, o gece mühendis İhsan Meral’e atanmış. Ses uzmanı bandın kesintisiz olduğunu raporlamış.'),
      MysteryEvidence('Donanım anahtarı zimmeti',
          'M-04 cinayet gecesi İhsan’a verilmiş. İade sabahı mühür sağlam. Anahtarın komut imzası pano kaydıyla aynı.'),
      MysteryEvidence('Rauf’un erişim kaydı',
          'Rauf galanın video döngüsünü hazırlamış. Cinayet saatinde liman turnikesinden geçmiş, fakat onun adına atanmış anahtar M-02.'),
    ],
    question:
        'Vana komutunu kimin verdiğine en doğrudan hangi kanıt işaret ediyor?',
    answers: [
      'Rauf’un gala videosunu düzenlemiş olması.',
      'Komutu imzalayan M-04 ile İhsan’ın zimmet kaydının eşleşmesi.',
      'Cem’in eski tutanağı imzalamış olması.'
    ],
    solution: 1,
    reconstruction:
        'Cem’in eski örtbası, Rauf’un sahte mazereti ve İhsan’ın komutu ayrı ayrı kayda geçti. Savcıya erişim kayıtlarını verdik. O sırada fenerdeki alıcıya yeni bir uyarı düştü: doğu havuzu, bir kez daha uzaktan açılmak üzereydi.',
  ),
  MysteryChapter(
    number: 9,
    title: 'İkinci Gelgit',
    scenes: [
      'Fırtına yükselirken alıcı iki kez öttü. Doğu havuzu açılırsa alt tünelden arşive su dolacak, 6. İskele’de hâlâ oturanların yolu kesilecekti. Nermin ana istasyondan vana panosuna bağlanmaya çalıştı. Ekranda “komut kuyruğa alındı” yazdı. Şebekeyi kesmek için elimi şaltere uzattım.',
      'Nermin bileğimi tuttu. “O kapağı elektrik kapalı tutuyor.” Yağmurun altında bana üç sayfalık bir bakım föyü uzattı. Her seçeneğin altında tek bir insanın yazabileceği kadar kısa bir not vardı. Babasının yazısıydı. Çizimde, bir zamanlar çocukların denize taş attığı basamaklardan geçen bir tahliye yolu görünüyordu.',
    ],
    evidence: [
      MysteryEvidence('Vana güvenlik föyü',
          'Ana şalter inerse kumanda düşer ve doğu vanası açık konuma geçer. Kuyruktaki komut, ağ kesilince silinmez.'),
      MysteryEvidence('Mekanik kilit çizimi',
          'Önce kuzey taşma hattı açılırsa basınç düşer. Bundan sonra doğu kapağının mekanik pimi kapanır.'),
      MysteryEvidence('İskele nöbetçisinin raporu',
          'Kuzey hattının çıkışı boş. Doğu tünelinde tahliye ekibi ve iki sivil var.'),
    ],
    question: 'İnsanları ve arşivi korumak için önce ne yaparsın?',
    answers: [
      'Kuzey taşma hattını açar, ardından doğu kapağını mekanik olarak kilitlerim.',
      'Ana şalteri indiririm.',
      'Ağ kablosunu kesip komutun silinmesini beklerim.'
    ],
    solution: 0,
    reconstruction:
        'Kuzey hattı açılınca basınç düştü. Nermin pimi yerine vurdu, ben tahliye ekibinin dışarı çıktığını telsizden duydum. Su yükselmedi. Savcı, arşivin alt rafında, kapağı taşkın tortusuyla sertleşmiş işletme defterini buldu. Selim, sayfa kıvrımına o geceki vana emrinin numarasını not etmişti. Artık elimizde emrin kendisi de vardı.',
  ),
  MysteryChapter(
    number: 10,
    title: 'Silt Defteri',
    scenes: [
      'Mahkeme salonuna Silt Defteri su geçirmez bir çantanın içinde getirildi. İhsan, avukatının omzunun üstünden deftere baktı. İlk taşkının emrindeki imza ona aitti. Kondüktör de o sabah yeniden ifade verdi. Depodan gelen hamalı tanımıştı. “Rauf bana hastaneye giden bir yolcu taşıdığımı söyledi,” dedi hamal. Savcı, o geceyi yeniden kurmak için üç delil grubunu masaya koydu.',
      'Arka sırada bir adam oturuyordu. Mahkeme görevlisinin kalemini yerden alıp uzattı. Bileğini uzatırken gömleğinin kolu sıyrıldı. Onu fotoğraftaki çocuk gibi hayal etmeyi bıraktım. Teneffüste yanına oturup adını sordum. “Arda,” dedi. Bir süre sonra ekledi: “Ali’yi de hatırlıyorum. Önce davayı bitirelim.”',
    ],
    evidence: [
      MysteryEvidence('Yer, zaman ve yöntem',
          'Doğu havuzunun tuzlu suyu ve boyası, Selim’in adli örnekleriyle eşleşti. Debi kaydı ölüm aralığını doğruladı. Tren bileti, cesedin sonra taşındığını gösterdi.'),
      MysteryEvidence('Komut ve sahte mazeret',
          'Pano komutu İhsan’ın M-04 anahtarına bağlı. Rauf kayıtlı gala yayınını hazırladı. Depo taşıma fişinde de onun imzası vardı; hamalın ifadesi fişle uyuştu.'),
      MysteryEvidence('Güdü ve saklanan geçmiş',
          'Tahliye listesi, ihale haritası ve özgün telsiz bandı vakfın ilk taşkından çıkar sağladığını gösteriyor. Selim üç belgeyi birlikte açıklamak üzereydi.'),
    ],
    question: 'Savcının hangi anlatımı bütün kanıtlarla ayakta kalır?',
    answers: [
      'Cem eski tutanağı imzaladı, bu yüzden cinayet emrini de onun verdiği kesin.',
      'Rauf sahte yayını hazırladı; bu, vanayı kendi açtığını kanıtlıyor.',
      'İhsan Selim’i susturmak için doğu vanasını açtı. Rauf, sahte mazeret ve delil gizleme yoluyla ona yardım etti.'
    ],
    solution: 2,
    reconstruction:
        'Mahkeme İhsan’ı Selim’in öldürülmesinden, Rauf’u delilleri gizlemekten mahkûm etti. Cem’in imzaladığı tutanak ayrı dosyaya alındı. İlk taşkında öldüğü kayda geçen ve kaybolan insanların adları, bu kez aileleriyle birlikte okundu. İsimlerin en altına Selim Işık eklendi. Onun bulduğu ikinci tahliye listesi, kıyı davalarının yeniden açılmasını sağladı.\n\nDuruşmadan sonra Arda’yla 6. İskele’ye yürüdük. Çocukken yaptığımız gibi üç düz taş topladı. Birini denize attı, ikincisini bana verdi. Üçüncüsünü cebine koydu. “Seneye de gelir miyiz?” dedi. “Seneye de,” dedim. Bu defa bir tutanak tutmadım.',
  ),
];
