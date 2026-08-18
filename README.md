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
scripts/generar-fotos.sh matilda pavlova
```

Saca el WebP (`cwebp -q 82`) y el PNG de respaldo cuantizado a 256 colores. Acepta
varios nombres de una vez, con o sin `.png`.

El HTML las referencia con `<picture>`: WebP + fallback PNG para dispositivos viejos.

## Iconos

Hay dos SVG fuente. `favicon.svg` es fiel al logo de Instagram; `assets/favicon-16-32.svg`
lleva el trazo engrosado porque el del logo (2,3 % del diámetro) mide 0,37 px a 16 px y
se convierte en una mancha gris.

```sh
scripts/generar-iconos.sh
```

Saca `favicon.ico` (con 16 y 32 dentro, cada uno renderizado a su resolución nativa) y
`apple-touch-icon.png`. Además comprueba tres cosas y falla si alguna no cuadra: que la
marca no toque el borde del círculo, que el ICO lleve los dos tamaños y que los cuatro
archivos no pasen de 4 KB.

Se usa Pillow y no ImageMagick a propósito: el `convert` de esta máquina es de otra
arquitectura y aborta con `bad CPU type`. Pillow ya es dependencia de las fotos.

## Imagen para compartir (Open Graph)

`assets/og.png` (1200×630) es la tarjeta que sale al pegar el enlace en WhatsApp, Instagram
o Messenger: la marca sola, el círculo con la "V" y la rayita, VAINILLA y la bajada. Antes no
había ninguna y el rastreador escogía por su cuenta la primera foto grande de la carta (la
torta de chocolate).

```sh
scripts/generar-og.sh
```

El diseño vive dentro del script, no en un SVG aparte: los textos se convierten a trazos
leyendo los subsets de `assets/fonts/`, así que rsvg no depende de las fuentes instaladas y
el resultado sale igual en cualquier máquina. Ojo con que los subsets son variables (eje
`wght` 100..700) y su instancia por defecto es la Thin: hay que instanciarlos al peso real
o la palabra sale en hilo.

Comprueba cuatro cosas y falla si alguna no cuadra: que sea 1200×630, que no lleve
transparencia (varios rastreadores la componen sobre negro), que toda la marca quepa en el
cuadrado central de 630 —WhatsApp recorta la vista previa cuando el chat es estrecho— y que
no pase de 80 KB.

Facebook y WhatsApp cachean la tarjeta por URL. Si cambia el diseño y hace falta que se vea
ya, hay que renombrarla (`og-2.png`) y actualizar las `og:image` del HTML.

## Deploy

Cloudflare Pages publica la rama `main` automáticamente (sin build, directorio raíz). Los cambios se hacen por PR.

Se eligió Cloudflare sobre GitHub Pages por tres cosas que pesan en las conexiones venezolanas: **HTTP/3** (QUIC aguanta la pérdida de paquetes sin bloquear todas las descargas a la vez), **Brotli** y **cabeceras de caché configurables**. GitHub Pages servía todo con `max-age=600` fijo y sin HTTP/3.

- `_headers` — política de caché: el HTML revalida siempre (los precios salen al instante), las fuentes duran un año, las fotos 30 días.
- `sw.js` — caché sin conexión: la carta se abre al instante en visitas repetidas y sigue funcionando sin señal, que es justo el caso de alguien en la tienda con mala cobertura.

Si hay que cambiar una foto y que se vea ya, conviene renombrarla (`matilda-2.webp`): una URL nueva se salta las 4 semanas de caché.
