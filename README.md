# Vainilla

Sitio del menú de [Vainilla](https://vainillamacarons.com/), pâtisserie boutique en Mérida, Venezuela — macarons, tortas, brunch y café. Pedidos por WhatsApp.

Una sola página estática (`index.html`, CSS y JS incluidos) con tres cartas en pestañas: **carta diaria**, **tortas bajo pedido** y **mini dulces bajo pedido** (bandejas para eventos). Optimizada para conexiones lentas: ~49 KB de HTML y fotos WebP de ~62 KB con carga diferida.

## Desarrollo

No hay build. Para previsualizar:

```sh
python3 -m http.server   # → http://localhost:8000
```

## Fotos

Los originales (2251 px) viven en `assets/originales/` (fuera del repo). Las versiones web se generan a 800 px:

```sh
cwebp -q 82 -m 6 -resize 800 800 assets/originales/FOTO.png -o assets/FOTO.webp
python3 -c "from PIL import Image; im=Image.open('assets/originales/FOTO.png').convert('RGBA').resize((800,800), Image.LANCZOS); im.quantize(colors=256, method=Image.FASTOCTREE).save('assets/FOTO.png', optimize=True)"
```

El HTML las referencia con `<picture>`: WebP + fallback PNG para dispositivos viejos.

## Iconos

Hay dos SVG fuente. `favicon.svg` es fiel al logo de Instagram; `assets/favicon-16-32.svg`
lleva el trazo engrosado porque el del logo (2,3 % del diámetro) mide 0,37 px a 16 px y
se convierte en una mancha gris. De ellos salen los tres archivos servidos:

```sh
TMP=$(mktemp -d)
rsvg-convert -w 16  -h 16  assets/favicon-16-32.svg -o "$TMP/f16.png"
rsvg-convert -w 32  -h 32  assets/favicon-16-32.svg -o "$TMP/f32.png"
rsvg-convert -w 180 -h 180 favicon.svg              -o "$TMP/a180.png"
python3 - "$TMP" <<'PY'
import sys, os
from PIL import Image
tmp = sys.argv[1]
i16 = Image.open(os.path.join(tmp, "f16.png")).convert("RGBA")
i32 = Image.open(os.path.join(tmp, "f32.png")).convert("RGBA")
i32.save("favicon.ico", format="ICO", append_images=[i16], sizes=[(32,32),(16,16)])
a = Image.open(os.path.join(tmp, "a180.png")).convert("RGBA")
fondo = Image.new("RGB", a.size, "#1E1E1E")      # opaco: iOS aplica su propia máscara
fondo.paste(a, mask=a.split()[3])
fondo.quantize(colors=16, method=Image.FASTOCTREE).save("apple-touch-icon.png", optimize=True)
PY
rm -rf "$TMP"
```

Se usa Pillow y no ImageMagick a propósito: el `convert` de esta máquina es de otra
arquitectura y aborta con `bad CPU type`. Pillow ya es dependencia de las fotos.

## Deploy

Cloudflare Pages publica la rama `main` automáticamente (sin build, directorio raíz). Los cambios se hacen por PR.

Se eligió Cloudflare sobre GitHub Pages por tres cosas que pesan en las conexiones venezolanas: **HTTP/3** (QUIC aguanta la pérdida de paquetes sin bloquear todas las descargas a la vez), **Brotli** y **cabeceras de caché configurables**. GitHub Pages servía todo con `max-age=600` fijo y sin HTTP/3.

- `_headers` — política de caché: el HTML revalida siempre (los precios salen al instante), las fuentes duran un año, las fotos 30 días.
- `sw.js` — caché sin conexión: la carta se abre al instante en visitas repetidas y sigue funcionando sin señal, que es justo el caso de alguien en la tienda con mala cobertura.

Si hay que cambiar una foto y que se vea ya, conviene renombrarla (`matilda-2.webp`): una URL nueva se salta las 4 semanas de caché.
