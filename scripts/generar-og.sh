#!/usr/bin/env bash
#
# Genera assets/og.png, la imagen que sale al compartir el enlace en WhatsApp,
# Instagram, Messenger o Telegram (Open Graph).
#
#   scripts/generar-og.sh
#
# Sin esta imagen los rastreadores agarran la primera foto grande de la página
# —la torta de chocolate— en vez de la marca. La tarjeta es la marca sola:
# el círculo con la "V" y la rayita, la palabra VAINILLA y la bajada.
#
# El diseño vive aquí, en el propio script, no en un SVG aparte: los textos se
# convierten a trazos leyendo las fuentes de assets/fonts/, así que un SVG
# suelto no se podría volver a editar como texto de todos modos. Con los textos
# en trazos, rsvg no depende de las fuentes instaladas en la máquina y el
# resultado es idéntico en cualquier parte.
#
# Los subsets self-hosted son variables (eje wght 100..700) y su instancia por
# defecto es la Thin: hay que instanciarlos al peso real o la palabra sale en
# hilo. Eso es lo que hace fontTools aquí; en el navegador lo hace font-weight.
#
# JPEG no se usa: son colores planos, el PNG cuantizado pesa la mitad y no
# ensucia los bordes. WebP tampoco: WhatsApp y Facebook no lo previsualizan.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

command -v rsvg-convert >/dev/null || { echo "falta rsvg-convert (librsvg)" >&2; exit 1; }
python3 -c "import PIL"      2>/dev/null || { echo "falta Pillow" >&2; exit 1; }
python3 -c "import fontTools" 2>/dev/null || { echo "falta fonttools" >&2; exit 1; }
python3 -c "import brotli"    2>/dev/null || { echo "falta brotli (fonttools lo necesita para woff2)" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

python3 - "$TMP/og.svg" <<'PY'
import sys
from fontTools.ttLib import TTFont
from fontTools.varLib import instancer
from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.misc.transform import Transform

# la paleta es la misma de :root en index.html
ROSA_CLARO = "#FCE3EB"; ROSA = "#F4A7C2"; FRAMBUESA = "#C9578A"
NEGRO = "#161216"; TINTA = "#54484D"; BLANCO = "#FFFFFF"

DISPLAY = "assets/fonts/josefin-sans-700.woff2"   # sustituta de Brandon Grotesque
TEXTO   = "assets/fonts/karla-400.woff2"

ANCHO, ALTO = 1200, 630
CX = ANCHO / 2

_fuentes = {}
def fuente(ruta, peso):
    if (ruta, peso) not in _fuentes:
        f = TTFont(ruta)
        if "fvar" in f:                  # instancia al peso real; si no, sale la Thin
            f = instancer.instantiateVariableFont(f, {"wght": peso}, updateFontNames=False)
        _fuentes[(ruta, peso)] = f
    return _fuentes[(ruta, peso)]

def linea(ruta, peso, texto, tam, tracking, base, color):
    """Una línea de texto centrada, convertida a trazos. Devuelve (svg, izq, der)."""
    f = fuente(ruta, peso)
    upem = f["head"].unitsPerEm; cmap = f.getBestCmap(); hmtx = f["hmtx"]; glifos = f.getGlyphSet()
    esc = tam / upem; sep = tracking * tam
    nombres = [cmap[ord(c)] for c in texto]
    anchos  = [hmtx[n][0] * esc for n in nombres]
    total = sum(anchos) + sep * (len(texto) - 1)
    x = izq = CX - total / 2
    trazo = SVGPathPen(glifos, ntos=lambda v: f"{v:.1f}")
    for nombre, avance in zip(nombres, anchos):
        # el eje Y de las fuentes va hacia arriba y el del SVG hacia abajo: -esc
        glifos[nombre].draw(TransformPen(trazo, Transform(esc, 0, 0, -esc, x, base)))
        x += avance + sep
    return f'<path fill="{color}" d="{trazo.getCommands()}"/>', izq, izq + total

piezas = []   # (svg, izq, der) — los extremos sirven para la comprobación del recorte

# La marca es el mismo dibujo de favicon.svg (viewBox 0 0 100 100), sin tocar
# proporciones: círculo negro, "V" blanca y la rayita debajo.
R, CYM = 96, 168
piezas.append((
    f'<g transform="translate({CX-R} {CYM-R}) scale({2*R/100})">'
    f'<circle cx="50" cy="50" r="50" fill="{NEGRO}"/>'
    f'<path d="M27.00 22.79 L50 68.79 L73.00 22.79" fill="none" stroke="{BLANCO}" stroke-width="2.3"/>'
    f'<path d="M36.43 76.06 L63.57 76.06" fill="none" stroke="{BLANCO}" stroke-width="2.3"/></g>',
    CX - R, CX + R))

piezas.append(linea(DISPLAY, 700, "VAINILLA", 96, .04, 385, NEGRO))
piezas.append(linea(DISPLAY, 700, "MACARONS & ALTA PASTELERÍA", 24, .26, 440, FRAMBUESA))

# guiños al borde punteado del hero. 11 rayas de 9 con huecos de 8 = 179 px justos,
# así empieza y termina en raya en vez de cortarse a medias.
RAYA = 179
piezas.append((f'<path d="M{CX-RAYA/2} 476 H{CX+RAYA/2}" stroke="{ROSA}" stroke-width="3" '
               f'stroke-dasharray="9 8"/>', CX - RAYA/2, CX + RAYA/2))

piezas.append(linea(TEXTO, 400, "Mérida · Venezuela", 24, .02, 520, TINTA))

svg = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{ANCHO}" height="{ALTO}" '
       f'viewBox="0 0 {ANCHO} {ALTO}">'
       f'<rect width="{ANCHO}" height="{ALTO}" fill="{ROSA_CLARO}"/>'
       + "".join(p[0] for p in piezas) + '</svg>')
open(sys.argv[1], "w").write(svg)
PY

rsvg-convert -w 1200 -h 630 "$TMP/og.svg" -o "$TMP/og.png"

python3 - "$TMP/og.png" <<'PY'
import sys
from PIL import Image

# sin alfa: varios rastreadores componen la transparencia sobre negro y la
# tarjeta saldría con un halo. Colores planos → 64 entradas sobran.
im = Image.open(sys.argv[1]).convert("RGBA")
fondo = Image.new("RGB", im.size, "#FCE3EB")
fondo.paste(im, mask=im.split()[3])
fondo.quantize(colors=64, method=Image.FASTOCTREE).save("assets/og.png", optimize=True)
PY

# --- verificación -----------------------------------------------------------
python3 - <<'PY'
import os, sys
from PIL import Image

fallos = []
im = Image.open("assets/og.png")
print(f"assets/og.png  {im.size}  modo {im.mode}")

if im.size != (1200, 630):
    fallos.append("la imagen no es 1200x630 (la proporción 1.91:1 que piden Open Graph y WhatsApp)")
if im.mode in ("RGBA", "LA") or "transparency" in im.info:
    fallos.append("la imagen tiene transparencia; varios rastreadores la componen sobre negro")

# WhatsApp recorta la vista previa a algo casi cuadrado cuando el chat es
# estrecho. Toda la marca tiene que caber en el cuadrado central de 630.
rgb = im.convert("RGB")
px = rgb.load()
fondo = px[5, 5]
izq, der = 1200, 0
for y in range(630):
    for x in range(1200):
        if px[x, y] != fondo:
            izq = min(izq, x); der = max(der, x)
print(f"tinta de x={izq} a x={der}; el cuadrado central va de 285 a 915")
if izq < 285 or der > 915:
    fallos.append("la marca se sale del cuadrado central: WhatsApp la recortaría")

peso = os.path.getsize("assets/og.png")
print(f"pesa {peso} B")
if peso > 81920:
    fallos.append(f"pesa {peso} B; por encima de 80 KB no vale la pena para una tarjeta de colores planos")

if fallos:
    print("\nFALLOS:", file=sys.stderr)
    for f in fallos:
        print("  -", f, file=sys.stderr)
    sys.exit(1)
print("\ntodo correcto")
PY

echo
echo "Recuerda: Facebook y WhatsApp cachean la tarjeta por URL. Si cambia el diseño"
echo "y hace falta que se vea ya, renómbrala (og-2.png) y actualiza las meta del HTML."
