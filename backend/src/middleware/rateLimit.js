// Rate limiting simple en memoria (por IP). Para un MVP es suficiente;
// en producción conviene usar un store compartido (Redis) si hay varias instancias.

const hits = new Map();
const WINDOW_MS = 15 * 60 * 1000; // 15 minutos
const MAX_REQUESTS = 20; // máximo de intentos por ventana

function rateLimit(req, res, next) {
  const ip = req.ip || req.socket?.remoteAddress || 'unknown';
  const now = Date.now();
  const entry = hits.get(ip);

  if (!entry || now - entry.start > WINDOW_MS) {
    hits.set(ip, { start: now, count: 1 });
    return next();
  }

  entry.count += 1;
  if (entry.count > MAX_REQUESTS) {
    return res.status(429).json({
      error: 'Demasiados intentos. Intenta de nuevo en unos minutos.',
    });
  }
  return next();
}

// Limpieza periódica para no crecer sin límite.
setInterval(() => {
  const now = Date.now();
  for (const [key, value] of hits.entries()) {
    if (now - value.start > WINDOW_MS) hits.delete(key);
  }
}, WINDOW_MS).unref();

// Rate limit específico para el asesor IA (llamadas a DeepSeek, con costo).
// Se aplica por usuario (disponible tras authMiddleware).
const advisorHits = new Map();
const ADVISOR_WINDOW_MS = 5 * 60 * 1000; // 5 minutos
const ADVISOR_MAX_REQUESTS = 40;

function advisorRateLimit(req, res, next) {
  const key = req.userId || req.ip || 'unknown';
  const now = Date.now();
  const entry = advisorHits.get(key);

  if (!entry || now - entry.start > ADVISOR_WINDOW_MS) {
    advisorHits.set(key, { start: now, count: 1 });
    return next();
  }

  entry.count += 1;
  if (entry.count > ADVISOR_MAX_REQUESTS) {
    return res.status(429).json({
      error: 'Has hecho muchas preguntas. Espera unos minutos e inténtalo de nuevo.',
    });
  }
  return next();
}

setInterval(() => {
  const now = Date.now();
  for (const [key, value] of advisorHits.entries()) {
    if (now - value.start > ADVISOR_WINDOW_MS) advisorHits.delete(key);
  }
}, ADVISOR_WINDOW_MS).unref();

module.exports = { rateLimit, advisorRateLimit };
