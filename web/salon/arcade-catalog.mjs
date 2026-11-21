// Public web catalog for the same Three.js modes loaded by Flutter's WebView.
export const arcadeGames = {
  "neon-pist": {
    mode: "runway",
    title: "Neon Pist",
    description: "Şerit değiştir, engellerden kaç ve enerji küplerini topla.",
    mark: "⌁",
  },
  "sinyal-avi": {
    mode: "drones",
    title: "Sinyal Avı",
    description: "Yaklaşan keşif dronlarına dokun ve dört tanesi kaçmadan yakala.",
    mark: "⌖",
  },
  "yorunge-pilotu": {
    mode: "orbit",
    title: "Yörünge Pilotu",
    description: "Uzay aracını yönlendir ve 3D halkalardan geç.",
    mark: "◉",
    image: "/salon/orbit.jpg",
  },
  "kristal-labirent": {
    mode: "maze",
    title: "Kristal Labirent",
    description: "Üç kristali topla ve labirentin altın çıkışını bul.",
    mark: "◇",
    image: "/salon/maze.jpg",
  },
  "mini-bovling": {
    mode: "bowling",
    title: "3D Mini Bowling",
    description: "Topu sürükleyerek hedefle ve üç atışta kukaları devir.",
    mark: "◉",
  },
  "frikik-ustasi": {
    mode: "freeKick",
    title: "Frikik Ustası",
    description: "Falsolu vuruş yap, barajı aş ve kaleciyi geç.",
    mark: "⌒",
  },
  "penalti-antrenmani": {
    mode: "penalty",
    title: "Penaltı Antrenmanı",
    description: "Topu sürükleyerek yönlendir ve kaleciyi geç.",
    mark: "◎",
  },
};

export function arcadeCards() {
  return Object.entries(arcadeGames).map(([slug, game]) =>
    `<a class="game-card classic-card arcade-card" data-kind="arcade" href="/oyun/${slug}/">
      <div class="card-art classic-mark" aria-hidden="true">${game.mark}</div>
      <div class="card-info"><span>3D Arcade</span><h3>${game.title}</h3><p>${game.description}</p></div>
      <span class="play" aria-hidden="true">↗</span></a>`).join("\n");
}
