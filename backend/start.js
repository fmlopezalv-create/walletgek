// Script de arranque para Render: limpia la URL de Neon, aplica migraciones
// y arranca la API.
require('dotenv').config();
const { execSync } = require('child_process');
const { cleanNeonUrl } = require('./src/lib/dbUrl');

process.env.DATABASE_URL = cleanNeonUrl(process.env.DATABASE_URL);

try {
  execSync('npx prisma migrate deploy', {
    stdio: 'inherit',
    env: process.env,
  });
} catch (e) {
  console.error('Error aplicando migraciones:', e.message);
  process.exit(1);
}

require('./src/index.js');
