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

## Deploy

Cloudflare Pages publica la rama `main` automáticamente (sin build, directorio raíz). Los cambios se hacen por PR.

Se eligió Cloudflare sobre GitHub Pages por tres cosas que pesan en las conexiones venezolanas: **HTTP/3** (QUIC aguanta la pérdida de paquetes sin bloquear todas las descargas a la vez), **Brotli** y **cabeceras de caché configurables**. GitHub Pages servía todo con `max-age=600` fijo y sin HTTP/3.

- `_headers` — política de caché: el HTML revalida siempre (los precios salen al instante), las fuentes duran un año, las fotos 30 días.
- `sw.js` — caché sin conexión: la carta se abre al instante en visitas repetidas y sigue funcionando sin señal, que es justo el caso de alguien en la tienda con mala cobertura.

Si hay que cambiar una foto y que se vea ya, conviene renombrarla (`matilda-2.webp`): una URL nueva se salta las 4 semanas de caché.
