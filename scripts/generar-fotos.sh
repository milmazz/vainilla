#!/usr/bin/env bash
#
# Genera las versiones web de una o varias fotos: WebP + PNG de respaldo, 800x800.
# Los originales (2251 px, con alfa) viven en assets/originales/, fuera del repo.
#
#   scripts/generar-fotos.sh matilda
#   scripts/generar-fotos.sh matilda pavlova torta-de-limon
#
# Las fotos son recortes con transparencia, así que JPEG no es una opción.

set -euo pipefail

RAIZ="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ORIGINALES="$RAIZ/assets/originales"
DESTINO="$RAIZ/assets"
LADO=800

if [ $# -eq 0 ]; then
  cat >&2 <<AYUDA
uso: $(basename "$0") NOMBRE [NOMBRE...]

  NOMBRE va sin extensión; el original debe estar en
  assets/originales/NOMBRE.png

  ejemplo: $(basename "$0") matilda pavlova
AYUDA
  exit 1
fi

command -v cwebp >/dev/null || { echo "falta cwebp (webp)" >&2; exit 1; }
python3 -c "import PIL" 2>/dev/null || { echo "falta Pillow" >&2; exit 1; }

if [ ! -d "$ORIGINALES" ]; then
  echo "no existe $ORIGINALES — los originales no están en esta máquina" >&2
  exit 1
fi

for nombre in "$@"; do
  nombre="${nombre%.png}"                 # tolerar que pasen el .png
  origen="$ORIGINALES/$nombre.png"

  if [ ! -f "$origen" ]; then
    echo "no existe $origen" >&2
    exit 1
  fi

  cwebp -quiet -q 82 -m 6 -resize "$LADO" "$LADO" "$origen" -o "$DESTINO/$nombre.webp"

  python3 - "$origen" "$DESTINO/$nombre.png" "$LADO" <<'PY'
import sys
from PIL import Image

origen, destino, lado = sys.argv[1], sys.argv[2], int(sys.argv[3])
im = Image.open(origen).convert("RGBA").resize((lado, lado), Image.LANCZOS)
im.quantize(colors=256, method=Image.FASTOCTREE).save(destino, optimize=True)
PY

  printf "%-24s webp %7s B   png %7s B\n" "$nombre" \
    "$(wc -c < "$DESTINO/$nombre.webp" | tr -d ' ')" \
    "$(wc -c < "$DESTINO/$nombre.png"  | tr -d ' ')"
done

echo
echo "Recuerda: el HTML las referencia con <picture> (WebP + PNG) y width/height."
echo "Si cambias una foto ya publicada y hace falta que se vea ya, renómbrala"
echo "(matilda-2.webp): una URL nueva se salta las 4 semanas de caché."
