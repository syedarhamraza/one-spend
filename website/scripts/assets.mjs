// Copies the real app captures and icon from the Flutter repo into public/,
// cropping the device status bar (the page draws its own) and converting to webp.
import { mkdir, stat } from "node:fs/promises";
import path from "node:path";
import sharp from "sharp";

const root = path.resolve(import.meta.dirname, "..", "..");
const captures = path.join(root, "tool", "store_graphics", "captures");
const outScreens = path.resolve(import.meta.dirname, "..", "public", "screens");
const outBrand = path.resolve(import.meta.dirname, "..", "public", "brand");

const screens = [
  "1-subscriptions", "2-upcoming", "3-trends", "4-categories",
  "5-detail", "6-reminders", "7-currency", "8-backup",
];
// Status bar height on the 1260x2800 captures.
const STATUS_BAR = 120;

async function fresh(src, dest) {
  try {
    return (await stat(dest)).mtimeMs >= (await stat(src)).mtimeMs;
  } catch {
    return false;
  }
}

await mkdir(outScreens, { recursive: true });
await mkdir(outBrand, { recursive: true });

for (const name of screens) {
  const src = path.join(captures, `${name}.png`);
  const dest = path.join(outScreens, `${name}.webp`);
  if (await fresh(src, dest)) continue;
  const img = sharp(src);
  const { width, height } = await img.metadata();
  await img
    .extract({ left: 0, top: STATUS_BAR, width, height: height - STATUS_BAR })
    .resize({ width: 720 })
    .webp({ quality: 86 })
    .toFile(dest);
}

const icon = path.join(root, "store", "play", "icon-512.png");
await sharp(icon).resize(256).png().toFile(path.join(outBrand, "icon.png"));
await sharp(icon).resize(64).png().toFile(path.join(outBrand, "favicon.png"));
await sharp(path.join(root, "store", "play", "feature-graphic.png")).png().toFile(path.join(outBrand, "og.png"));
console.log("assets ready");
