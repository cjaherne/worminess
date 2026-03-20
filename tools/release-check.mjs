/**
 * Lightweight release gate: required paths exist (LÖVE has no compile step).
 */
import fs from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const root = path.join(__dirname, "..");

const required = [
  "main.lua",
  "conf.lua",
  "src/app.lua",
  "src/scenes/play.lua",
  "src/sim/world.lua",
  "src/sim/weapons/rocket.lua",
  "src/sim/weapons/grenade.lua",
];

let ok = true;
for (const rel of required) {
  const p = path.join(root, rel);
  if (!fs.existsSync(p)) {
    console.error("missing:", rel);
    ok = false;
  }
}
if (!ok) process.exit(1);
console.log("release check ok");
