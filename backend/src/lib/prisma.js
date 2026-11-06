const { PrismaClient } = require('@prisma/client');
const { cleanNeonUrl } = require('./dbUrl');

const prisma = new PrismaClient({
  datasources: {
    db: { url: cleanNeonUrl(process.env.DATABASE_URL) },
  },
});
module.exports = prisma;
