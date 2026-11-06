// Ajusta la URL de Neon para que Prisma funcione:
// - Elimina `channel_binding=require` (no soportado por el driver).
// - Añade `pgbouncer=true` en la URL pooled de Neon (PgBouncer en modo
//   transacción no admite prepared statements de Prisma).
function cleanNeonUrl(url) {
  if (!url) return url;
  try {
    const u = new URL(url);
    u.searchParams.delete('channel_binding');
    if (u.hostname.includes('-pooler.') && !u.searchParams.has('pgbouncer')) {
      u.searchParams.set('pgbouncer', 'true');
    }
    return u.toString();
  } catch {
    return url;
  }
}

module.exports = { cleanNeonUrl };
