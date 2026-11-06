require('dotenv').config();
const { execSync } = require('child_process');
const { cleanNeonUrl } = require('./lib/dbUrl');

// Compatibilidad con Neon: limpia la URL antes de que Prisma la use
// (quita channel_binding y añade pgbouncer=true en la URL pooled).
process.env.DATABASE_URL = cleanNeonUrl(process.env.DATABASE_URL);

// Aplica migraciones pendientes de forma tolerante: si fallan por entorno
// (p. ej. variables aún no listas), muestra el error pero no bloquea el
// arranque del servidor en local/dev.
try {
  execSync('npx prisma migrate deploy', { stdio: 'inherit', env: process.env });
} catch (e) {
  console.error('Aviso: no se pudieron aplicar migraciones:', e.message);
}

const app = require('./app');
const PORT = process.env.PORT || 3000;

app.listen(PORT, () => {
  console.log(`API walletgek escuchando en http://localhost:${PORT}`);
});
