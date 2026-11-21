// Public web catalog for the arcade games bundled with the Flutter app.
export const arcadeGames = {
  "vapur-84": {
    mode: "ferry",
    title: "Vapur 84",
    description: "Boğaz’da vapuru üç şerit arasında yönlendir, 60 saniyede bilet topla ve şamandıralardan kaç.",
    mark: "⛴",
    category: "Arcade",
    image: "/salon/vapur-84.jpg",
  },
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
      ${slug === "vapur-84"
        ? `<img class="card-art ferry-cover" src="${game.image}" alt="" loading="lazy">`
        : `<div class="card-art classic-mark" aria-hidden="true">${game.mark}</div>`}
      <div class="card-info"><span>${game.category ?? "3D Arcade"}</span><h3>${game.title}</h3><p>${game.description}</p></div>
      <span class="play" aria-hidden="true">↗</span></a>`).join("\n");
}
