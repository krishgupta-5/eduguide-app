// Usage: node generate.mjs <directions.json> <outDir>
// One-pass batch of six candidates (A1..C2) via Pollinations. Key comes from POLLINATIONS_KEY only.
import fs from 'node:fs';
import path from 'node:path';

const [, , cfgPath, outDir = 'brand/candidates'] = process.argv;
if (!cfgPath) throw new Error('usage: node generate.mjs <directions.json> <outDir>');
if (!process.env.POLLINATIONS_KEY) throw new Error('Set POLLINATIONS_KEY first');

const cfg = JSON.parse(fs.readFileSync(cfgPath, 'utf8'));
const MODEL = process.env.IMAGE_MODEL || cfg.model || 'openai/gpt-image-2';
const BG = cfg.background || 'solid very dark charcoal (#111111)';
const MARK = cfg.mark || 'off-white (#F4F4F0)';
const ACCENT = cfg.accent || 'emerald green (#10B981)';
fs.mkdirSync(outDir, { recursive: true });

const tweaks = cfg.tweaks || { 1: 'slightly wider proportions', 2: 'slightly more compact proportions' };
const variants = Object.keys(cfg.directions).flatMap((d, i) => [
  [`${d}1`, d, tweaks[1], (i + 1) * 10 + 1],
  [`${d}2`, d, tweaks[2], (i + 1) * 10 + 2],
]);

const prompt = (subject, tweak) => `Create one complete full-bleed 1:1 square image.
Background: fill the entire square with ${BG}. Keep it visible in every open area and in all four corners.
Subject: place one extremely simplified ${subject} on the background (${tweak}), reduced to one strong continuous silhouette and one defining feature.
Complexity: use only 4-7 large basic geometric shapes and at most two broad internal color regions. Remove every nonessential line, outline, anatomical detail, texture, and decoration. Keep it readable at 32 x 32.
Color behavior: use exactly three colors in the complete image: ${MARK}, ${ACCENT}, and the background. Keep the subject and background clearly separated.
Composition: keep the subject upright, perfectly centered and symmetric, filling about 62% of the square with even empty space on all sides. Preserve both members of any paired feature.
Style: raw, severe, confident, technical and premium. Bold, sharp, clean flat geometry with crisp straight edges. Not cute, not cartoon, not a mascot, no eyes with pupils, no smile.
Finish: show only the subject on the full-canvas background, with clean surfaces and normal square outer corners.
Constraints: Use no text, letters or watermark. Add no borders, frames, cards, rounded tiles, or presentation masks. One subject only, no scenery. No glow, no gradients, no photorealistic material, no bevel, no strong three-dimensional rendering, no cast shadow. Keep the background solid and uniform, with no texture, vignette, or lighting variation.`;

async function gen([label, dir, tweak, seed]) {
  const text = prompt(cfg.directions[dir], tweak);
  const url = `https://gen.pollinations.ai/image/${encodeURIComponent(text)}?model=${encodeURIComponent(MODEL)}&width=1024&height=1024&seed=${seed}&nologo=true`;
  try {
    const res = await fetch(url, { headers: { Authorization: `Bearer ${process.env.POLLINATIONS_KEY}` } });
    const buf = Buffer.from(await res.arrayBuffer());
    if (!res.ok || !(res.headers.get('content-type') || '').startsWith('image/'))
      return `${label} ERROR ${res.status}: ${buf.toString('utf8').slice(0, 300)}`;
    fs.writeFileSync(path.join(outDir, `${label}.png`), buf);
    fs.writeFileSync(path.join(outDir, `${label}.prompt.txt`), `model: ${MODEL}\nseed: ${seed}\n\n${text}`);
    return `${label} saved (${buf.length} bytes)`;
  } catch (e) {
    return `${label} ERROR ${e.message}`;
  }
}

// Optional 3rd arg: comma-separated labels (e.g. "A1,A2,C2") to generate only those.
// CONCURRENCY=1 runs serially, for providers that cap in-flight requests.
const only = (process.argv[4] || '').split(',').filter(Boolean);
const todo = only.length ? variants.filter(([label]) => only.includes(label)) : variants;
const CONCURRENCY = Number(process.env.CONCURRENCY || 3);

const results = [];
for (let i = 0; i < todo.length; i += CONCURRENCY)
  results.push(...(await Promise.all(todo.slice(i, i + CONCURRENCY).map(gen))));
console.log(`model: ${MODEL}\n` + results.join('\n'));
