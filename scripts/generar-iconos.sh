#!/usr/bin/env bash
#
# Regenera favicon.ico y apple-touch-icon.png desde los dos SVG fuente.
#
#   scripts/generar-iconos.sh
#
# Hay dos fuentes a propósito:
#   favicon.svg               fiel al logo (marca 46 %, trazo 2,3)
#   assets/favicon-16-32.svg  engrosada (marca 54 %, trazo 8) porque el trazo
#                             del logo mide 0,37 px a 16 px y sale una mancha gris
#
# Se usa Pillow y no ImageMagick: el `convert` de esta máquina es de otra
# arquitectura y aborta con `bad CPU type`. Pillow ya hace falta para las fotos.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$RAIZ"

command -v rsvg-convert >/dev/null || { echo "falta rsvg-convert (librsvg)" >&2; exit 1; }
python3 -c "import PIL" 2>/dev/null || { echo "falta Pillow" >&2; exit 1; }

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

# cada tamaño se renderiza a su resolución nativa, no reescalando desde uno mayor
rsvg-convert -w 16  -h 16  assets/favicon-16-32.svg -o "$TMP/f16.png"
rsvg-convert -w 32  -h 32  assets/favicon-16-32.svg -o "$TMP/f32.png"
rsvg-convert -w 180 -h 180 favicon.svg              -o "$TMP/a180.png"

python3 - "$TMP" <<'PY'
import sys, os
from PIL import Image

tmp = sys.argv[1]

# ICO con los dos tamaños dentro
i16 = Image.open(os.path.join(tmp, "f16.png")).convert("RGBA")
i32 = Image.open(os.path.join(tmp, "f32.png")).convert("RGBA")
i32.save("favicon.ico", format="ICO", append_images=[i16], sizes=[(32, 32), (16, 16)])

# apple-touch-icon aplanado sobre el negro de la marca: rsvg deja las esquinas
# transparentes e iOS aplica su propia máscara de cuadrado redondeado. Como el
# círculo es de ese mismo color, el resultado es idéntico pero predecible.
a = Image.open(os.path.join(tmp, "a180.png")).convert("RGBA")
fondo = Image.new("RGB", a.size, "#1E1E1E")
fondo.paste(a, mask=a.split()[3])
fondo.quantize(colors=16, method=Image.FASTOCTREE).save("apple-touch-icon.png", optimize=True)
PY

# --- verificación -----------------------------------------------------------
python3 - <<'PY'
import subprocess, tempfile, os, math, sys
from PIL import Image, IcoImagePlugin

fallos = []

ico = IcoImagePlugin.IcoFile(open("favicon.ico", "rb"))
tam = sorted(ico.sizes())
print(f"favicon.ico           {tam}")
if tam != [(16, 16), (32, 32)]:
    fallos.append("el ICO no contiene 16 y 32")

a = Image.open("apple-touch-icon.png")
print(f"apple-touch-icon.png  {a.size} modo {a.mode}")
if a.size != (180, 180):
    fallos.append("apple-touch-icon no es 180x180")
if a.mode in ("RGBA", "LA") or "transparency" in a.info:
    fallos.append("apple-touch-icon tiene transparencia; iOS la compone de forma impredecible")

# la marca no puede tocar el borde del círculo: a 60 % de ancho se sale y el
# círculo sale recortado en las puntas. Esto lo detecta.
tmp = tempfile.mkdtemp()
for nombre, src in (("optimizada", "assets/favicon-16-32.svg"), ("fiel", "favicon.svg")):
    p = os.path.join(tmp, nombre + ".png")
    subprocess.run(["rsvg-convert", "-w", "400", "-h", "400", src, "-o", p], check=True)
    px = Image.open(p).convert("L").load()
    peor = max((math.hypot(x - 200, y - 200)
                for y in range(400) for x in range(400) if px[x, y] > 200), default=0)
    print(f"{nombre:22}punto blanco más externo {peor:5.1f} px de un radio de 200")
    if peor >= 194:
        fallos.append(f"la marca {nombre} toca o cruza el borde del círculo")

total = sum(os.path.getsize(f) for f in
            ("favicon.ico", "favicon.svg", "apple-touch-icon.png", "assets/favicon-16-32.svg"))
print(f"total de los 4 archivos {total} B")
if total > 4096:
    fallos.append(f"los iconos pesan {total} B, por encima del presupuesto de 4 KB")

if fallos:
    print("\nFALLOS:", file=sys.stderr)
    for f in fallos:
        print("  -", f, file=sys.stderr)
    sys.exit(1)
print("\ntodo correcto")
PY
