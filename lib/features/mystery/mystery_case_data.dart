// ═══════════════════════════════════════════════════════════════════════════
// DEDEKTİF KAMPANYASI — birbirine bağlı vakalar zinciri
//
// Tek oyunculu, polisiye/iz sürme temalı hikaye oyunu. Her vaka kendi
// başına çözülebilir bir cinayet/olay içerir, ama hepsinin arka planında
// aynı iz var: bir mühür — daire içinde stilize bir göz — ve "V.K." baş
// harfleri. Vaka 1-3'te bu sadece arka plan detayı gibi görünür. Büyük
// finalde ("Çember") hepsi birleşir.
// ═══════════════════════════════════════════════════════════════════════════

class MysteryClue {
  const MysteryClue({
    required this.id,
    required this.emoji,
    required this.title,
    required this.description,
  });

  final String id, emoji, title, description;
}

class MysteryQA {
  const MysteryQA(this.question, this.answer);
  final String question, answer;
}

class MysterySuspect {
  const MysterySuspect({
    required this.id,
    required this.name,
    required this.role,
    required this.emoji,
    required this.flavor,
    required this.questions,
  });

  final String id, name, role, emoji, flavor;
  final List<MysteryQA> questions;
}

class MysteryEnding {
  const MysteryEnding({required this.title, required this.body});
  final String title, body;
}

/// Bir kampanya vakasının tamamı: giriş metni, kanıtlar, şüpheliler, gerçek
/// suçlu ve her suçlama seçeneği için ayrı bir final metni.
class MysteryCase {
  const MysteryCase({
    required this.id,
    required this.number,
    required this.title,
    required this.subtitle,
    required this.emoji,
    required this.durationLabel,
    required this.introPages,
    required this.clues,
    required this.suspects,
    required this.culpritId,
    required this.endings,
    this.isFinale = false,
  });

  final String id;
  final int number;
  final String title, subtitle, emoji, durationLabel;
  final List<String> introPages;
  final List<MysteryClue> clues;
  final List<MysterySuspect> suspects;
  final String culpritId;
  final Map<String, MysteryEnding> endings;
  final bool isFinale;
}

// ═══════════════════════════════════════════════════════════════════════════
// VAKA 1 — GECE EKSPRESİ CİNAYETİ
// ═══════════════════════════════════════════════════════════════════════════

const kCase1 = MysteryCase(
  id: 'night_express',
  number: 1,
  title: 'Gece Ekspresi Cinayeti',
  subtitle: 'İstanbul-Ankara treninde esrarengiz bir ölüm',
  emoji: '🚂',
  durationLabel: '~10 dk',
  introPages: [
    'İstanbul-Ankara gece ekspresi, saat 23.50. Dışarıda yağmur camlara '
        'vuruyor, kompartımanların çoğu karanlık.\n\n'
        'Birinci sınıf vagonunun sonundaki kompartımandan bir çığlık yükseliyor.',
    'Ünlü kuyumcu Kaya Aydemir, kendi kompartımanında hareketsiz yatıyor. '
        'Masasındaki şarap kadehi kırık, kadife kolye kutusu ise bomboş.\n\n'
        'Tren bir sonraki istasyona varana kadar 40 dakika var. Ve sen, o '
        'trendeki tek dedektifsin.',
    'Dört kişi bu olayla bir şekilde bağlantılı: eşi, iş ortağı, vagon '
        'görevlisi ve tesadüfen olay yerinde bulunan bir doktor.\n\n'
        'Zaman daralıyor. Kanıtları topla, şüphelileri sorguya çek — ve '
        'gerçek katili bul. Ama dikkat et: en olası şüpheli her zaman suçlu '
        'olan değildir.',
  ],
  clues: [
    MysteryClue(
      id: 'glass',
      emoji: '🍷',
      title: 'Kırık Şarap Kadehi',
      description:
          'Kadehin dibinde beyaz, tuz gibi bir toz kalıntısı var. Koklayınca '
          'hafif acı bademe benzer bir koku geliyor. Zehir olabilir mi?',
    ),
    MysteryClue(
      id: 'letter',
      emoji: '✉️',
      title: 'Yırtık Mektup',
      description:
          '"...seni asla affetmeyeceğim, bu paranın hesabını bir gün '
          'mutlaka ödeyeceksin..." Mektubun geri kalanı yok, imza da yok. '
          'Kime, kimden yazılmış?',
    ),
    MysteryClue(
      id: 'window',
      emoji: '🪟',
      title: 'Açık Pencere',
      description:
          'Kompartımanın penceresi ardına kadar açık, soğuk gece rüzgarı '
          'içeri doluyor. Ama tren tam hızla giderken pencereden girmek '
          'neredeyse imkansız — biri dikkatini başka yöne çekmek mi istedi?',
    ),
    MysteryClue(
      id: 'button',
      emoji: '🔘',
      title: 'Kopuk Düğme',
      description:
          'Yerde, kurbanın ayakkabısının altında ezilmiş bir üniforma '
          'düğmesi var. Trendeki görevli üniformalarındaki düğmelerle aynı '
          'desende.',
    ),
    MysteryClue(
      id: 'necklace',
      emoji: '📦',
      title: 'Boş Kolye Kutusu',
      description:
          'Kadife kutunun içi bomboş. Kilit zorlanmamış, kırılmamış — sanki '
          'kurban kutuyu kendi eliyle, güvendiği birine açmış gibi.',
    ),
    MysteryClue(
      id: 'ledger',
      emoji: '📄',
      title: 'Hesap Defteri Sayfası',
      description:
          'Kurbanın ceketinin iç cebinde, dükkânın hesap defterinden '
          'koparılmış bir sayfa. Kırmızı kalemle daire içine alınmış bir '
          'açık: 47.500 TL. Kenara küçük harflerle "S.B. ile konuş" yazılmış. '
          'Sayfanın köşesinde, mürekkeple çizilmiş küçük, tuhaf bir simge '
          'var: daire içinde tek bir göz.',
    ),
  ],
  suspects: [
    MysterySuspect(
      id: 'elif',
      name: 'Elif Aydemir',
      role: 'Kurbanın Eşi',
      emoji: '👩',
      flavor: 'Gözleri kızarmış, ama elleri hiç titremiyor. Sakinliği mi, '
          'yoksa alışkınlığı mı?',
      questions: [
        MysteryQA(
          'Kocanızla aranız son zamanlarda nasıldı?',
          'Zor bir dönemdeydik, evet. Ama "zor" ile "cinayet" arasında büyük '
              'fark var dedektif. Onu hâlâ seviyordum.',
        ),
        MysteryQA(
          'O gece nerede olduğunuzu söyler misiniz?',
          'Kendi kompartımanımdaydım, uyumaya çalışıyordum. Yalnızdım, kimse '
              'doğrulayamaz — biliyorum, kulağa kötü geliyor.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'serkan',
      name: 'Serkan Bulut',
      role: 'İş Ortağı',
      emoji: '🕴️',
      flavor: 'Gülümsemesi bir an bile bozulmuyor. Tam bir profesyonel — ya '
          'da tam bir aktör.',
      questions: [
        MysteryQA(
          'Dükkânla ilgili son zamanlarda bir sorun var mıydı?',
          'Hayır, hayır, her şey yolundaydı. Kaya ile aramızda hiçbir pürüz '
              'yoktu, inanın.',
        ),
        MysteryQA(
          'O gece nerede olduğunuzu söyler misiniz?',
          'Vagon restorandaydım, bir kadeh bir şeyler içtim. Garson beni '
              'görmüştür... sanırım.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'nurcan',
      name: 'Nurcan Ete',
      role: 'Vagon Görevlisi',
      emoji: '👩‍✈️',
      flavor: 'Otuz yıllık tren görevlisi. Yorgun gözlerinde, anlatmadığı '
          'çok şey olduğu belli.',
      questions: [
        MysteryQA(
          'Kurbanı daha önce tanıyor muydunuz?',
          'Bu hat üzerinde onlarca kez yolculuk etti, tabii ki tanıyordum. '
              'Nazik bir adamdı çoğu zaman.',
        ),
        MysteryQA(
          'Üniformanızda eksik bir düğme var, fark ettiniz mi?',
          'Ne? ...Evet, galiba kapıyı kontrol ederken bir yere takıldı. '
              'Önemli bir şey değil.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'halil',
      name: 'Dr. Halil Soykan',
      role: 'Tesadüfi Yolcu',
      emoji: '🩺',
      flavor: 'Elleri hâlâ hafif titriyor. İlk yardım sahnesinin şoku mu, '
          'yoksa başka bir şey mi?',
      questions: [
        MysteryQA(
          'Olay yerinde neden bulundunuz?',
          'Bir çığlık duydum, koşarak geldim. Nabzına baktım ama... çok '
              'geçti.',
        ),
        MysteryQA(
          'Çantanızdaki şişe nedir?',
          'Kalp ilacım. Kronik ritim bozukluğum var, yanımdan hiç ayırmam. '
              'İsterseniz reçetemi gösterebilirim.',
        ),
      ],
    ),
  ],
  culpritId: 'serkan',
  endings: {
    'serkan': MysteryEnding(
      title: '🎯 Doğru Dedektif!',
      body:
          'Hesap defterindeki o sayfa her şeyi ele veriyordu: Serkan Bulut, '
          'ortaklık parasından 47.500 TL zimmetine geçirmiş ve Kaya bunu '
          'öğrenmişti. O gece "barışma kadehi" bahanesiyle Kaya\'nın '
          'kompartımanına girdi, şarabına sessiz bir zehir kattı.\n\n'
          'Kolyeyi çalması sahte bir hırsızlık süsü vermek içindi — ne '
          'yazık ki panik içinde kutuyu açarken izlerini tam da aradığınız '
          'o sayfada bıraktı. Kondüktörün düğmesi habersiz bir tesadüftü: '
          'Nurcan, saatler önce farklı bir yolcuyla küçük bir tartışma '
          'yaşamış, düğmesi orada düşmüştü. Dr. Halil\'in tek suçu, meraklı '
          've biraz sakar bir kalp doktoru olmaktı.\n\n'
          'Ama bir şey seni rahatsız ediyor: sayfanın köşesindeki o küçük '
          'göz simgesi. Serkan\'ın parayı nereye harcadığını hiç sormadın. '
          'Vaka kapandı, dedektif — ama sanki her şey kapanmadı.',
    ),
    'elif': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Elif\'i suçladınız ama itiraf hiç gelmedi — çünkü suçlu o '
          'değildi. Mektup gerçekten ona aitti, evet, ama sadece bir öfke '
          'anının kâğıda dökülmüş haliydi, hiçbir zaman gönderilmemişti '
          'bile.\n\n'
          'Gerçek katil, ortaklık parasını zimmetine geçirdiğini gizlemeye '
          'çalışan Serkan Bulut\'tu — ve siz onu fark edemeden trenden '
          'güvenle indi. Belki bir dahaki vakada, o hesap defteri '
          'sayfasındaki küçük notu ("S.B. ile konuş") gözden kaçırmazsın.',
    ),
    'nurcan': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Nurcan\'ı suçladınız ama elinizde gerçek bir kanıt yoktu — '
          'sadece bir düğme ve bir önseziniz vardı. Düğme, kurbanla saatler '
          'önce yaşadığı küçük, alakasız bir tartışmadan kalmıştı.\n\n'
          'Gerçek katil, zimmetini örtbas etmeye çalışan iş ortağı Serkan '
          'Bulut\'tu. Nurcan şimdi, haksız yere suçlandığı için size hiç '
          'güvenmiyor.',
    ),
    'halil': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Dr. Halil\'i suçladınız ama onun tek "suçu" meraklı bir doktor '
          'olmaktı — olay yerine ilk gelen kişi olarak birkaç izi bilmeden '
          'bozmuştu, hepsi bu.\n\n'
          'Gerçek katil, zimmetini örtbas etmeye çalışan iş ortağı Serkan '
          'Bulut\'tu, ve siz onu asla yakalayamadınız.',
    ),
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// VAKA 2 — GALERİ SİRİUS'TAKİ SAHTEKÂRLIK
// ═══════════════════════════════════════════════════════════════════════════

const kCase2 = MysteryCase(
  id: 'sirius_gallery',
  number: 2,
  title: "Galeri Sirius'taki Sahtekârlık",
  subtitle: 'Büyük müzayededen bir gece önce, restoratör ölü bulundu',
  emoji: '🖼️',
  durationLabel: '~10 dk',
  introPages: [
    'Nişantaşı, Galeri Sirius. Yarın gece, on yıllardır kayıp sanılan bir '
        'Osmanlı dönemi tablosu tarihinin en yüksek müzayede rekorunu '
        'kırmaya hazırlanıyor.\n\n'
        'Ama bu sabah, galerinin baş restoratörü Yasemin Ergin, depo '
        'katındaki merdivenin dibinde hareketsiz bulundu.',
    'İlk bakışta bir kaza gibi duruyor: merdivenden düşme. Ama Yasemin on '
        'yıldır bu merdivenlere çıkıyordu, gözü kapalı bile güvenle inip '
        'çıkardı.\n\n'
        'Ve tablonun asıl önemi de burada: Yasemin, ölmeden bir gün önce '
        'yönetime "sertifikayı henüz imzalamadığını" söylemişti.',
    'Galeri sahibi, rakip bir eksper, kendi kız kardeşi ve galerinin '
        'güvenlik şefi — dördü de o gece binadaydı.\n\n'
        'Müzayedeye 30 saat kaldı. Eğer tablo sahteyse, milyonlarca lira '
        'el değiştirecek — ve gerçek katil kalabalığın arasında '
        'kaybolacak. Vakit daralıyor, dedektif.',
  ],
  clues: [
    MysteryClue(
      id: 'brush',
      emoji: '🖌️',
      title: 'Kırık İnce Fırça',
      description:
          'Yasemin\'in en hassas restorasyon fırçası ikiye kırılmış halde '
          'yerde. Ama kırık yüzey temiz ve düz — düşerken değil, bilinçli '
          'bir şekilde kırılmışa benziyor.',
    ),
    MysteryClue(
      id: 'certificate',
      emoji: '📜',
      title: 'Sahte Sertifika Taslağı',
      description:
          'Çekmecede, üzerinde defalarca pratik yapılmış iki farklı imza '
          'bulunan bir "özgünlük sertifikası" taslağı var. Biri Yasemin\'in '
          'imzası, diğeri hiç tanımadığın bir eksperin.',
    ),
    MysteryClue(
      id: 'key',
      emoji: '🔑',
      title: 'Kayıp Anahtar',
      description:
          'Depo katının ana anahtarı, olması gerekmeyen bir çalışanın '
          'mont cebinde bulundu. "Unutmuşum, hep üzerimde kalıyor" diyor '
          'ama sesi pek emin değil.',
    ),
    MysteryClue(
      id: 'envelope',
      emoji: '🕯️',
      title: 'Mühürlü Zarf',
      description:
          'Şöminede yarı yanmış bir zarf: kırmızı balmumu mührün üzerinde '
          'daire içinde tek bir göz simgesi var. İçindeki kâğıtta '
          'okunabilen tek şey: "...son uyarı, Y.E. Sessiz kal."',
    ),
    MysteryClue(
      id: 'photo',
      emoji: '📸',
      title: 'Bulanık Fotoğraf',
      description:
          'Yasemin\'in telefonunda, ölümünden saatler önce çekilmiş '
          'bulanık bir fotoğraf: depo katında, orada olmaması gereken '
          'birinin silueti.',
    ),
    MysteryClue(
      id: 'gloves',
      emoji: '🧤',
      title: 'Tozlu Eldiven',
      description:
          'Pahalı, beyaz pamuklu restoratör eldivenleri — ama Yasemin\'in '
          'kendi paletinde hiç kullanmadığı, mavimsi bir boya lekesi var '
          'üzerlerinde.',
    ),
  ],
  suspects: [
    MysterySuspect(
      id: 'kaan',
      name: 'Kaan Sezer',
      role: 'Galeri Sahibi',
      emoji: '🎩',
      flavor: 'Gülümsemesi müşteriler için, ama gözleri sürekli saate '
          'kayıyor. Galeri son iki yıldır zarar ediyor.',
      questions: [
        MysteryQA(
          'Müzayede gerçekleşmezse galeriye ne olur?',
          'Dürüst olmam gerekirse... batarız. Ama bu, birini öldürmem '
              'için sebep değil, dedektif.',
        ),
        MysteryQA(
          'Yasemin sertifikayı imzalamayı reddetseydi ne olurdu?',
          'Bir yolunu bulurduk. Başka bir eksper çağırırdık. Onu '
              'öldürmeme hiç gerek yoktu.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'deniz',
      name: 'Deniz Aksu',
      role: 'Rakip Eksper',
      emoji: '🧑‍🎨',
      flavor: 'Kibar, ölçülü konuşuyor — ama Yasemin\'in adı geçtiğinde '
          'çenesi bir an kilitleniyor.',
      questions: [
        MysteryQA(
          'Yasemin ile aranız nasıldı?',
          'Meslektaştık. Bazen rekabet ettik, evet, sanat dünyası '
              'böyledir. Ama saygı duyardım ona.',
        ),
        MysteryQA(
          'O gece galeride neden bulunuyordunuz?',
          'Tabloyu son kez incelemek istedim, müzayede öncesi standart '
              'bir nezaket ziyaretiydi.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'melis',
      name: 'Melis Ergin',
      role: 'Yardımcı Restoratör, Kız Kardeşi',
      emoji: '👩‍🔬',
      flavor: 'Gözleri şişmiş, ama sürekli ablasının çekmecesine bakıp '
          'duruyor. Bir şey mi arıyor?',
      questions: [
        MysteryQA(
          'Ablanızla ilişkiniz nasıldı?',
          'Hep onun gölgesindeydim. "Küçük Ergin" derlerdi bana. Ama onu '
              'kaybetmek... hayır, bunu ben yapmadım.',
        ),
        MysteryQA(
          'Çekmecesinde ne arıyordunuz?',
          'Kendi çizimlerimi. Bazılarını ona göstermeden satmıştım, '
              'utanç verici ama suç değil.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'orhan',
      name: 'Orhan Tekin',
      role: 'Güvenlik Şefi',
      emoji: '🛡️',
      flavor: 'Az konuşuyor, çok gözlemliyor. Yıllardır bu binanın her '
          'köşesini biliyor.',
      questions: [
        MysteryQA(
          'Kamera kayıtlarında neden boşluk var?',
          'Sistem bakımdaydı, planlıydı — kağıtları gösterebilirim. Kötü '
              'bir zamanlama, itiraf ediyorum.',
        ),
        MysteryQA(
          'O gece kimi gördünüz?',
          'Herkesi. Ama en son, Deniz Bey\'in depo katından çıktığını '
              'gördüm — geç saatte, tek başına.',
        ),
      ],
    ),
  ],
  culpritId: 'deniz',
  endings: {
    'deniz': MysteryEnding(
      title: '🎯 Doğru Dedektif!',
      body:
          'Deniz Aksu, o "kayıp başyapıtı" yıllar önce kendisi sipariş '
          'etmiş bir sahtekârdı — ve şimdi onu gerçek bir müzayedeye '
          'sokarak temize çıkarmaya çalışıyordu. Yasemin, restorasyon '
          'sırasında boyanın kimyasını fark etti: tablo, iddia edilen '
          'yaştan çok daha yeniydi.\n\n'
          'Deniz onu susturmaya çalıştı — önce o mühürlü zarfla tehdit '
          'etti, işe yaramayınca depo katında yüzleşti ve merdivenden itti. '
          'Kırık fırça, mücadelenin izi; mavi boya lekeli eldivenler ise '
          'Deniz\'in kendi restorasyon setinden kalmaydı.\n\n'
          'Ama o mühür — daire içindeki göz — yine karşına çıktı. Deniz '
          'kimin adına çalışıyordu? Zarftaki "V.K." harfleri kimin?'
          ' Bu iz, Gece Ekspresi\'ndeki o sayfadaki simgeyle aynı.',
    ),
    'kaan': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Kaan\'ı suçladınız ama onun tek suçu kötü bir iş adamı olmaktı, '
          'katil değildi. Gerçek suçlu, sahte tabloyu piyasaya sürmeye '
          'çalışan rakip eksper Deniz Aksu\'ydu — ve şimdi tablo, sahte '
          'sertifikasıyla bir başka müzayedede satılmayı bekliyor.',
    ),
    'melis': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Melis\'i suçladınız ama o sadece kendi küçük sırrını saklamaya '
          'çalışan, kırgın bir kız kardeşti. Gerçek katil, tabloyu sahte '
          'olarak sertifikalandırmaya çalışan Deniz Aksu\'ydu — ve o '
          'gece galeriden kimse fark etmeden çıktı.',
    ),
    'orhan': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Orhan\'ı suçladınız ama o sadece işini yapan, sadık bir '
          'güvenlik şefiydi. Gerçek katil Deniz Aksu\'ydu — kamera '
          'boşluğunu fark etmiş ve kendi izini örtmüştü. Şimdi '
          'özgürce dolaşıyor.',
    ),
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// VAKA 3 — BORSA KULESİ'NDE ÖLÜM
// ═══════════════════════════════════════════════════════════════════════════

const kCase3 = MysteryCase(
  id: 'bourse_tower',
  number: 3,
  title: "Borsa Kulesi'nde Ölüm",
  subtitle: 'Bir fintech CFO\'su, kilitli ofisinde ölü bulundu',
  emoji: '🏙️',
  durationLabel: '~10 dk',
  introPages: [
    'Zirve Kulesi, 42. kat. Hızla büyüyen fintech şirketi NovaPay\'in mali '
        'işler direktörü Tarık Emiroğlu, gece geç saatte kendi ofisinde '
        'ölü bulundu.\n\n'
        'Masasında bir "istifa/itiraf" notu, yanında boş bir ilaç şişesi. '
        'Görünüşe göre intihar. Ama sen ilk bakışta bir şey fark ettin: '
        'masada su bardağı yok.',
    'Kapının akıllı kilit kaydı, ölüm saatinden üç dakika SONRA, dışarıdan '
        'kilitlendiğini gösteriyor. Bu, bir intihar değil.\n\n'
        'Tarık\'ın az önce yönetim kuruluna göndermek üzere hazırladığı '
        'bir e-posta taslağı var: büyük bir mali usulsüzlüğü ihbar '
        'ediyordu. Gönderilmeden kalmış.',
    'Eşi, şirketin CEO\'su, meraklı bir gazeteci, sadık şoförü — dördü de '
        'o gece kulede ya da yakınındaydı.\n\n'
        'NovaPay\'in halka arzına üç gün kaldı. Eğer gerçek ortaya '
        'çıkmazsa, binlerce yatırımcı bilmeden büyük bir yalana para '
        'yatıracak. Zaman daralıyor, dedektif.',
  ],
  clues: [
    MysteryClue(
      id: 'pillbottle',
      emoji: '💊',
      title: 'Boş İlaç Şişesi',
      description:
          'Masada boş bir ilaç şişesi var ama hiçbir yerde su bardağı, '
          'kahve fincanı ya da başka bir sıvı yok. Bu kadar hapı kuru '
          'yutmak neredeyse imkansız.',
    ),
    MysteryClue(
      id: 'note',
      emoji: '💻',
      title: 'Sahte İtiraf Notu',
      description:
          'Laptop ekranındaki "istifa" notu tuhaf derecede kısa ve '
          'resmî — Tarık\'ın her zamanki sıcak, ayrıntılı yazım tarzına '
          'hiç benzemiyor.',
    ),
    MysteryClue(
      id: 'lock',
      emoji: '🔐',
      title: 'Kilit Kaydı',
      description:
          'Akıllı kapı kilidinin dijital kaydı: saat 23.47\'de, tahmini '
          'ölüm saatinden 3 dakika sonra, kapı DIŞARIDAN kilitlenmiş. '
          'Ölü bir adam kendi kapısını kilitleyemez.',
    ),
    MysteryClue(
      id: 'spreadsheet',
      emoji: '📈',
      title: 'Silinmiş Hesap Tablosu',
      description:
          'Kurtarılan bir dosyada, paravan bir şirkete yapılan büyük, '
          'gizli bir fon transferi var. Şirketin belgelerinin köşesinde, '
          'filigran gibi, daire içinde bir göz simgesi görünüyor.',
    ),
    MysteryClue(
      id: 'parking',
      emoji: '🎫',
      title: 'Otopark Bileti',
      description:
          'O gece geçerli bir otopark bileti, NovaPay çalışanlarından '
          'hiçbirine kayıtlı olmayan bir araca ait.',
    ),
    MysteryClue(
      id: 'call',
      emoji: '☎️',
      title: 'Son Arama Kaydı',
      description:
          'Tarık\'ın telefonundaki son arama, ölümünden 40 dakika önce, '
          'kayıtlı olmayan bir numaraya. Numara sonradan tek kullanımlık '
          'bir hatta ait çıkıyor.',
    ),
  ],
  suspects: [
    MysterySuspect(
      id: 'aylin',
      name: 'Aylin Emiroğlu',
      role: 'Eşi',
      emoji: '👰',
      flavor: 'Gözyaşları içinde ama sorularına net, düşünülmüş cevaplar '
          'veriyor. Büyük bir hayat sigortası poliçesi var.',
      questions: [
        MysteryQA(
          'Kocanızın hayat sigortasından haberiniz var mıydı?',
          'Tabii ki vardı, birlikte imzaladık. Ama parayı istemek için '
              'onu kaybetmeyi asla göze almam.',
        ),
        MysteryQA(
          'O gece nerede olduğunuzu söyler misiniz?',
          'Evdeydim, çocuklarla. Komşumuz beni bahçede gördü, sorabilirsin.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'baris',
      name: 'Barış Koral',
      role: 'NovaPay CEO\'su, Kurucu Ortak',
      emoji: '👔',
      flavor: 'Kamerada her zaman gülümseyen, karizmatik bir CEO. Ama '
          'gözlerinde bir hesap kitap var.',
      questions: [
        MysteryQA(
          'Tarık\'ın ihbar taslağından haberiniz var mıydı?',
          'Hayır, hiçbir fikrim yoktu. Tarık\'la her konuda açık '
              'konuşurduk, bunu bana neden söylemesin ki?',
        ),
        MysteryQA(
          'O gece ofiste miydiniz?',
          'Erken çıktım, evdeydim. Güvenlik kayıtları teyit eder — '
              'umarım.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'ece',
      name: 'Ece Duran',
      role: 'Araştırmacı Gazeteci',
      emoji: '📰',
      flavor: 'Aylardır NovaPay\'in hesaplarını kurcalıyor. Kuleye o gece '
          'girdiği güvenlik kamerasında görünüyor.',
      questions: [
        MysteryQA(
          'O gece kuleye neden girdiniz?',
          'Tarık beni aramıştı, konuşmak istiyordu. Bir kaynaktan bilgi '
              'alacaktım — ama asla oraya varamadım, resepsiyonda '
              'bekletildim.',
        ),
        MysteryQA(
          'Neden şüpheli görünüyorsunuz?',
          'Çünkü gazeteciyim ve gerçeği arıyorum — bu suç değil, '
              'dedektif. Suçluyu bulmama yardım edebilirim.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'bora',
      name: 'Bora Yalçın',
      role: 'Kişisel Şoför',
      emoji: '🕶️',
      flavor: 'Sessiz, dikkatli, sadık görünüyor. Ama kumar borçları '
          'olduğu söyleniyor.',
      questions: [
        MysteryQA(
          'O gece Tarık Bey\'i nereye götürdünüz?',
          'Sadece kuleye bıraktım, sonra beklememi söylemedi. Ben de '
              'ayrıldım.',
        ),
        MysteryQA(
          'Kumar borçlarınız doğru mu?',
          'Doğru... ama biri bana yardım etti, borcumu kapattı. Kimden '
              'bahsettiğimi söylemem gerekmiyor sanırım.',
        ),
      ],
    ),
  ],
  culpritId: 'baris',
  endings: {
    'baris': MysteryEnding(
      title: '🎯 Doğru Dedektif!',
      body:
          'Barış Koral, NovaPay\'in parasını yıllardır gizli bir paravan '
          'şirkete akıtıyordu — karşılığında şirketinin inanılmaz hızlı '
          'büyümesi için "arka kapı" destek alıyordu. Tarık, hesapları '
          'kurcalarken gerçeği buldu ve yönetim kuruluna gitmeye '
          'hazırlanıyordu.\n\n'
          'Barış o gece "konuşmak" bahanesiyle ofise geldi, Tarık\'ın '
          'kahvesine sessiz bir ilaç kattı, sahte itiraf notunu onun '
          'kendi laptopunda yazdı (şifresini biliyordu) ve çıkarken '
          'kapıyı kendi yönetici yetkisiyle dışarıdan kilitledi. Şoförü '
          'Bora\'nın borcunu ödeyen de oydu — sessiz kalması için.\n\n'
          'Paravan şirketin belgelerindeki o filigran: daire içinde bir '
          'göz. Aynı mühür, aynı harfler: V.K. Bu artık bir tesadüf '
          'olamaz.',
    ),
    'aylin': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Aylin\'i suçladınız ama sigorta parası bir motiften ibaretti, '
          'kanıt değildi. Gerçek katil, şirketin gizli fon transferlerini '
          'örtbas etmeye çalışan CEO Barış Koral\'dı — ve şimdi halka arz '
          'planlandığı gibi devam ediyor.',
    ),
    'ece': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Ece\'yi suçladınız ama o sadece gerçeği arayan bir gazeteciydi '
          '— resepsiyonda bekletilmesi bile aslında onu olay yerinden '
          'uzak tutmak için ayarlanmıştı. Gerçek katil Barış Koral\'dı, '
          've şimdi onu durduracak kimse kalmadı.',
    ),
    'bora': MysteryEnding(
      title: '❌ Yanlış İz',
      body:
          'Bora\'yı suçladınız ama o sadece borcunu ödeyen birine sadık '
          'kalmaya çalışan, korkmuş bir şoförüydü. Gerçek katil CEO '
          'Barış Koral\'dı — Bora\'nın borcunu ödeyen de oydu.',
    ),
  },
);

// ═══════════════════════════════════════════════════════════════════════════
// BÜYÜK FİNAL — ÇEMBER
// ═══════════════════════════════════════════════════════════════════════════

const kFinaleCase = MysteryCase(
  id: 'the_circle',
  number: 4,
  title: 'Çember',
  subtitle: 'Üç vaka, tek el. Bu gece her şey ortaya çıkıyor.',
  emoji: '🎭',
  durationLabel: '~15 dk · BÜYÜK FİNAL',
  isFinale: true,
  introPages: [
    'Üç vaka. Üç farklı şehir, üç farklı kurban. Ama hepsinde aynı iz: '
        'daire içinde bir göz, ve iki harf — V.K.\n\n'
        'Bu sabah kapının altından mühürlü bir zarf çıktı. İçinde tek bir '
        'cümle: "Son toplantıya davetlisiniz, dedektif."',
    'Davet, "V.K. Holdings"in yıllık hayır balosuna. Şehrin en güçlü iş '
        'insanları, siyasetçileri, gazetecileri tek bir salonda.\n\n'
        'Resmi söylem: bu gece kurumun kurucusu, yıllardır kamuoyu önüne '
        'çıkmayan gizemli bir hayırsever, yeni bir "Merkez Sistem" '
        'girişimini duyuracak — şehrin dijital kimlik, bankacılık ve alt '
        'yapısını "tek çatı altında birleştiren" bir platform.',
    'Ama sen artık biliyorsun: Serkan Bulut\'un zimmeti, Deniz Aksu\'nun '
        'sahte tablosu, Barış Koral\'ın gizli transferleri — hepsi aynı '
        'kaynaktan besleniyordu. Hepsi, bu "Merkez Sistem"in sessizce '
        'inşa edilmesi için gereken parayı ve sessizliği sağladı.\n\n'
        'Ve bu gece, kim olduğunu bile bilmediğin biri, imzayı atacak. '
        'Onu durdurmak için 90 dakikan var.',
  ],
  clues: [
    MysteryClue(
      id: 'mask',
      emoji: '🎭',
      title: 'Yarım Maske',
      description:
          'Özel asansörde, yerde yarısı kırılmış altın yaldızlı bir '
          'maskeli balo maskesi. Üzerinde o simge: daire içinde bir göz. '
          'Bu, sıradan bir konuğa ait olamayacak kadar özel işçilikli.',
    ),
    MysteryClue(
      id: 'briefcase',
      emoji: '💼',
      title: 'Kilitli Evrak Çantası',
      description:
          'Bir yardımcının sıkı sıkı koruduğu evrak çantasında "Merkez '
          'Sistem Aktivasyon Protokolü" yazan belgeler var — imza '
          'satırı hâlâ boş... ya da öyle sanıyorsun.',
    ),
    MysteryClue(
      id: 'signature',
      emoji: '🖋️',
      title: 'Islak İmza',
      description:
          'Özel ofiste, mürekkebi hâlâ ıslak bir imza sayfası. Birileri, '
          'senin fark etmenden dakikalar önce, "vekaleten" bir imza '
          'atmış. Kimin adına?',
    ),
    MysteryClue(
      id: 'server',
      emoji: '📡',
      title: 'Gizli Sunucu Odası',
      description:
          'Kitaplığın arkasında saklı bir kapı, bir sunucu odasına '
          'açılıyor. Ekranlarda kocaman bir geri sayım: "MERKEZ SİSTEM — '
          'AKTİVASYON". Süre hızla azalıyor.',
    ),
    MysteryClue(
      id: 'watch',
      emoji: '🕰️',
      title: 'Kırık Cep Saati',
      description:
          'Özel asansörün önünde düşürülmüş antika bir cep saati, '
          'kapağının içine "V.K." kazınmış. Demek ki az önce biri, tam '
          'buradan, aceleyle geçmiş.',
    ),
    MysteryClue(
      id: 'guestlist',
      emoji: '📇',
      title: 'Konuk Listesi Notu',
      description:
          'Kapıdaki konuk listesinde bir isim üzerine, farklı bir elle, '
          'başka bir isim yazılmış: "Kerem Aydın". Altındaki orijinal isim '
          'okunmuyor — sanki bilerek kazınmış.',
    ),
  ],
  suspects: [
    MysterySuspect(
      id: 'kerem',
      name: 'Kerem Aydın',
      role: 'Balodaki "Yardımcı Dedektif"',
      emoji: '🕴️‍♂️',
      flavor: 'Akşam boyunca sana yardım eden, sıcakkanlı, her şeyi bilen '
          'gizemli bir tanıdık. Belki de fazla yardımsever.',
      questions: [
        MysteryQA(
          'Bu geceki davetin arkasında kim var, biliyor musun?',
          'Söylentiler var tabii ama kimse gerçek yüzünü görmedi. Ben de '
              'senin kadar meraklıyım, inan.',
        ),
        MysteryQA(
          'Konuk listesindeki değişikliği nasıl açıklarsın?',
          'Son dakika bir davet değişikliği olmuş olmalı, bu tür '
              'balolarda sık olur. Neden bu kadar takıldın ki buna?',
        ),
      ],
    ),
    MysterySuspect(
      id: 'naz',
      name: 'Naz Ilgın',
      role: 'Bir Senatörün Danışmanı',
      emoji: '👩‍💼',
      flavor: 'Gergin, sürekli etrafı kolaçan ediyor. Elinde küçük bir '
          'ses kayıt cihazı sıkıca tutuyor.',
      questions: [
        MysteryQA(
          'Neden bu kadar tedirginsiniz?',
          'Çünkü haftalardır bu "Merkez Sistem"i araştırıyorum ve '
              'bulduklarım beni korkutuyor. Elimdeki kayıtlar kanıt '
              'olabilir — eğer buradan sağ çıkarsam.',
        ),
        MysteryQA(
          'Elinizdeki kayıt cihazında ne var?',
          'V.K. Holdings\'in yönetim kurulu toplantılarından gizlice '
              'kaydettiğim konuşmalar. Kimin gerçekte kim olduğuna dair '
              'ipuçları.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'cengiz',
      name: 'Cengiz Örs',
      role: 'V.K. Holdings Güvenlik Şefi',
      emoji: '🕶️',
      flavor: 'İri yapılı, sert bakışlı, kulaklığından sürekli talimat '
          'alıyor. Herkesin ilk şüphelendiği kişi.',
      questions: [
        MysteryQA(
          'Patronunuzu hiç yüz yüze gördünüz mü?',
          'Hayır. On yıldır burada çalışıyorum, talimatları hep '
              'aracılardan alırım. Tuhaf, biliyorum — ama iyi para '
              'ödüyor.',
        ),
        MysteryQA(
          'Bu gece neden bu kadar tedbirlisiniz?',
          'Çünkü büyük bir gece bu. "Bugün her şey değişecek" dediler '
              'bana. Ne demek istediklerini ben de bilmiyorum.',
        ),
      ],
    ),
    MysterySuspect(
      id: 'selin',
      name: 'Selin Kutlu',
      role: 'Balo Organizatörü',
      emoji: '💃',
      flavor: 'Kusursuz, pürüzsüz bir ev sahibi tavrı. Ama gözlerinde, '
          'her an bir şeyin kontrolden çıkabileceğine dair bir korku var.',
      questions: [
        MysteryQA(
          'V.K. Holdings için ne kadar süredir çalışıyorsunuz?',
          'Aslında... çalışmıyorum. Kurucusu, küçükken beni büyüten '
              'kişi. Ama onu gerçekten hiç tanımadım — sadece '
              'mektuplarla, banka havaleleriyle var oldu hayatımda.',
        ),
        MysteryQA(
          '"Merkez Sistem" hakkında ne biliyorsunuz?',
          'Sadece bu gece açıklanacağını. Bana hep "bu aile mirası, '
              'bir gün senin de olacak" dediler. Ama şimdi bundan '
              'korkuyorum.',
        ),
      ],
    ),
  ],
  culpritId: 'kerem',
  endings: {
    'kerem': MysteryEnding(
      title: '🎯 Doğru Dedektif — ama çok geç.',
      body:
          'Haklıydın. Akşam boyunca yanında yürüyen, her sorunu '
          'cevaplayan, sana en çok yardım eden o sıcakkanlı adam — '
          '"Kerem Aydın" diye biri hiç var olmadı. O, V.K. Holdings\'in '
          'gerçek kurucusu Vedat Korkmaz\'ın ta kendisiydi; yıllardır '
          'kimseye göstermediği yüzünü, senin gözlerinin içine bakarak '
          'gizlemişti.\n\n'
          'Serkan Bulut\'u parasal çıkmaza o soktu. Deniz Aksu\'nun sahte '
          'tablosunu o finanse etti. Barış Koral\'ın gizli transferlerini '
          'o yönetti. Üç ayrı şehirde, üç ayrı ölüm — hepsi, bu gece imzalanan '
          'tek bir belge için gereken parayı ve sessizliği sağlamak '
          'içindi.\n\n'
          '"Tebrikler, dedektif" diyor, sesi hâlâ o tanıdık sıcaklıkta. '
          '"Gerçekten çok yaklaştın." Sonra saatine bakıyor. "Ama imza beş '
          'dakika önce atıldı. Sunucu odasındaki geri sayım süs değildi."\n\n'
          'Salonun devasa ekranları aynı anda yanıyor: "MERKEZ SİSTEM — '
          'AKTİF." Alkışlar yükseliyor, kimse ne olduğunu anlamıyor. '
          'Vedat Korkmaz, maskesini yeniden takıyor, sana son kez '
          'gülümsüyor ve özel asansöre doğru yürüyor.\n\n'
          'Peşinden koşmak istiyorsun ama bacakların adeta yere '
          'çakılmış. Güvenlik ekipleri sessizce çıkışları kapatmaya '
          'başlıyor. Elinde üç vakanın da kanıtı var — ama karşındaki '
          'artık görünmez, sistemin bir parçası, her yerde ve hiçbir '
          'yerde.\n\n'
          'Nefesin kesiliyor. Bu, bir vakanın sonu değil, dedektif. '
          '\n\nİZ SÜRMEYE DEVAM EDECEK...',
    ),
    'naz': MysteryEnding(
      title: '❌ Yanlış İz — ve zaman doldu.',
      body:
          'Naz\'ı suçladın ama o, gerçeği ortaya çıkarmaya çalışan tek '
          'kişiydi — elindeki kayıtlar seni gerçek suçluya götürebilirdi, '
          'ama artık çok geç.\n\n'
          'Salonun ekranları aynı anda yanıyor: "MERKEZ SİSTEM — AKTİF." '
          'Kalabalık arasında, akşam boyunca sana yardım eden o '
          'sıcakkanlı "Kerem Aydın" son kez gülümsüyor, maskesini takıyor '
          've özel asansöre doğru yürüyor. Onu hiç şüphelenmemiştin.\n\n'
          'Naz sana bakıyor, gözlerinde hem korku hem bir tür acıma var: '
          '"O oydu, değil mi? Hep o muydu?" Cevap veremeden, güvenlik '
          'ekipleri çıkışları kapatmaya başlıyor.\n\n'
          '\nİZ SÜRMEYE DEVAM EDECEK...',
    ),
    'cengiz': MysteryEnding(
      title: '❌ Yanlış İz — ve zaman doldu.',
      body:
          'Cengiz\'i suçladın ama o sadece talimat alan, patronunun '
          'yüzünü bile hiç görmemiş sadık bir çalışandı.\n\n'
          'Salonun ekranları aynı anda yanıyor: "MERKEZ SİSTEM — AKTİF." '
          'O sıcakkanlı "Kerem Aydın" — gerçekte Vedat Korkmaz\'ın ta '
          'kendisi — son kez gülümsüyor ve özel asansöre doğru '
          'kayboluyor. Bütün gece yanı başındaydı ve fark edemedin.\n\n'
          'Güvenlik ekipleri çıkışları kapatmaya başlıyor. Elinde üç '
          'vakanın kanıtı var ama karşındaki artık yok — bir isim, bir '
          'maske, bir gölge.\n\n'
          '\nİZ SÜRMEYE DEVAM EDECEK...',
    ),
    'selin': MysteryEnding(
      title: '❌ Yanlış İz — ve zaman doldu.',
      body:
          'Selin\'i suçladın ama o, bu dünyaya sadece doğduğu için '
          'sürüklenmiş, gerçek gücü hiç olmamış bir kurbandı.\n\n'
          'Salonun ekranları aynı anda yanıyor: "MERKEZ SİSTEM — AKTİF." '
          'O sıcakkanlı "Kerem Aydın" — gerçekte Vedat Korkmaz\'ın ta '
          'kendisi — son kez gülümsüyor ve özel asansöre doğru '
          'kayboluyor.\n\n'
          'Selin\'in gözlerinde bir şey kırılıyor: "O benim... o benim '
          'ailemdi." Cevap veremeden, güvenlik ekipleri çıkışları '
          'kapatmaya başlıyor.\n\n'
          '\nİZ SÜRMEYE DEVAM EDECEK...',
    ),
  },
);

/// Kampanya sırası: her vaka bir öncekini tamamlayınca açılır.
const kMysteryCases = [kCase1, kCase2, kCase3, kFinaleCase];
