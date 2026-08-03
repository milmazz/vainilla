# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Single-page static menu site for Vainilla, a pâtisserie in Mérida, Venezuela. Everything lives in `index.html` — one `<style>` block, one `<script>` block, no build step, no dependencies, no tests. The only other served files are `sw.js` (offline cache) and `_headers` (Cloudflare cache policy). Preview with `python3 -m http.server`. Deployed from `main` (root); every merge to `main` publishes.

**Hard constraint:** customers browse from Venezuela on slow connections and often old devices. Keep the page light (HTML is ~49 KB), keep the WebP + PNG `<picture>` fallbacks, keep `xlink:href` alongside `href` on SVG `<use>`, and don't add heavy JS or external dependencies. The one allowed external connection is the Adobe Fonts kit (`use.typekit.net/lge4vai.css`) that serves Brandon Grotesque Medium/Bold — loaded async (`media="print"` swap) so it never blocks render; Josefin Sans (self-hosted) is the fallback. Don't add more external origins.

## Architecture

- **Three tab panels** on one page: `<body data-menu="diaria|encargo|minidulces">` toggles visibility of `.solo-diaria` / `.solo-encargo` / `.solo-minidulces` (the tabpanel divs inside the single `<main>`, plus the category navs) via CSS. `setMenu()` / `cambiarMenu()` in the script are the only JS. Deep links: `#encargo`, `#minidulces`.
- **Sections** are `<section class="bloque" id="...">` with an `<h2 class="titulo-xl">`. Backgrounds alternate between white, `bloque-rosa-claro`, `bloque-rosa` (brunch) and `bloque-negro` (café) — when adding/removing/reordering sections, preserve the alternation so adjacent sections never share a background.
- **Category navs** (`.cats` inside the sticky selector) must stay in sync with the section ids of each tab. Text is lowercase in markup; CSS uppercases it. The mini dulces tab has no `.cats` nav — it's a single section (`#minidulces`); add one if it ever grows to several sections.
- **Item patterns**: `.items > .item` rows (name/desc left, price right) for lists; `.cards > .card` for the Pâtisserie photo cards; `.cards-media` (photo circle + `.tabla-precios` dotted-leader rows) for single-product sections (Primavera, Matilda, Cheesecake, Pavlova, Tres leches, Profiteroles, Perritos). Follow the existing pattern when adding products — one product per line, no grouped multi-product rows.
- **Colors exist only in `:root`** — the base palette plus derived tints (`--negro-70`, `--blanco-65`, `--rosa-velo`, …). Never write raw hex/rgba in rules; add a token if a new tint is needed. Same for typography: the shared display-caps recipe lives in one grouped rule (`.titulo-xl,.btn,.tab,...`).
- **No inline `style=` attributes** — the codebase was deliberately cleaned of them; use classes.

## Images

- Mafer's originals (2251 px PNG cutouts with alpha, ~3 MB each) live in `assets/originales/`, which is **gitignored** — they exist only on the local machine; never commit them.
- Web versions in `assets/` are 800×800: WebP (`cwebp -q 82 -m 6 -resize 800 800`) plus a 256-color quantized PNG fallback (Pillow `quantize(colors=256, method=FASTOCTREE)`), referenced via `<picture>` with `loading="lazy"` and `width`/`height` set.
- Photos are transparent cutouts — JPEG is not an option.
- The tres-leches web asset differs from its original: the pink container tint was removed by color flood-fill (see commit history for the script).

## Deploy and caching

- **Host: Cloudflare Pages**, connected to this repo, no build command, output directory `/`. It replaced GitHub Pages for three reasons that matter on Venezuelan networks: HTTP/3 (QUIC survives packet loss without head-of-line blocking), Brotli, and configurable cache headers. GitHub Pages served everything with a fixed `max-age=600` and no HTTP/3.
- **`_headers`** sets the cache policy: HTML revalidates every load (price changes are instant), fonts get a year, `/assets/*` gets 30 days, `/sw.js` is never cached. Paths are deliberately non-overlapping — Cloudflare merges headers when several rules match one URL, so overlapping rules produce a garbled `Cache-Control`. The one remaining overlap (`/assets/fonts/*` vs `/assets/*`) degrades safely to 30 days. **This file only does anything on Cloudflare** — GitHub Pages just serves it as a text file.
- **`sw.js`** is the offline cache. `/assets/*` is stale-while-revalidate (instant paint, refreshes in the background); the HTML is network-first with the last good copy as the offline fallback. `respondWith` and `waitUntil` must both be called synchronously in the fetch handler — moving `waitUntil` inside a `.then()` risks the browser rejecting it once the event goes inactive.
- **Changing a photo:** because assets are cached for 30 days and the filename carries no content hash, a replaced photo can take up to 30 days to reach someone who already has it. If a change needs to be live immediately, rename the file (`matilda-2.webp`) and update the `<picture>` — a new URL sidesteps every cache layer. Only bump `CACHE` in `sw.js` if the caching *strategy* changes; stale-while-revalidate already self-heals ordinary content edits.
- A registered service worker persists on the domain. Removing the feature means shipping a `sw.js` that calls `registration.unregister()`, not deleting the file.
- Testing the worker needs a real browser driven over CDP — `chrome --dump-dom` exits before the `load` handler registers anything and writes no profile, so it silently "passes" while testing nothing. The only trustworthy check is to kill the origin server and reload, with a never-cached URL as a negative control.

## Workflow and content

- Content decisions come from Mafer (the owner) and arrive in rounds of feedback. Content is in Spanish; prices use comma decimals (`$2,50`). The original round of pendings was tracked in issue #1, now closed — ask her directly rather than looking for an open tracking issue.
- Work on a branch, open a PR to `main` with `gh`, merge when the user says so (rebase-merge preferred). Commit style: lowercase imperative summary.
- The carta diaria deliberately has no photos or product popups — Mafer's decision; don't reintroduce them unless she asks. The old popup/modal code lives in git history.
- Untracked scratch files in the repo root (`vainilla-*.html`, `menu-*.pdf`) are drafts/sources — leave them untracked.
