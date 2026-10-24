// Usage: node make-mark.cjs <candidate.png> <out logo-mark.png>
// Removes the dark background, crops tightly to the mark, centers it on a 512x512 transparent square.
// Also writes <out dir>/../brand/logo-mark-preview.png (mark on black) for a visual check.
const path = require('path');
const sharp = require(require.resolve('sharp', { paths: [process.cwd()] }));

const [, , SRC, OUT = 'public/logo-mark.png'] = process.argv;
if (!SRC) throw new Error('usage: node make-mark.cjs <candidate.png> <out.png>');
const PREVIEW = path.join(process.cwd(), 'brand', 'logo-mark-preview.png');

(async () => {
  const { data, info } = await sharp(SRC).removeAlpha().raw().toBuffer({ resolveWithObject: true });
  const { width, height } = info;
  const rgba = Buffer.alloc(width * height * 4);
  let minX = width, minY = height, maxX = -1, maxY = -1;
  for (let y = 0; y < height; y++) {
    for (let x = 0; x < width; x++) {
      const s = (y * width + x) * 3, d = (y * width + x) * 4;
      const r = data[s], g = data[s + 1], b = data[s + 2];
      // Dark background -> transparent; ramp between brightness 45 and 110 keeps edges smooth.
      const a = Math.max(0, Math.min(255, Math.round(((Math.max(r, g, b) - 45) / 65) * 255)));
      rgba[d] = r; rgba[d + 1] = g; rgba[d + 2] = b; rgba[d + 3] = a;
      if (a > 128) { minX = Math.min(minX, x); maxX = Math.max(maxX, x); minY = Math.min(minY, y); maxY = Math.max(maxY, y); }
    }
  }
  const pad = 6;
  const left = Math.max(0, minX - pad), top = Math.max(0, minY - pad);
  const box = { left, top, width: Math.min(width, maxX + pad + 1) - left, height: Math.min(height, maxY + pad + 1) - top };
  const mark = await sharp(rgba, { raw: { width, height, channels: 4 } })
    .extract(box)
    .resize(512, 512, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png().toBuffer();
  await sharp(mark).toFile(OUT);
  await sharp({ create: { width: 512, height: 512, channels: 4, background: '#000000' } })
    .composite([{ input: mark }]).png().toFile(PREVIEW);
  console.log('mark bbox', box, '->', OUT, '| preview', PREVIEW);
})();
