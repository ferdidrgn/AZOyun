const supportedModes = new Set([
  "runway", "drones", "orbit", "maze", "bowling", "freeKick", "penalty", "ferry",
]);

export function openArcade(main, mode, title) {
  if (!supportedModes.has(mode)) {
    main.querySelector(".arcade-shell").textContent =
      "Bu oyun modu şu anda tarayıcıda kullanılamıyor.";
    return;
  }

  const frame = document.createElement("iframe");
  frame.className = "arcade-frame";
  frame.title = title || "3D Arcade oyunu";
  frame.loading = "eager";
  frame.allow = "fullscreen";
  frame.src = mode === "ferry"
    ? "/arcade3d/vapur-84.html"
    : "/arcade3d/index.html?game=" + encodeURIComponent(mode);
  main.querySelector(".arcade-shell").replaceChildren(frame);
}
