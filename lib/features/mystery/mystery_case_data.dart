// ═══════════════════════════════════════════════════════════════════════════
// "GECE EKSPRESİ CİNAYETİ" — vaka içeriği
// Tek oyunculu, polisiye/iz sürme temalı hikaye oyunu. Kanıt topla, şüpheli
// sorgula, gerçek katili bul. Arkadaşlarla birlikte tartışarak da oynanabilir.
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

/// Gerçek katil.
const kCulpritId = 'serkan';

const kIntroPages = [
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
];

const kClues = [
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
        'açık: 47.500 TL. Kenara küçük harflerle "S.B. ile konuş" yazılmış.',
  ),
];

const kSuspects = [
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
];

const kEndings = {
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
        'Vaka kapandı, dedektif. İyi iş çıkardın.',
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
};
