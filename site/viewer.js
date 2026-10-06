// pdf.js is vendored into the site by build_site.py, so the published page
// makes no third-party requests and does not break when a CDN does.
import * as pdfjs from "./vendor/pdfjs/pdf.min.mjs";

pdfjs.GlobalWorkerOptions.workerSrc = "./vendor/pdfjs/pdf.worker.min.mjs";

const DEFAULT_MANIFEST = {
  editions: [
    { id: "prob-all", label: "Цветной", file: "prob-all.pdf" },
    { id: "prob-monochrome", label: "Ч/Б", file: "prob-monochrome.pdf" },
  ],
};

// A page never gets wider than this (CSS px) at 100%, so that a 4K monitor
// does not blow the text up to absurd sizes.
const MAX_PAGE_WIDTH = 920;
// How many pages around the viewport keep their rendered bitmap.
const KEEP_RADIUS = 4;

const $ = (id) => document.getElementById(id);
const el = {
  scroller: $("scroller"),
  pages: $("pages"),
  status: $("status"),
  sidebar: $("sidebar"),
  toc: $("toc"),
  tocToggle: $("tocToggle"),
  backdrop: $("backdrop"),
  version: $("version"),
  editions: $("editions"),
  download: $("download"),
  pageInput: $("pageInput"),
  pageCount: $("pageCount"),
  prev: $("prev"),
  next: $("next"),
  back: $("back"),
  zoomIn: $("zoomIn"),
  zoomOut: $("zoomOut"),
  zoomLevel: $("zoomLevel"),
  theme: $("theme"),
};

const ZOOM_STEPS = [0.5, 0.67, 0.8, 1, 1.25, 1.5, 2, 3];

const state = {
  manifest: DEFAULT_MANIFEST,
  edition: null,
  doc: null,
  /** @type {Array<{wrap: HTMLElement, ratio: number, task: any, rendered: boolean}>} */
  slots: [],
  zoom: 1,
  current: 1,
  observer: null,
  loadToken: 0,
  hash: "",
  /** Flat outline entries sorted by page, for highlighting the current section. */
  tocEntries: [],
  /** Pages we jumped away from by following a link. */
  history: [],
};

/* ------------------------------- storage ------------------------------- */

const store = {
  get(key) {
    try { return localStorage.getItem(key); } catch { return null; }
  },
  set(key, value) {
    try { localStorage.setItem(key, value); } catch { /* private mode */ }
  },
};

/* --------------------------------- theme -------------------------------- */

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  store.set("theme", theme);
}

applyTheme(store.get("theme") || "auto");

el.theme.addEventListener("click", () => {
  const order = ["auto", "light", "dark"];
  const next = order[(order.indexOf(document.documentElement.dataset.theme) + 1) % 3];
  applyTheme(next);
  el.theme.title = { auto: "Тема: как в системе", light: "Тема: светлая", dark: "Тема: тёмная" }[next];
});

/* -------------------------------- sidebar ------------------------------- */

const isOverlay = () => window.matchMedia("(max-width: 1040px)").matches;

function setToc(open) {
  el.sidebar.hidden = !open;
  document.body.classList.toggle("toc-open", open);
  el.backdrop.hidden = !open;
  el.tocToggle.setAttribute("aria-expanded", String(open));
  if (!isOverlay()) store.set("toc", open ? "1" : "0");
  if (open) highlightToc();
}

el.tocToggle.addEventListener("click", () => setToc(el.sidebar.hidden));
el.backdrop.addEventListener("click", () => setToc(false));

// Start closed on narrow screens; remember the choice on wide ones.
setToc(isOverlay() ? false : store.get("toc") !== "0");

/* ------------------------------- url state ------------------------------ */

function readHash() {
  const params = new URLSearchParams(location.hash.slice(1));
  return { edition: params.get("v"), page: parseInt(params.get("p"), 10) || null };
}

function writeHash() {
  const params = new URLSearchParams();
  params.set("v", state.edition.id);
  params.set("p", String(state.current));
  state.hash = "#" + params.toString();
  history.replaceState(null, "", state.hash);
}

// Someone followed a link to another page while the viewer was already open.
window.addEventListener("hashchange", () => {
  if (location.hash === state.hash || !state.doc) return;
  const { edition, page } = readHash();
  if (edition && edition !== state.edition.id) {
    const target = state.manifest.editions.find((e) => e.id === edition);
    if (target) return void loadEdition(target, page || 1);
  }
  if (page) scrollToPage(page, { behavior: "smooth" });
});

/* -------------------------------- status -------------------------------- */

function showStatus(html) {
  el.status.innerHTML = html;
  el.status.hidden = false;
}

function hideStatus() {
  el.status.hidden = true;
}

/* -------------------------------- layout -------------------------------- */

function availableWidth() {
  // 24px of breathing room on each side, matching .page's max-width.
  return Math.max(240, Math.min(el.scroller.clientWidth - 24, MAX_PAGE_WIDTH));
}

/** CSS width of a page at the current zoom level. */
function targetWidth() {
  return availableWidth() * state.zoom;
}

function layoutSlots() {
  const width = targetWidth();
  for (const slot of state.slots) {
    slot.wrap.style.width = `${width}px`;
    slot.wrap.style.height = `${Math.round(width * slot.ratio)}px`;
  }
}

/* ------------------------------ destinations ---------------------------- */

/**
 * Turn a PDF destination (named or explicit) into a page number and, when the
 * destination carries coordinates, the vertical position inside that page as a
 * fraction of its height. This is what makes in-document cross-references land
 * on the referenced line rather than the top of the page.
 */
async function resolveDest(dest) {
  if (!dest) return null;
  const doc = state.doc;
  try {
    const explicit = typeof dest === "string" ? await doc.getDestination(dest) : dest;
    if (!Array.isArray(explicit) || !explicit.length) return null;

    const index = await doc.getPageIndex(explicit[0]);
    const target = { page: index + 1, offset: 0 };

    // [ref, /XYZ, left, top, zoom] and [ref, /FitH, top] carry a usable top.
    const kind = explicit[1]?.name;
    const top =
      kind === "XYZ" ? explicit[3] :
      kind === "FitH" || kind === "FitBH" ? explicit[2] :
      null;

    if (typeof top === "number") {
      const page = await doc.getPage(index + 1);
      const viewport = page.getViewport({ scale: 1 });
      const [, y] = viewport.convertToViewportPoint(explicit[2] ?? 0, top);
      target.offset = Math.min(Math.max(y / viewport.height, 0), 1);
    }
    return target;
  } catch {
    return null;
  }
}

async function goToDest(dest, { remember = true } = {}) {
  const target = await resolveDest(dest);
  if (!target) return false;
  if (remember) state.history.push(state.current);
  scrollToPage(target.page, { offset: target.offset, behavior: "smooth" });
  el.back.disabled = !state.history.length;
  if (isOverlay() && !el.sidebar.hidden) setToc(false);
  return true;
}

/* -------------------------------- render -------------------------------- */

function discard(slot) {
  slot.task?.cancel();
  slot.task = null;
  slot.rendered = false;
  slot.wrap.replaceChildren();
}

/** Clickable areas for the PDF's own links: URLs and in-document references. */
async function buildLinkLayer(page, viewport) {
  const annotations = await page.getAnnotations({ intent: "display" });
  const links = annotations.filter((a) => a.subtype === "Link" && (a.url || a.dest || a.action));
  if (!links.length) return null;

  const layer = document.createElement("div");
  layer.className = "linkLayer";

  for (const annotation of links) {
    const [x1, y1, x2, y2] = pdfjs.Util.normalizeRect(
      viewport.convertToViewportRectangle(annotation.rect)
    );
    const a = document.createElement("a");
    a.style.left = `${x1}px`;
    a.style.top = `${y1}px`;
    a.style.width = `${x2 - x1}px`;
    a.style.height = `${y2 - y1}px`;

    if (annotation.url) {
      a.href = annotation.url;
      a.target = "_blank";
      a.rel = "noopener noreferrer";
      a.title = annotation.url;
    } else if (annotation.dest) {
      a.href = "#";
      a.title = "Перейти по ссылке";
      a.addEventListener("click", (e) => {
        e.preventDefault();
        goToDest(annotation.dest);
      });
    } else if (annotation.action) {
      // GoToPage-style named actions: NextPage, PrevPage, FirstPage, LastPage.
      const jump = {
        NextPage: () => state.current + 1,
        PrevPage: () => state.current - 1,
        FirstPage: () => 1,
        LastPage: () => state.slots.length,
      }[annotation.action];
      if (!jump) continue;
      a.href = "#";
      a.addEventListener("click", (e) => {
        e.preventDefault();
        state.history.push(state.current);
        el.back.disabled = false;
        scrollToPage(jump(), { behavior: "smooth" });
      });
    }
    layer.append(a);
  }
  return layer;
}

async function renderPage(index) {
  const slot = state.slots[index];
  if (!slot || slot.rendered || slot.task) return;

  const token = state.loadToken;
  const cssWidth = targetWidth();
  slot.rendered = true;

  let page;
  try {
    page = await state.doc.getPage(index + 1);
  } catch {
    slot.rendered = false;
    return;
  }
  if (token !== state.loadToken) return;

  const unit = page.getViewport({ scale: 1 });
  slot.ratio = unit.height / unit.width;
  slot.wrap.style.height = `${Math.round(cssWidth * slot.ratio)}px`;

  // Render at device resolution, but cap the bitmap so huge zoom levels on
  // phones do not hit the browser's canvas-area limit.
  const dpr = Math.min(window.devicePixelRatio || 1, 2.5);
  const scale = Math.min((cssWidth * dpr) / unit.width, 4096 / unit.width);
  const viewport = page.getViewport({ scale });

  const canvas = document.createElement("canvas");
  canvas.width = Math.floor(viewport.width);
  canvas.height = Math.floor(viewport.height);
  canvas.style.aspectRatio = `${unit.width} / ${unit.height}`;

  const task = page.render({ canvasContext: canvas.getContext("2d", { alpha: false }), viewport });
  slot.task = task;

  try {
    await task.promise;
  } catch (err) {
    if (err?.name !== "RenderingCancelledException") slot.rendered = false;
    return;
  } finally {
    if (slot.task === task) slot.task = null;
  }
  if (token !== state.loadToken) return;

  slot.wrap.replaceChildren(canvas);

  // CSS-pixel viewport shared by the text and link overlays.
  const cssViewport = page.getViewport({ scale: cssWidth / unit.width });

  // Text layer: lets the reader select and copy, and makes the page searchable
  // with the browser's own find. Purely additive — a failure leaves the bitmap.
  try {
    const layer = document.createElement("div");
    layer.className = "textLayer";
    layer.style.setProperty("--total-scale-factor", String(cssWidth / unit.width));
    await new pdfjs.TextLayer({
      textContentSource: page.streamTextContent(),
      container: layer,
      viewport: cssViewport,
    }).render();
    if (token === state.loadToken && slot.rendered) slot.wrap.append(layer);
  } catch { /* bitmap is enough */ }

  try {
    const layer = await buildLinkLayer(page, cssViewport);
    if (layer && token === state.loadToken && slot.rendered) slot.wrap.append(layer);
  } catch { /* links are a bonus */ }
}

/** Keep bitmaps only near the viewport; re-render what came into view. */
function refreshWindow() {
  const first = Math.max(0, state.current - 1 - KEEP_RADIUS);
  const last = Math.min(state.slots.length - 1, state.current - 1 + KEEP_RADIUS);
  state.slots.forEach((slot, i) => {
    if (i < first || i > last) {
      if (slot.rendered) discard(slot);
    }
  });
}

/* ------------------------------- navigation ----------------------------- */

function setCurrent(page, { updateInput = true } = {}) {
  const clamped = Math.min(Math.max(1, page), state.slots.length || 1);
  if (clamped === state.current && !updateInput) return;
  const changed = clamped !== state.current;
  state.current = clamped;
  if (updateInput && document.activeElement !== el.pageInput) {
    el.pageInput.value = String(clamped);
  }
  el.prev.disabled = clamped === 1;
  el.next.disabled = clamped === state.slots.length;
  writeHash();
  if (changed) highlightToc();
}

function scrollToPage(page, { offset = 0, behavior = "instant" } = {}) {
  const slot = state.slots[page - 1];
  if (!slot) return;
  renderPage(page - 1);
  const inner = offset ? Math.max(0, slot.wrap.offsetHeight * offset - 16) : 0;
  const top = slot.wrap.offsetTop - el.pages.offsetTop - 8 + inner;
  el.scroller.scrollTo({ top, behavior });
  setCurrent(page);
}

/** The page occupying most of the viewport. */
function visiblePage() {
  const mid = el.scroller.scrollTop + el.scroller.clientHeight / 3;
  let best = 1;
  for (let i = 0; i < state.slots.length; i++) {
    if (state.slots[i].wrap.offsetTop - el.pages.offsetTop <= mid) best = i + 1;
    else break;
  }
  return best;
}

function goBack() {
  const page = state.history.pop();
  el.back.disabled = !state.history.length;
  if (page) scrollToPage(page, { behavior: "smooth" });
}

/* ------------------------------ outline / ToC --------------------------- */

async function buildToc() {
  el.toc.replaceChildren();
  state.tocEntries = [];

  let outline;
  try {
    outline = await state.doc.getOutline();
  } catch {
    outline = null;
  }
  if (!outline?.length) {
    el.toc.innerHTML = '<p class="toc-empty">В этом PDF нет оглавления.</p>';
    return;
  }

  const token = state.loadToken;

  const buildList = (items, depth) => {
    const ul = document.createElement("ul");
    for (const item of items) {
      const li = document.createElement("li");
      li.className = `depth-${depth}`;

      const a = document.createElement("a");
      a.textContent = item.title.trim();
      a.href = "#";
      if (item.bold) a.style.fontWeight = "600";
      if (item.italic) a.style.fontStyle = "italic";

      const entry = { a, page: null };
      state.tocEntries.push(entry);

      if (item.url) {
        a.href = item.url;
        a.target = "_blank";
        a.rel = "noopener noreferrer";
      } else {
        a.addEventListener("click", (e) => {
          e.preventDefault();
          goToDest(item.dest);
        });
        // Resolving every destination is what lets the page numbers show up and
        // the current section stay highlighted while scrolling.
        resolveDest(item.dest).then((target) => {
          if (!target || token !== state.loadToken) return;
          entry.page = target.page;
          const badge = document.createElement("span");
          badge.className = "toc-page";
          badge.textContent = String(target.page);
          a.prepend(badge);
          highlightToc();
        });
      }

      li.append(a);
      if (item.items?.length) li.append(buildList(item.items, depth + 1));
      ul.append(li);
    }
    return ul;
  };

  el.toc.append(buildList(outline, 0));
}

function highlightToc() {
  let active = null;
  for (const entry of state.tocEntries) {
    if (entry.page !== null && entry.page <= state.current) active = entry;
  }
  for (const entry of state.tocEntries) {
    if (entry === active) entry.a.setAttribute("aria-current", "true");
    else entry.a.removeAttribute("aria-current");
  }
  if (active && !el.sidebar.hidden) {
    active.a.scrollIntoView({ block: "nearest" });
  }
}

/* --------------------------------- zoom --------------------------------- */

function setZoom(zoom, { anchor = true } = {}) {
  const next = Math.min(Math.max(zoom, ZOOM_STEPS[0]), ZOOM_STEPS[ZOOM_STEPS.length - 1]);
  if (Math.abs(next - state.zoom) < 1e-6) return;

  const page = anchor ? visiblePage() : null;
  state.zoom = next;
  el.zoomLevel.textContent = `${Math.round(next * 100)}%`;

  for (const slot of state.slots) if (slot.rendered) discard(slot);
  layoutSlots();
  if (page) scrollToPage(page);
  renderAround();
}

function stepZoom(dir) {
  const i = ZOOM_STEPS.findIndex((z) => z > state.zoom + 1e-6);
  if (dir > 0) setZoom(ZOOM_STEPS[i === -1 ? ZOOM_STEPS.length - 1 : i]);
  else {
    const below = ZOOM_STEPS.filter((z) => z < state.zoom - 1e-6);
    setZoom(below.length ? below[below.length - 1] : ZOOM_STEPS[0]);
  }
}

function renderAround() {
  const page = visiblePage();
  for (let p = page - 1; p <= page + 2; p++) renderPage(p - 1);
}

/* -------------------------------- loading ------------------------------- */

async function loadEdition(edition, startPage = 1) {
  state.edition = edition;
  state.loadToken++;
  const token = state.loadToken;

  for (const slot of state.slots) discard(slot);
  state.slots = [];
  state.history = [];
  el.back.disabled = true;
  el.pages.replaceChildren();
  state.observer?.disconnect();
  el.download.href = edition.file;
  el.download.setAttribute("download", edition.file.split("/").pop());
  showStatus('<div class="spinner"></div><p>Загружаем конспект…</p>');
  paintEditionButtons();

  state.doc?.destroy();
  state.doc = null;

  let doc;
  try {
    doc = await pdfjs.getDocument({ url: edition.file, enableXfa: false }).promise;
  } catch (err) {
    if (token !== state.loadToken) return;
    showStatus(
      `<p>Не удалось загрузить <code>${edition.file}</code>.</p>` +
      `<p><a href="https://github.com/JustMarfix/probability/releases/latest">Скачать из релизов</a></p>`
    );
    console.error(err);
    return;
  }
  if (token !== state.loadToken) { doc.destroy(); return; }

  state.doc = doc;
  hideStatus();
  el.pageCount.textContent = String(doc.numPages);

  const first = await doc.getPage(1);
  const unit = first.getViewport({ scale: 1 });
  const ratio = unit.height / unit.width;

  const frag = document.createDocumentFragment();
  for (let i = 1; i <= doc.numPages; i++) {
    const wrap = document.createElement("div");
    wrap.className = "page";
    wrap.dataset.page = String(i);
    frag.append(wrap);
    state.slots.push({ wrap, ratio, task: null, rendered: false });
  }
  el.pages.append(frag);
  layoutSlots();

  state.observer = new IntersectionObserver(
    (entries) => {
      for (const entry of entries) {
        if (entry.isIntersecting) renderPage(Number(entry.target.dataset.page) - 1);
      }
    },
    { root: el.scroller, rootMargin: "600px 0px" }
  );
  for (const slot of state.slots) state.observer.observe(slot.wrap);

  scrollToPage(Math.min(startPage, doc.numPages));
  buildToc();
}

/* ------------------------------- edition UI ----------------------------- */

function paintEditionButtons() {
  el.editions.replaceChildren();
  if (state.manifest.editions.length < 2) return;
  for (const edition of state.manifest.editions) {
    const btn = document.createElement("button");
    btn.textContent = edition.label;
    btn.setAttribute("aria-pressed", String(edition.id === state.edition?.id));
    btn.addEventListener("click", () => {
      if (edition.id !== state.edition.id) loadEdition(edition, state.current);
    });
    el.editions.append(btn);
  }
}

/* -------------------------------- events -------------------------------- */

let scrollTick = 0;
el.scroller.addEventListener("scroll", () => {
  if (scrollTick) return;
  scrollTick = requestAnimationFrame(() => {
    scrollTick = 0;
    if (!state.slots.length) return;
    setCurrent(visiblePage());
    refreshWindow();
  });
}, { passive: true });

el.prev.addEventListener("click", () => scrollToPage(state.current - 1, { behavior: "smooth" }));
el.next.addEventListener("click", () => scrollToPage(state.current + 1, { behavior: "smooth" }));
el.back.addEventListener("click", goBack);
el.zoomIn.addEventListener("click", () => stepZoom(1));
el.zoomOut.addEventListener("click", () => stepZoom(-1));
el.zoomLevel.addEventListener("click", () => setZoom(1));

el.pageInput.addEventListener("change", () => {
  const n = parseInt(el.pageInput.value, 10);
  if (n) scrollToPage(n);
  el.pageInput.value = String(state.current);
});
el.pageInput.addEventListener("keydown", (e) => {
  if (e.key === "Enter") el.pageInput.blur();
});

document.addEventListener("keydown", (e) => {
  if (e.target.tagName === "INPUT" || e.metaKey || e.ctrlKey || e.altKey) return;
  switch (e.key) {
    case "ArrowRight": case "PageDown": case "j":
      scrollToPage(state.current + 1, { behavior: "smooth" }); break;
    case "ArrowLeft": case "PageUp": case "k":
      scrollToPage(state.current - 1, { behavior: "smooth" }); break;
    case "Home": scrollToPage(1, { behavior: "smooth" }); break;
    case "End": scrollToPage(state.slots.length, { behavior: "smooth" }); break;
    case "Backspace": goBack(); break;
    case "o": case "O": case "щ": case "Щ": setToc(el.sidebar.hidden); break;
    case "Escape": if (!el.sidebar.hidden && isOverlay()) setToc(false); else return; break;
    case "+": case "=": stepZoom(1); break;
    case "-": stepZoom(-1); break;
    case "0": setZoom(1); break;
    default: return;
  }
  e.preventDefault();
});

let resizeTimer = 0;
let lastWidth = window.innerWidth;
window.addEventListener("resize", () => {
  if (window.innerWidth === lastWidth) return; // mobile URL bar show/hide
  lastWidth = window.innerWidth;
  clearTimeout(resizeTimer);
  resizeTimer = setTimeout(() => {
    if (!state.slots.length) return;
    const page = state.current;
    for (const slot of state.slots) if (slot.rendered) discard(slot);
    layoutSlots();
    scrollToPage(page);
    renderAround();
  }, 200);
});

/* --------------------------------- boot --------------------------------- */

(async function boot() {
  el.back.disabled = true;
  try {
    const res = await fetch("manifest.json", { cache: "no-cache" });
    if (res.ok) {
      const data = await res.json();
      state.manifest = { ...DEFAULT_MANIFEST, ...data };
      if (!Array.isArray(state.manifest.editions) || !state.manifest.editions.length) {
        state.manifest.editions = DEFAULT_MANIFEST.editions;
      }
    }
  } catch { /* fall back to the built-in list */ }

  const { version, releaseUrl } = state.manifest;
  if (version) el.version.textContent = version;
  else el.version.hidden = true;
  if (releaseUrl) el.version.href = releaseUrl;

  const hash = readHash();
  const edition =
    state.manifest.editions.find((e) => e.id === hash.edition) || state.manifest.editions[0];
  el.zoomLevel.textContent = "100%";
  await loadEdition(edition, hash.page || 1);
})();
