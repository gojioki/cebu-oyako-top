import fs from "node:fs";

const [htmlPath, imagePath, alt] = process.argv.slice(2);

if (!htmlPath || !imagePath || !alt) {
  throw new Error("Usage: node embed_character_asset.mjs <html> <png> <alt>");
}

const html = fs.readFileSync(htmlPath, "utf8");
const dataUri = `data:image/png;base64,${fs.readFileSync(imagePath).toString("base64")}`;
const escapedAlt = alt.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
const pattern = new RegExp(`(<div class="btv3-char-img"><img src=")[^"]+(" alt="${escapedAlt}")`);

if (!pattern.test(html)) {
  throw new Error(`Character image not found: ${alt}`);
}

fs.writeFileSync(htmlPath, html.replace(pattern, `$1${dataUri}$2`));
