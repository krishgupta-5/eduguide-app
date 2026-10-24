// Usage: node make-icons.cjs <logo-mark.png> <outDir> [tileHex=#11110f]
// Kado-style tile (32-unit grid, inset 1, radius 9) with the transparent mark large on a dark background.
const path = require('path');
const sharp = require(require.resolve('sharp', { paths: [process.cwd()] }));

const [, , MARK, OUT = 'public', HEX = '#11110f'] = process.argv;
if (!MARK) throw new Error('usage: node make-icons.cjs <logo-mark.png> <outDir> [tileHex]');
const n = parseInt(HEX.replace('#', ''), 16);
const BG = { r: (n >> 16) & 255, g: (n >> 8) & 255, b: n & 255, alpha: 1 };

async function icon(size, file, scale, rounded) {
  const inner = Math.round(size * scale);
  let mark = sharp(MARK).resize(inner, inner, { kernel: 'lanczos3' });
  if (size <= 48) mark = mark.sharpen({ sigma: 0.6 });
  let img = sharp({ create: { width: size, height: size, channels: 4, background: BG } })
    .composite([{ input: await mark.png().toBuffer(), gravity: 'center' }]);
  if (rounded) {
    const u = size / 32;
    const mask = Buffer.from(`<svg xmlns="http://www.w3.org/2000/svg" width="${size}" height="${size}"><rect x="${u}" y="${u}" width="${30 * u}" height="${30 * u}" rx="${9 * u}" fill="#fff"/></svg>`);
    img = sharp(await img.png().toBuffer()).composite([{ input: mask, blend: 'dest-in' }]);
  }
  await img.png().toFile(path.join(OUT, file));
  console.log(file, size);
}

(async () => {
  // The book mark is wide and fills its source canvas edge to edge. These scales push it
  // as large as possible while the page corners still clear the tile's rounded corners.
  await icon(16, 'favicon-16x16.png', 0.86, true);
  await icon(32, 'favicon-32x32.png', 0.86, true);
  await icon(48, 'favicon-48x48.png', 0.85, true);
  await icon(512, 'favicon.png', 0.82, true);
  await icon(160, 'app_icon.png', 0.82, true);
  await icon(192, 'android-chrome-192x192.png', 0.8, true);
  await icon(512, 'android-chrome-512x512.png', 0.8, true);
  await icon(180, 'apple-touch-icon.png', 0.8, false); // iOS rounds it itself; keep it opaque
})();
