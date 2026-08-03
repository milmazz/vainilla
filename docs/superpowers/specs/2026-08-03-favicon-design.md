# Favicon de Vainilla — diseño

Fecha: 2026-08-03

## Problema

El sitio no declara favicon. Todo visitante provoca una petición automática a
`/favicon.ico` que responde 404. Se detectó al verificar el despliegue del PR #9
(único error de consola en producción, aparte de ninguno).

## Marca de partida

El logo de Instagram de Vainilla: círculo casi negro, una V blanca de trazo fino
y un subrayado corto centrado debajo.

Proporciones medidas sobre el JPEG original de 150×150 px, expresadas respecto al
diámetro del círculo:

| Elemento | Medida | / diámetro |
|---|---|---|
| V (cuadrada) | 69×69 px | 0,46 |
| Subrayado | 41×3 px | 0,27 de ancho |
| Grosor del subrayado | 3 px | 0,020 |
| Trazo de la V (perpendicular) | ~3,4 px | 0,023 |
| Hueco V → subrayado | 7 px | 0,047 |
| Ancho subrayado / ancho V | — | 0,59 |
| Fondo | `#1E1E1E` | — |
| Trazo | `#FFFFFF` | — |

## Decisión de diseño: dos variantes

El trazo original mide 2,3 % del diámetro. **A 16 px eso son 0,37 px**, por debajo
de un píxel: se renderiza como una mancha gris y el subrayado desaparece. Además la
marca ocupa solo el 46 % del círculo, así que a 16 px la mitad de los píxeles se
gastan en borde negro, y el hueco de 4,7 % es medio píxel — la V y el subrayado se
fusionan en un borrón.

Se descartó una sola variante intermedia: no queda bien en ninguno de los dos
extremos. Se generan dos, como en cualquier set de iconos profesional.

Parámetros en un `viewBox` de 100 unidades:

| | Fiel | Optimizada |
|---|---|---|
| Ancho de la marca | 46 | 54 |
| Grosor de trazo | 2,3 | 8 |
| Hueco V → subrayado | 4,7 | 8 |
| Ancho subrayado / V | 0,59 | 0,59 |
| Destino | 180 px y SVG | 16 y 32 px |

El ancho de la marca optimizada está limitado por el círculo, no por el gusto. Con
trazo 8, la esquina externa del extremo del brazo de la V queda a esta distancia
del borde:

| Marca | Margen al borde |
|---|---|
| 52 % | 4,41 |
| 54 % | 3,00 |
| 56 % | 1,59 |
| 58 % | 0,18 |
| 60 % | **−1,23 (se sale)** |

A 58 % y 60 % el círculo sale visiblemente recortado en las puntas. **54 %** es el
mayor valor con margen real, y a 16 px se sigue leyendo como V subrayada.

Conviene comprobarlo con la geometría, no a ojo: en los renders a 16 px el recorte
no se aprecia y una primera revisión visual dio por bueno el 60 %.

El subrayado usa el mismo grosor que la V en ambas variantes (en el original difieren
en 0,4 px, diferencia que no sobrevive a ningún tamaño de favicon).

## Color

Círculo `#1E1E1E`, trazo `#FFFFFF` — los del logo de Instagram.

**No se usa `--negro` (`#161216`) del sitio**, que es más cálido. Se prioriza la
fidelidad a la marca sobre la coherencia con los tokens del CSS. La regla de
`CLAUDE.md` de no escribir hex crudo aplica a las reglas de estilo de `index.html`,
no a estos assets, que son archivos independientes.

## Archivos

Servidos:

| Archivo | Variante | Contenido |
|---|---|---|
| `favicon.ico` | optimizada | 16×16 y 32×32 empaquetados |
| `favicon.svg` | fiel | vectorial |
| `apple-touch-icon.png` | fiel | 180×180 |

Fuente reproducible: `assets/favicon-16-32.svg` (optimizada), origen del `.ico`.
`favicon.svg` es a la vez entregable y fuente de la variante fiel.

Peso total esperado: 3–4 KB.

## Marcado

Tres líneas en el `<head>` de `index.html`:

```html
<link rel="icon" href="/favicon.ico" sizes="32x32">
<link rel="icon" href="/favicon.svg" type="image/svg+xml">
<link rel="apple-touch-icon" href="/apple-touch-icon.png">
```

El `.ico` se declara además de estar en la raíz porque los navegadores modernos
prefieren la declaración explícita; los viejos lo piden solo.

## Caché

Los iconos van en la raíz y **no coinciden con ninguna regla de `_headers`**: la
regla `/` solo cubre la raíz exacta, no `/favicon.ico`. Se añaden tres reglas de
30 días, cada una con su ruta literal para no solaparse con las existentes:

```
/favicon.ico
  Cache-Control: public, max-age=2592000

/favicon.svg
  Cache-Control: public, max-age=2592000

/apple-touch-icon.png
  Cache-Control: public, max-age=2592000
```

Como el resto de `_headers`, esto no hace nada hasta migrar a Cloudflare (issue #10).

## Service worker: decisión de no tocarlo

`sw.js` cachea `/assets/*` y las navegaciones. Los iconos no caen en ninguna de las
dos ramas, así que pasan directos a la red.

**Se deja así a propósito.** Los navegadores cachean favicons de forma muy agresiva
por su cuenta, y añadir rutas sueltas de la raíz al handler de `fetch` lo complica
para ganar muy poco. Coste aceptado: sin conexión la pestaña puede salir sin icono.

## Generación

```sh
rsvg-convert -w 180 -h 180 favicon.svg -o apple-touch-icon.png
rsvg-convert -w 16  -h 16  assets/favicon-16-32.svg -o /tmp/f16.png
rsvg-convert -w 32  -h 32  assets/favicon-16-32.svg -o /tmp/f32.png
convert /tmp/f16.png /tmp/f32.png favicon.ico
```

La receta va al README, junto a la de las fotos.

## Verificación

1. Los tres archivos responden 200 en local y en producción tras el merge.
2. `favicon.ico` contiene dos imágenes, de 16 y 32 px (`identify favicon.ico`).
3. Carga en Chrome con perfil limpio: **cero errores de consola**. Es la prueba que
   cierra el problema original — hoy sale exactamente un 404 y debe salir ninguno.
4. Inspección visual de los renders a 16, 32 y 180 px.

## Fuera de alcance

- Manifiesto PWA / iconos `maskable`. No hay manifiesto y añadirlo no es este trabajo.
- Variante para modo oscuro. El círculo negro funciona sobre cualquier fondo de pestaña.
- Retocar el logo de la marca. Se reproduce, no se rediseña.
