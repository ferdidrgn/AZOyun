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
];

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
};
