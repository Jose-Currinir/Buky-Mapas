// Genera el sprite "cl" de los estilos cl-light / cl-dark: chinchetas de POI
// por categoría en tema claro y oscuro, escudos de ruta, flecha de sentido,
// paradas de bus y metro, y punto de ciudad.
//
//   claro: gota blanca con sombra suave, círculo de color, glifo blanco
//   oscuro: gota gris pizarra #6d7b98, círculo pastel, glifo #191a1c
// Glifos: Material Symbols (Apache 2.0).
//
// Salida: data/sprites/cl{,@2x}.{json,png}
// Uso: (cd scripts/poi-sprite-build && npm install && node gen-poi-sprite.mjs)
import sharp from "sharp";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const REPO = path.resolve(__dirname, "../..");
const SPRITES = path.join(REPO, "data/sprites");
const SYM = path.join(__dirname, "node_modules/@material-symbols/svg-400/rounded");

// Colores de chincheta por categoría (deben coincidir con gen-styles.py).
const PIN = {
  light: {
    food: "#ff8126", shop: "#0597ff", lodging: "#f848c7", culture: "#b56aff",
    park: "#17a773", health: "#f74a55", transport: "#4286f3", service: "#848e96",
  },
  dark: {
    food: "#f0b178", shop: "#74bcfe", lodging: "#ea8ec5", culture: "#d998f7",
    park: "#90c9a0", health: "#fd8e96", transport: "#74bcfe", service: "#b4bcc8",
  },
};

// glifo del estilo -> [categoría, símbolo Material]
const GLYPHS = {
  restaurant: ["food", "restaurant"], fastfood: ["food", "fastfood"], cafe: ["food", "local_cafe"],
  bar: ["food", "local_bar"], icecream: ["food", "icecream"], bakery: ["food", "bakery_dining"],
  grocery: ["shop", "shopping_cart"], mall: ["shop", "local_mall"], clothing: ["shop", "apparel"],
  shop: ["shop", "shopping_bag"],
  lodging: ["lodging", "bed"],
  museum: ["culture", "museum"], gallery: ["culture", "palette"], theatre: ["culture", "theater_comedy"],
  cinema: ["culture", "movie"], attraction: ["culture", "add_a_photo"],
  park: ["park", "park"], golf: ["park", "golf_course"], sport: ["park", "stadium"],
  hospital: ["health", "h_mobiledata"], pharmacy: ["health", "medication"], clinic: ["health", "medical_services"],
  airport: ["transport", "flight"], fuel: ["transport", "local_gas_station"], parking: ["transport", "local_parking"],
  school: ["service", "school"], library: ["service", "local_library"], worship: ["service", "church"],
  civic: ["service", "account_balance"],
};

function glyphPaths(sym) {
  for (const f of [`${sym}-fill.svg`, `${sym}.svg`]) {
    const p = path.join(SYM, f);
    if (fs.existsSync(p)) {
      const svg = fs.readFileSync(p, "utf8");
      return [...svg.matchAll(/<path[^>]*\sd="([^"]+)"/g)].map((m) => `<path d="${m[1]}"/>`).join("");
    }
  }
  throw new Error("glifo no encontrado: " + sym);
}

// Material usa viewBox "0 -960 960 960": lo llevamos a un cuadro de `size` px en (x, y).
const glyph = (sym, x, y, size, fill) =>
  `<g fill="${fill}" transform="translate(${x},${y}) scale(${size / 960}) translate(0,960)">${glyphPaths(sym)}</g>`;

// Chincheta: gota de 23x28 (círculo r=11.5 + punta), círculo interior r=9.5.
function pinSVG(sym, theme, color) {
  const W = 23, H = 28, cx = 11.5, cy = 11.5;
  const drop = `M${cx} 26.6 C${cx - 1.2} 24.4 ${cx - 4.4} 22.4 ${cx - 6.6} 20.9
    A11.5 11.5 0 1 1 ${cx + 6.6} 20.9 C${cx + 4.4} 22.4 ${cx + 1.2} 24.4 ${cx} 26.6 Z`;
  const outer = theme === "light" ? "#ffffff" : "#6d7b98";
  const shadow = theme === "light"
    ? `<defs><filter id="s" x="-30%" y="-30%" width="160%" height="160%">
         <feGaussianBlur stdDeviation="0.8"/></filter></defs>
       <path d="${drop}" fill="#3c4043" opacity="0.32" transform="translate(0,0.7)" filter="url(#s)"/>`
    : "";
  const g = theme === "light" ? "#ffffff" : "#191a1c";
  return `<svg xmlns="http://www.w3.org/2000/svg" width="${W}" height="${H}" viewBox="0 0 ${W} ${H}">
${shadow}<path d="${drop}" fill="${outer}"/>
<circle cx="${cx}" cy="${cy}" r="9.5" fill="${color}"/>
${glyph(sym, cx - 6.25, cy - 6.25, 12.5, g)}
</svg>`;
}

// Escudo estirable (icon-text-fit): rectángulo redondeado con borde.
function shieldSVG(fill, stroke) {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="20" height="16" viewBox="0 0 20 16">
<rect x="0.75" y="0.75" width="18.5" height="14.5" rx="3" fill="${fill}" stroke="${stroke}" stroke-width="1.5"/></svg>`;
}

const roundSquare = (bg, sym, fg, size = 15) => `<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}" viewBox="0 0 ${size} ${size}">
<rect x="0.5" y="0.5" width="${size - 1}" height="${size - 1}" rx="3.5" fill="${bg}" stroke="#ffffff" stroke-width="1"/>
${glyph(sym, 2.25, 2.25, size - 4.5, fg)}</svg>`;

const arrowSVG = (c) => `<svg xmlns="http://www.w3.org/2000/svg" width="12" height="9" viewBox="0 0 12 9">
<path d="M0.5 4.5 H8.5 M6 1.5 L9.5 4.5 L6 7.5" fill="none" stroke="${c}" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/></svg>`;

const dotSVG = (fill, stroke, r = 3.2, sw = 1.4) => `<svg xmlns="http://www.w3.org/2000/svg" width="9" height="9" viewBox="0 0 9 9">
<circle cx="4.5" cy="4.5" r="${r}" fill="${fill}" stroke="${stroke}" stroke-width="${sw}"/></svg>`;

const metroSVG = (red) => `<svg xmlns="http://www.w3.org/2000/svg" width="14" height="14" viewBox="0 0 14 14">
<circle cx="7" cy="7" r="6.6" fill="#ffffff"/><circle cx="7" cy="7" r="5.3" fill="none" stroke="${red}" stroke-width="1.1"/>
${glyph("subway", 3.4, 3.4, 7.2, red)}</svg>`;

function icons() {
  const out = {};
  for (const theme of ["light", "dark"]) {
    for (const [id, [cat, sym]] of Object.entries(GLYPHS)) {
      out[`pin-${theme}-${id}`] = { svg: pinSVG(sym, theme, PIN[theme][cat]) };
    }
  }
  out["shield-national-light"] = { svg: shieldSVG("#ffffff", "#5f6368"), stretch: true };
  out["shield-national-dark"] = { svg: shieldSVG("#bdc1c6", "#1c2a40"), stretch: true };
  out["shield-regional-light"] = { svg: shieldSVG("#1e8e3e", "#ffffff"), stretch: true };
  out["shield-regional-dark"] = { svg: shieldSVG("#2f7d47", "#1c2a40"), stretch: true };
  out["oneway-light"] = { svg: arrowSVG("#8d99a6") };
  out["oneway-dark"] = { svg: arrowSVG("#6d7b98") };
  out["transit-bus-light"] = { svg: roundSquare("#5b6b7c", "directions_bus", "#ffffff") };
  out["transit-bus-dark"] = { svg: roundSquare("#6d7b98", "directions_bus", "#191a1c") };
  // metro: círculo blanco con anillo rojo y glifo genérico (no el logotipo de Metro S.A.)
  out["transit-metro-light"] = { svg: metroSVG("#e2231a") };
  out["transit-metro-dark"] = { svg: metroSVG("#ef5350") };
  // puntos de POI de menor importancia, por categoría
  for (const theme of ["light", "dark"]) {
    for (const [cat, color] of Object.entries(PIN[theme])) {
      out[`dot-${theme}-${cat}`] = { svg: dotSVG(color, theme === "light" ? "#ffffff" : "#1c2a40", 2.9, 1) };
    }
  }
  out["dot-light"] = { svg: dotSVG("#ffffff", "#5f6368") };
  out["dot-dark"] = { svg: dotSVG("#1c2a40", "#c8cdd5") };
  return out;
}

async function render(svg, scale) {
  const img = sharp(Buffer.from(svg), { density: 72 * scale * 4 });
  const meta = await sharp(Buffer.from(svg)).metadata();
  const w = Math.round(meta.width * scale), h = Math.round(meta.height * scale);
  return { buf: await img.resize(w, h).png().toBuffer(), w, h };
}

async function buildSheet(name, scale, suffix) {
  const all = icons();
  const composites = [], SHEET_W = 300 * scale;
  const outJson = {};
  let x = 0, y = 0, rowH = 0;
  for (const [id, def] of Object.entries(all)) {
    const { buf, w, h } = await render(def.svg, scale);
    if (x + w > SHEET_W) { x = 0; y += rowH + 2 * scale; rowH = 0; }
    composites.push({ input: buf, top: y, left: x });
    const entry = { width: w, height: h, x, y, pixelRatio: scale };
    if (def.stretch) {
      const r = 4 * scale;  // radio + borde: no se estiran las esquinas
      entry.stretchX = [[r, w - r]];
      entry.stretchY = [[r, h - r]];
      entry.content = [r, r - scale, w - r, h - r + scale];
    }
    outJson[id] = entry;
    x += w + 2 * scale;
    rowH = Math.max(rowH, h);
  }
  const H = y + rowH;
  // PNG con paleta y máxima compresión: el sprite se descarga en cada carga del mapa
  const sheet = await sharp({
    create: { width: SHEET_W, height: H, channels: 4, background: { r: 0, g: 0, b: 0, alpha: 0 } },
  }).composite(composites).png({ compressionLevel: 9, palette: true, quality: 100, effort: 10 }).toBuffer();

  fs.writeFileSync(path.join(SPRITES, `${name}${suffix}.png`), sheet);
  fs.writeFileSync(path.join(SPRITES, `${name}${suffix}.json`), JSON.stringify(outJson));
  console.log(`${name}${suffix}: ${SHEET_W}x${H}, ${Object.keys(outJson).length} íconos, ${(sheet.length / 1024).toFixed(0)} KB`);
}

fs.mkdirSync(SPRITES, { recursive: true });
await buildSheet("cl", 1, "");
await buildSheet("cl", 2, "@2x");
console.log("listo");
