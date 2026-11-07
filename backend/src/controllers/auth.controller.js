const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');
const { DEFAULT_CATEGORIES } = require('../lib/defaultCategories');

const EMAIL_RE = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

const publicUser = (user) => ({
  id: user.id,
  email: user.email,
  name: user.name,
  currency: user.currency,
  country: user.country,
  isPremium: user.isPremium ?? false,
  monthlyBudget:
    user.monthlyBudget != null ? Number(user.monthlyBudget) : null,
  emergencyFundMonths: user.emergencyFundMonths ?? 3,
  emergencyFundSaved:
    user.emergencyFundSaved != null ? Number(user.emergencyFundSaved) : 0,
});

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

async function register(req, res) {
  const email = normalizeEmail(req.body.email);
  const { password, name, currency, country } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña son obligatorios' });
  }
  if (!EMAIL_RE.test(email)) {
    return res.status(400).json({ error: 'Introduce un email válido' });
  }
  if (password.length < 6) {
    return res.status(400).json({ error: 'La contraseña debe tener al menos 6 caracteres' });
  }
  const exists = await prisma.user.findUnique({ where: { email } });
  if (exists) {
    return res.status(409).json({ error: 'El email ya está registrado' });
  }
  const passwordHash = await bcrypt.hash(password, 10);
  const user = await prisma.user.create({
    data: {
      email,
      passwordHash,
      name: name != null ? String(name).trim() : null,
      currency: currency || 'EUR',
      country: country || 'ES',
    },
  });
  await prisma.category.createMany({
    data: DEFAULT_CATEGORIES.map((c) => ({ ...c, userId: user.id })),
  });
  const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
  return res.status(201).json({ token, user: publicUser(user) });
}

async function login(req, res) {
  const email = normalizeEmail(req.body.email);
  const { password } = req.body;
  if (!email || !password) {
    return res.status(400).json({ error: 'Email y contraseña son obligatorios' });
  }
  const user = await prisma.user.findUnique({ where: { email } });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    return res.status(401).json({ error: 'Credenciales inválidas' });
  }
  const token = jwt.sign({ userId: user.id }, process.env.JWT_SECRET, { expiresIn: '7d' });
  return res.json({ token, user: publicUser(user) });
}

module.exports = { register, login };
