import { mkdir, readFile, writeFile } from "node:fs/promises";
import { classics, classicCards } from "../web/salon/classic-catalog.mjs";

const origin = "https://azoyun.web.app";
const brand = "AZ Oyun";
const defaultImage = "/salon/hero.jpg";
const extras = {
  ayna: ["Ayna Odası", "Işıkların sırasını hatırla ve işaretlere aynı sırayla dokun.", "Tek kişilik"],
  "klasik-okey": ["Klasik Okey", "Dört oyuncuyla TV’de masa kur ve telefonundan taşlarını diz.", "Aile Masası", "/?family=tv&game=okey"],
  "101-okey": ["101 Okey", "Dört oyuncuyla 101 puanı tamamla, elini aç ve taş işle.", "Aile Masası", "/?family=tv&game=okey101"],
  mahalleler: ["Mahalleler", "İki ila dört oyuncuyla mülk al, kira topla ve özel takas yap.", "Aile Masası", "/?family=tv&game=city"],
  "yorunge-pilotu": ["Yörünge Pilotu", "Uzay aracını yönlendir ve 3D halkalardan geç.", "3D Arcade", "/arcade3d/?game=orbit", "/salon/orbit.jpg"],
  "kristal-labirent": ["Kristal Labirent", "Üç kristali topla ve labirentin altın çıkışını bul.", "3D Arcade", "/arcade3d/?game=maze", "/salon/maze.jpg"],
};
const escape = (value) => String(value).replace(/[&<>"']/g, (char) =>
  ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[char]);

function metadata(title, description, path, image = defaultImage) {
  const url = origin + path;
  const social = [["title", title], ["description", description], ["image", origin + image]];
  return [
    `<link rel="canonical" href="${url}">`,
    '<meta name="author" content="AZ Oyun">',
    '<meta property="og:type" content="website">',
    '<meta property="og:locale" content="tr_TR">',
    '<meta property="og:site_name" content="AZ Oyun">',
    `<meta property="og:url" content="${url}">`,
    '<meta name="twitter:card" content="summary_large_image">',
    ...social.flatMap(([key, value]) => [
      `<meta property="og:${key}" content="${escape(value)}">`,
      `<meta name="twitter:${key}" content="${escape(value)}">`,
    ]),
  ].join("\n    ");
}

export async function writePublicPages(input, output) {
  const template = await readFile(new URL("index.html", input), "utf8");
  const allGames = { ...Object.fromEntries(Object.entries(classics).map(([id, game]) => [id, game.slice(0, 3)])), ...extras };
  const total = Object.keys(allGames).length;
  const homeDescription = `AZ Oyun’da ${total} tarayıcı oyunu oyna. Okey ve Mahalleler için TV’de masa kur, QR kodla katıl veya 2048, Yılan ve 3D oyunlara başla.`;
  const familyLinks = {
    "/?family=tv&amp;game=okey": "/oyun/klasik-okey/",
    "/?family=tv&amp;game=okey101": "/oyun/101-okey/",
    "/?family=tv&amp;game=city": "/oyun/mahalleler/",
    "/?play=ayna": "/oyun/ayna/",
    "/arcade3d/?game=orbit": "/oyun/yorunge-pilotu/",
    "/arcade3d/?game=maze": "/oyun/kristal-labirent/",
  };
  const applyHead = (html, title, description, path, image) => html
    .replace(/<title>[^<]+<\/title>/, `<title>${escape(title)}</title>`)
    .replace(/<meta\s+name="description"\s+content="[^"]*"\s*\/?>/, `<meta name="description" content="${escape(description)}">`)
    .replace("<!-- page-metadata -->", metadata(title, description, path, image));
  const structuredData = (html, data) => html.replace("</head>",
    '  <script type="application/ld+json">' + JSON.stringify({
      "@context": "https://schema.org", inLanguage: "tr", ...data,
    }).replaceAll("<", "\\u003c") + "</script>\n</head>");
  let home = structuredData(
    applyHead(template, `AZ Oyun · ${total} Tarayıcı Oyunu`, homeDescription, "/"),
    { "@type": "WebSite", name: brand, url: origin + "/" },
  );
  for (const [oldLink, newLink] of Object.entries(familyLinks)) home = home.replace(`href="${oldLink}"`, `href="${newLink}"`);
  home = home.replace("<!-- classic-cards -->", classicCards());
  await writeFile(new URL("index.html", output), home);

  const paths = ["/", "/privacy-policy.html", "/terms.html"];
  for (const [id, [name, description, mode, action, image]] of Object.entries(allGames)) {
    const path = "/oyun/" + id + "/";
    const main = `<main id="main" class="shell room-page"${action ? "" : ` data-play="${id}"`}>
      <div class="room-title"><div><h1>${escape(name)}</h1><p>${escape(mode)}</p></div><a class="button outline" href="/#oyunlar">Oyun salonu</a></div>
      <section class="surface classic-stage stack"><p>${escape(description)}</p>
        ${action ? `<a class="button primary" href="${escape(action)}">${mode === "Aile Masası" ? "TV’de masa aç" : "Oyunu başlat"}</a>` :
          '<noscript><p>Oynamak için tarayıcında JavaScript’i etkinleştir.</p></noscript>'}
      </section></main>`;
    const page = structuredData(
      applyHead(template, name + " Oyna · " + brand, description, path, image)
        .replace(/<main\b[\s\S]*?<\/main>/, main),
      { "@type": "VideoGame", name, description, url: origin + path,
        image: origin + (image || defaultImage), gamePlatform: "Web browser" },
    );
    const directory = new URL("oyun/" + id + "/", output);
    await mkdir(directory, { recursive: true });
    await writeFile(new URL("index.html", directory), page);
    paths.push(path);
  }
  const sitemap = '<?xml version="1.0" encoding="UTF-8"?>\n<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    paths.map((path) => `  <url><loc>${origin}${path}</loc></url>`).join("\n") + "\n</urlset>\n";
  await writeFile(new URL("sitemap.xml", output), sitemap);
  const joinPage = applyHead(template, "Oda Daveti · AZ Oyun", "AZ Oyun oda davetini aç.", "/join/")
    .replace("</head>", '  <meta name="robots" content="noindex">\n</head>')
    .replace(/<main\b[\s\S]*?<\/main>/, '<main id="main" class="shell room-page"><h1>Oda daveti</h1><noscript>Daveti açmak için JavaScript’i etkinleştir.</noscript></main>');
  await mkdir(new URL("join/", output), { recursive: true });
  await writeFile(new URL("join/index.html", output), joinPage);
  const notFound = applyHead(template, "Sayfa bulunamadı · AZ Oyun", "Aradığın sayfa bulunamadı.", "/404.html")
    .replace("</head>", '  <meta name="robots" content="noindex">\n</head>')
    .replace('<script type="module" src="/salon/app.mjs"></script>', "")
    .replace(/<main\b[\s\S]*?<\/main>/, '<main id="main" class="shell room-page"><div class="room-title"><h1>Sayfa bulunamadı</h1><a class="button primary" href="/#oyunlar">Oyun salonu</a></div></main>');
  await writeFile(new URL("404.html", output), notFound);
}
