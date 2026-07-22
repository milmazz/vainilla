# Vainilla

Sitio del menú de [Vainilla](https://milmazz.uno/vainilla/), pâtisserie boutique en Mérida, Venezuela — macarons, tortas, brunch y café. Pedidos por WhatsApp.

Una sola página estática (`index.html`, CSS y JS incluidos) con dos cartas en pestañas: **carta diaria** y **tortas bajo pedido**. Optimizada para conexiones lentas: ~47 KB de HTML y fotos WebP de ~62 KB con carga diferida.

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

GitHub Pages sirve la rama `main` automáticamente. Los cambios se hacen por PR; los pendientes de contenido se rastrean en el [issue #1](https://github.com/milmazz/vainilla/issues/1).
