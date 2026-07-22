# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

Single-page static menu site for Vainilla, a pâtisserie in Mérida, Venezuela. Everything lives in `index.html` — one `<style>` block, one `<script>` block, no build step, no dependencies, no tests. Preview with `python3 -m http.server`. Deployed by GitHub Pages from `main` (root); every merge to `main` publishes.

**Hard constraint:** customers browse from Venezuela on slow connections and often old devices. Keep the page light (HTML is ~47 KB), keep the WebP + PNG `<picture>` fallbacks, keep `xlink:href` alongside `href` on SVG `<use>`, and don't add heavy JS or external dependencies.

## Architecture

- **Two tab panels** on one page: `<body data-menu="diaria|encargo">` toggles visibility of `.solo-diaria` / `.solo-encargo` (both `<main>` elements and their category navs) via CSS. `setMenu()` / `cambiarMenu()` in the script are the only JS. Deep link: `#encargo`.
- **Sections** are `<section class="bloque" id="...">` with an `<h2 class="titulo-xl">`. Backgrounds alternate between white, `bloque-rosa-claro`, `bloque-rosa` (brunch) and `bloque-negro` (café) — when adding/removing/reordering sections, preserve the alternation so adjacent sections never share a background.
- **Category navs** (`.cats` inside the sticky selector) must stay in sync with the section ids of each tab. Text is lowercase in markup; CSS uppercases it.
- **Item patterns**: `.items > .item` rows (name/desc left, price right) for lists; `.cards > .card` for the Pâtisserie photo cards; `.cards-media` (photo circle + `.tabla-precios` dotted-leader rows) for single-product sections (Primavera, Matilda, Cheesecake, Pavlova, Tres leches, Profiteroles, Perritos). Follow the existing pattern when adding products — one product per line, no grouped multi-product rows.
- **Colors exist only in `:root`** — the base palette plus derived tints (`--negro-70`, `--blanco-65`, `--rosa-velo`, …). Never write raw hex/rgba in rules; add a token if a new tint is needed. Same for typography: the shared display-caps recipe lives in one grouped rule (`.titulo-xl,.btn,.tab,...`).
- **No inline `style=` attributes** — the codebase was deliberately cleaned of them; use classes.

## Images

- Mafer's originals (2251 px PNG cutouts with alpha, ~3 MB each) live in `assets/originales/`, which is **gitignored** — they exist only on the local machine; never commit them.
- Web versions in `assets/` are 800×800: WebP (`cwebp -q 82 -m 6 -resize 800 800`) plus a 256-color quantized PNG fallback (Pillow `quantize(colors=256, method=FASTOCTREE)`), referenced via `<picture>` with `loading="lazy"` and `width`/`height` set.
- Photos are transparent cutouts — JPEG is not an option.
- The tres-leches web asset differs from its original: the pink container tint was removed by color flood-fill (see commit history for the script).

## Workflow and content

- Content decisions come from Mafer (the owner) and are tracked in GitHub issue #1; feedback arrives in rounds. Content is in Spanish; prices use comma decimals (`$2,50`).
- Work on a branch, open a PR to `main` with `gh`, merge when the user says so (rebase-merge preferred). Commit style: lowercase imperative summary.
- The carta diaria deliberately has no photos or product popups — Mafer's decision; don't reintroduce them unless she asks. The old popup/modal code lives in git history.
- Untracked scratch files in the repo root (`vainilla-*.html`, `menu-*.pdf`) are drafts/sources — leave them untracked.
