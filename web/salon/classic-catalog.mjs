export const classics = {
  xox: ["XOX", "Üç taşı sırala", "2 kişi", "×"],
  dortlu: ["Dörtlü Diz", "Dört taşı yan yana getir", "2 kişi", "●"],
  nim: ["Nim", "Son taşı alan kazanır", "2 kişi", "Ⅲ"],
  reversi: ["Reversi", "Rakibin disklerini çevir", "2 kişi", "◐"],
  noktalar: ["Noktalar ve Kutular", "Çizgilerle kutu kapat", "2 kişi", "⊞"],
  tkm: [
    "Taş Kağıt Makas",
    "Bilgisayara karşı üç galibiyet",
    "Tek kişilik",
    "✂",
  ],
  zar: ["Zar Partisi", "Zar at, tur puanını kasaya al", "2 kişi", "⚄"],
  hafiza: ["Hafıza Eşleştirme", "Aynı kartları bul", "Tek kişilik", "◇"],
  uclu: ["Üçlü Eşle", "Tepside üç aynı simgeyi birleştir", "Tek kişilik", "✿"],
  2048: ["2048", "Eşit sayıları kaydırıp birleştir", "Tek kişilik", "²"],
  yapboz: ["Kayan Yapboz", "15 taşı sıraya diz", "Tek kişilik", "▦"],
  sayi: ["Sayı Say", "1’den 25’e sırayla dokun", "Tek kişilik", "₁₂"],
  matematik: ["Matematik Bulmacası", "On işlemi doğru çöz", "Tek kişilik", "±"],
  "sayi-tahmin": [
    "Sayı Tahmini",
    "İpuçlarından gizli sayıyı çöz",
    "Tek kişilik",
    "#",
  ],
  asmaca: [
    "Adam Asmaca",
    "Altı hata hakkıyla kelimeyi bul",
    "Tek kişilik",
    "A",
  ],
  sehir: [
    "Şehir Bulmaca",
    "İpucundan Türkiye’deki şehri bul",
    "Tek kişilik",
    "⌂",
  ],
  kelime: [
    "Kelime Bulmaca",
    "Karışan harfleri doğru sıraya koy",
    "Tek kişilik",
    "Ab",
  ],
  bilgi: [
    "Bilgi Yarışması",
    "Genel kültür sorularını cevapla",
    "Tek kişilik",
    "?",
  ],
  futbol: [
    "Futbol Bilgi Yarışması",
    "Futbol sorularını cevapla",
    "Tek kişilik",
    "⚽",
  ],
  refleks: ["Refleks Testi", "Işık yanınca dokun", "Tek kişilik", "↯"],
  balon: ["Balon Patlat", "Süre dolmadan balonları yakala", "Tek kişilik", "○"],
  yilan: ["Yılan", "Yemleri topla ve kuyruğundan kaç", "Tek kişilik", "∿"],
  oje: [
    "Oje Atölyesi",
    "Renk ve desenlerle kendi setini yap",
    "Tek kişilik",
    "✦",
  ],
  ciz: ["Çiz Kazan", "Verilen kelimeyi süre dolmadan çiz", "Yerel parti", "✎"],
  maymun: [
    "Maymun Dokunuşu",
    "Yer değiştiren hedefe dokun",
    "Tek kişilik",
    "♧",
  ],
  scuba: ["Scuba Sweep", "Süre dolmadan atıkları topla", "Tek kişilik", "♻"],
  zipla: ["Zıpla Geç", "Engellerin üzerinden atla", "Tek kişilik", "↟"],
  kaplan: [
    "Kaplan Koşusu",
    "Engelleri aş, altınları topla",
    "Tek kişilik",
    "₊",
  ],
  serit: [
    "Şerit Yarışı",
    "Şerit değiştirerek araçlardan kaç",
    "Tek kişilik",
    "⋮",
  ],
  bovling: ["Mini Bovling", "İşaretlenen hatta atış yap", "Tek kişilik", "◉"],
  penalti: [
    "Penaltı Antrenmanı",
    "Beş vuruşta kaleciyi geç",
    "Tek kişilik",
    "◎",
  ],
  frikik: ["Frikik Ustası", "Barajı aşacak köşeyi seç", "Tek kişilik", "⌒"],
};

export function classicCards() {
  return Object.entries(classics).map(([id, [name, description, mode, mark]]) =>
    `<a class="game-card classic-card" data-kind="${mode === "Tek kişilik" ? "solo" : "local"}" href="/oyun/${id}/">
      <div class="card-art classic-mark" aria-hidden="true">${mark}</div>
      <div class="card-info"><span>${mode}</span><h3>${name}</h3><p>${description}</p></div>
      <span class="play" aria-hidden="true">↗</span></a>`).join("\n");
}
