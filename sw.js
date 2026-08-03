// Service worker de Vainilla: carga instantánea en conexiones lentas o sin señal.
//
// assets (fotos y fuentes): se responde desde caché al instante y se revalida
//   por detrás. Con el max-age largo de _headers esa revalidación casi siempre
//   la resuelve la caché HTTP del navegador, así que no cuesta datos.
// HTML: primero la red (para que los precios estén al día) y, si no hay
//   conexión, la última copia guardada.
// Todo lo demás (typekit, wa.me, instagram) pasa directo a la red.

const CACHE = 'vainilla-v1';

self.addEventListener('install', () => self.skipWaiting());

self.addEventListener('activate', e => {
  e.waitUntil(
    caches.keys()
      .then(claves => Promise.all(
        claves.filter(c => c !== CACHE).map(c => caches.delete(c))
      ))
      .then(() => self.clients.claim())
  );
});

self.addEventListener('fetch', e => {
  const req = e.request;

  if (req.method !== 'GET') return;

  const url = new URL(req.url);
  if (url.origin !== location.origin) return;

  if (url.pathname.startsWith('/assets/')) {
    // respondWith y waitUntil se llaman en el mismo turno, mientras el evento
    // sigue activo: si la revalidación se lanzara desde dentro de un .then()
    // el navegador podría rechazar el waitUntil.
    const red = fetch(req).then(res => guardar(req, res));
    e.waitUntil(red.catch(() => {}));
    e.respondWith(caches.match(req).then(guardado => guardado || red));
    return;
  }

  if (req.mode === 'navigate') {
    e.respondWith(
      fetch(req)
        .then(res => guardar(req, res))
        .catch(() => caches.match(req).then(guardado => guardado || caches.match('/')))
    );
  }
});

function guardar(req, res) {
  if (res && res.ok) {
    const copia = res.clone();
    caches.open(CACHE).then(c => c.put(req, copia));
  }
  return res;
}
