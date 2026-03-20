/**
 * Pixel sprite generator (Node built-ins only). Outputs PNGs; run: node tools/gen_sprites.mjs
 */
import fs from "fs";
import path from "path";
import zlib from "zlib";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.join(__dirname, "..");
const OUT = path.join(ROOT, "assets", "sprites");

const PAL = {
  _: [0, 0, 0, 0],
  o: [45, 31, 24, 255],
  f: [107, 83, 68, 255],
  l: [140, 110, 90, 255],
  n: [201, 123, 137, 255],
  w: [200, 200, 210, 255],
  m: [60, 55, 50, 255],
  s: [90, 95, 100, 255],
  r: [240, 90, 70, 255],
  y: [255, 220, 80, 255],
  g: [70, 180, 90, 255],
  G: [45, 140, 60, 255],
  B: [55, 120, 200, 255],
  O: [255, 140, 40, 255],
  e: [180, 180, 190, 255],
};

const ACCENT_TEAM_A = [89, 191, 242];
const ACCENT_TEAM_B = [242, 115, 89];

const MOLE_IDLE = [
  "____oooooooo____",
  "___offfffffoo___",
  "__offlllllllfoo__",
  "_offlllllllllfoo_",
  "_offllnnnnlllfoo_",
  "_offlllllllllfoo_",
  "__offlllllllfoo__",
  "___ooffffffoo____",
  "____ooffffoo_____",
  "_____mmmmmm______",
  "____mmhhssmm_____",
  "___mmhhsssshhmm____",
  "__mmssssssssmm___",
  "__mmssssssssmm___",
  "__mmmmmmmmmmmm___",
  "___mmmmmmmmmm____",
  "____oooooooo_____",
];

const MOLE_AIM = MOLE_IDLE;

const MOLE_WALK1 = [
  "____oooooooo____",
  "___offfffffoo___",
  "__offlllllllfoo__",
  "_offlllllllllfoo_",
  "_offllnnnnlllfoo_",
  "_offlllllllllfoo_",
  "__offlllllllfoo__",
  "___ooffffffoo____",
  "____ooffffoo_____",
  "_____mmmmmm______",
  "____mmhhssmm_____",
  "___mmhhsssshhmm____",
  "__mmssssssssmm___",
  "__mmssssssssmm___",
  "__mmmmmmmmmmmm___",
  "___mmmmmmmmmm____",
  "__ooooooooo______",
];

const MOLE_WALK2 = [
  "____oooooooo____",
  "___offfffffoo___",
  "__offlllllllfoo__",
  "_offlllllllllfoo_",
  "_offllnnnnlllfoo_",
  "_offlllllllllfoo_",
  "__offlllllllfoo__",
  "___ooffffffoo____",
  "____ooffffoo_____",
  "_____mmmmmm______",
  "____mmhhssmm_____",
  "___mmhhsssshhmm____",
  "__mmssssssssmm___",
  "__mmssssssssmm___",
  "__mmmmmmmmmmmm___",
  "___mmmmmmmmmm____",
  "________ooooooooo",
];

function gridToRgba(lines, accentRgb) {
  const h = lines.length;
  const w = Math.max(...lines.map((l) => l.length));
  const pix = new Uint8Array(w * h * 4);
  for (let y = 0; y < h; y++) {
    const line = lines[y];
    for (let x = 0; x < w; x++) {
      const ch = line[x] || "_";
      let c;
      if (ch === "h") c = accentRgb.concat(255);
      else c = PAL[ch] || PAL._;
      const i = (y * w + x) * 4;
      pix[i] = c[0];
      pix[i + 1] = c[1];
      pix[i + 2] = c[2];
      pix[i + 3] = c[3];
    }
  }
  return { w, h, pix };
}

const ROCKET_ASC = `
_______OOOOOOO_____
______OrrrrrrO_____
_____OrrrrrrrrO____
____OrrrrrrrrrrO___
___OrrrrrrrrrrrrO__
___OrrrryyyyyrrrO__
___OrrryyyyyyyrrO__
___OrrryyOOOyyrrO__
___OrrryOOOOyyrrO__
___OrrryOOOOyyrrO__
___OrrryyOOOyyrrO__
___OrrryyyyyyyrrO__
___OrrrryyyyyrrrO__
___OrrrrrrrrrrrrO__
____OrrrrrrrrrrO___
_____OrrrrrrrrO____
______OrrrrrrO_____
_______OOOOOOO_____
`;

const GRENADE_ASC = `
__________ooo_______
_________offoo______
________offffoo_____
_______offffffoo____
______offffffffoo___
_____offffGGfffoo___
____offffGGGGfffoo__
___offffGGGGGGffoo__
___offffGGyyGGffoo__
___offffGyyyyGffoo__
___offffGyyyyGffoo__
___offffGGyyGGffoo__
___offffGGGGGGffoo__
____offffGGGGffoo___
_____offffGGfffoo___
______offffffffoo___
_______offffffoo____
________offffoo_____
_________offoo______
__________ooo_______
`;

function parseGrid(str, fixedW) {
  const lines = str
    .trim()
    .split("\n")
    .map((l) => l.trim())
    .filter(Boolean);
  const h = lines.length;
  const w = fixedW || Math.max(...lines.map((l) => l.length));
  const pix = new Uint8Array(w * h * 4);
  for (let y = 0; y < h; y++) {
    const line = lines[y];
    for (let x = 0; x < w; x++) {
      const ch = line[x] || "_";
      const c = PAL[ch] || PAL._;
      const i = (y * w + x) * 4;
      pix[i] = c[0];
      pix[i + 1] = c[1];
      pix[i + 2] = c[2];
      pix[i + 3] = c[3];
    }
  }
  return { w, h, pix };
}

function scaleNearest(srcW, srcH, src, dstW, dstH) {
  const dst = new Uint8Array(dstW * dstH * 4);
  for (let dy = 0; dy < dstH; dy++) {
    const sy = Math.min(srcH - 1, Math.floor((dy / dstH) * srcH));
    for (let dx = 0; dx < dstW; dx++) {
      const sx = Math.min(srcW - 1, Math.floor((dx / dstW) * srcW));
      const si = (sy * srcW + sx) * 4;
      const di = (dy * dstW + dx) * 4;
      dst[di] = src[si];
      dst[di + 1] = src[si + 1];
      dst[di + 2] = src[si + 2];
      dst[di + 3] = src[si + 3];
    }
  }
  return dst;
}

function crc32(buf) {
  let c = ~0 >>> 0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return (~c) >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const t = Buffer.from(type, "ascii");
  const crc = Buffer.alloc(4);
  crc.writeUInt32BE(crc32(Buffer.concat([t, data])), 0);
  return Buffer.concat([len, t, data, crc]);
}

function encodePngRgba(width, height, rgba) {
  const raw = Buffer.alloc((width * 4 + 1) * height);
  let o = 0;
  for (let y = 0; y < height; y++) {
    raw[o++] = 0;
    for (let x = 0; x < width; x++) {
      const i = (y * width + x) * 4;
      raw[o++] = rgba[i];
      raw[o++] = rgba[i + 1];
      raw[o++] = rgba[i + 2];
      raw[o++] = rgba[i + 3];
    }
  }
  const zlibbed = zlib.deflateSync(raw, { level: 9 });
  const sig = Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]);
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(width, 0);
  ihdr.writeUInt32BE(height, 4);
  ihdr[8] = 8;
  ihdr[9] = 6;
  ihdr[10] = 0;
  ihdr[11] = 0;
  ihdr[12] = 0;
  return Buffer.concat([sig, chunk("IHDR", ihdr), chunk("IDAT", zlibbed), chunk("IEND", Buffer.alloc(0))]);
}

function centerOnCanvas(srcW, srcH, src, canvas = 1024, margin = 80) {
  const dst = new Uint8Array(canvas * canvas * 4);
  const scale = Math.min((canvas - 2 * margin) / srcW, (canvas - 2 * margin) / srcH);
  const dw = Math.max(1, Math.round(srcW * scale));
  const dh = Math.max(1, Math.round(srcH * scale));
  const scaled = scaleNearest(srcW, srcH, src, dw, dh);
  const ox = Math.floor((canvas - dw) / 2);
  const oy = Math.floor((canvas - dh) / 2);
  for (let y = 0; y < dh; y++) {
    for (let x = 0; x < dw; x++) {
      const si = (y * dw + x) * 4;
      const dx = ox + x;
      const dy = oy + y;
      if (dx < 0 || dy < 0 || dx >= canvas || dy >= canvas) continue;
      const di = (dy * canvas + dx) * 4;
      dst[di] = scaled[si];
      dst[di + 1] = scaled[si + 1];
      dst[di + 2] = scaled[si + 2];
      dst[di + 3] = scaled[si + 3];
    }
  }
  return dst;
}

function writeMole(filename, rows, accent) {
  const { w, h, pix } = gridToRgba(rows, accent);
  fs.writeFileSync(path.join(OUT, filename), encodePngRgba(1024, 1024, centerOnCanvas(w, h, pix)));
}

function main() {
  fs.mkdirSync(OUT, { recursive: true });

  writeMole("mole_team_a_idle.png", MOLE_IDLE, ACCENT_TEAM_A);
  writeMole("mole_team_b_idle.png", MOLE_IDLE, ACCENT_TEAM_B);
  writeMole("mole_team_a_aim.png", MOLE_AIM, ACCENT_TEAM_A);
  writeMole("mole_team_b_aim.png", MOLE_AIM, ACCENT_TEAM_B);
  writeMole("mole_team_a_walk_1.png", MOLE_WALK1, ACCENT_TEAM_A);
  writeMole("mole_team_a_walk_2.png", MOLE_WALK2, ACCENT_TEAM_A);
  writeMole("mole_team_b_walk_1.png", MOLE_WALK1, ACCENT_TEAM_B);
  writeMole("mole_team_b_walk_2.png", MOLE_WALK2, ACCENT_TEAM_B);

  const rkt = parseGrid(ROCKET_ASC, 19);
  fs.writeFileSync(path.join(OUT, "rocket.png"), encodePngRgba(1024, 1024, centerOnCanvas(rkt.w, rkt.h, rkt.pix)));

  const gr = parseGrid(GRENADE_ASC, 21);
  fs.writeFileSync(path.join(OUT, "grenade.png"), encodePngRgba(1024, 1024, centerOnCanvas(gr.w, gr.h, gr.pix)));

  fs.writeFileSync(
    path.join(OUT, "ui_icon_rocket.png"),
    encodePngRgba(128, 128, scaleNearest(rkt.w, rkt.h, rkt.pix, 128, 128))
  );
  fs.writeFileSync(
    path.join(OUT, "ui_icon_grenade.png"),
    encodePngRgba(128, 128, scaleNearest(gr.w, gr.h, gr.pix, 128, 128))
  );

  const windAsc = `
___________BBBBBBBBB___________
__________BOOOOOOOOOB__________
_________BOOOOOOOOOOOB_________
________BOOOOBBBBOOOOOB________
_______BOOOOBBBBBBBOOOOB_______
______BOOOOBBBBBBBBBOOOOB______
_____BOOOOBBBBBBBBBBBOOOOB_____
____BOOOOBBBBBBBBBBBBBOOOOB____
___BOOOOBBBBBBBBBBBBBBBOOOOB___
__BOOOOBBBBBBBBBBBBBBBBBOOOOB__
_BOOOOBBBBBBBBBBBBBBBBBBBOOOOB_
BOOOOBBBBBBBBBBBBBBBBBBBBBOOOOB
BOOOOBBBBBBBBBBBBBBBBBBBBBOOOOB
BOOOOBBBBBBBBBBBBBBBBBBBBBOOOOB
_BOOOOBBBBBBBBBBBBBBBBBBBOOOOB_
__BOOOOBBBBBBBBBBBBBBBBBOOOOB__
___BOOOOBBBBBBBBBBBBBBBOOOOB___
____BOOOOBBBBBBBBBBBBBOOOOB____
_____BOOOOBBBBBBBBBBBOOOOB_____
______BOOOOBBBBBBBBBOOOOB______
_______BOOOOBBBBBBBBOOOOB_______
________BOOOOBBBBOOOOOB________
_________BOOOOOOOOOOOB_________
__________BOOOOOOOOOB__________
___________BBBBBBBBB___________
`;
  const wind = parseGrid(windAsc, 31);
  fs.writeFileSync(
    path.join(OUT, "ui_icon_wind.png"),
    encodePngRgba(128, 128, scaleNearest(wind.w, wind.h, wind.pix, 128, 128))
  );
}

main();
