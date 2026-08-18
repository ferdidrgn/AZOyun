/// Tek cihazda oynanan "hızlı oyunlar" için ortak kimlikler.
/// Yeni bir hızlı oyun eklerken buraya da ekle — başarım/istatistik
/// sistemleri (ör. "Her Şeyi Dene") bu listeye göre çalışır.
const List<String> kQuickGameIds = [
  'tictactoe',
  'connect4',
  'reversi',
  'rps',
  'memory',
  'dotsboxes',
  'nim',
  'snake',
  '2048',
  'reflex',
  'trivia',
  'bullscows',
  'balloonpop',
  'diceparty',
  'slidingpuzzle',
  'jumpdash',
  'colormemory',
  'minibowling',
  'mysterycase1',
];

/// Firebase oda-tabanlı (çok oyunculu) oyunların kimlikleri — bkz. her
/// oyunun `ProfileService.reportGameResult(gameId: ...)` çağrısı.
/// Profil/İstatistik ekranındaki "oyun çeşitliliği" grafiği bu listeyi
/// [kQuickGameIds] ile birlikte kullanır.
const List<String> kOnlineGameIds = [
  'racing', 'impostor', 'golf', 'word', 'dama', 'okey',
  'fighter', 'hangman', 'city', 'vampire', 'liar', 'soccer',
];

const Map<String, String> kOnlineGameTitles = {
  'racing': 'Araba Yarışı',
  'impostor': 'Hain Kim?',
  'golf': 'Mini Golf',
  'word': 'Kelime Bulmaca',
  'dama': 'Türk Dama',
  'okey': 'Okey',
  'fighter': 'Dövüşçüler',
  'hangman': 'Adam Asmaca',
  'city': 'Şehir Bulmaca',
  'vampire': 'Vampir Köylü',
  'liar': 'Yalancılar Kahvesi',
  'soccer': 'Serbest Vuruş',
};

const Map<String, String> kQuickGameTitles = {
  'tictactoe': 'XOX',
  'connect4': "4'lü Bağlantı",
  'reversi': 'Reversi',
  'rps': 'Taş Kağıt Makas',
  'memory': 'Hafıza Kartları',
  'dotsboxes': 'Çizgi Doldurma',
  'nim': 'Taş Alma',
  'snake': 'Yılan',
  '2048': '2048',
  'reflex': 'Refleks Çarpışması',
  'trivia': 'Kim Bilir?',
  'bullscows': 'Sayı Tahmin Düellosu',
  'balloonpop': 'Balon Patlatma',
  'diceparty': 'Parti Zarı',
  'slidingpuzzle': 'Kayan Yapboz',
  'jumpdash': 'Zıpla Geç',
  'colormemory': 'Renk Hafızası',
  'minibowling': 'Mini Bovling',
  'mysterycase1': 'Gece Ekspresi Cinayeti',
};
