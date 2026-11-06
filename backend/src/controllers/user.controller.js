const prisma = require('../lib/prisma');

async function getProfile(req, res) {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    select: {
      id: true,
      email: true,
      name: true,
      currency: true,
      country: true,
      monthlyBudget: true,
      isPremium: true,
    },
  });
  if (!user) return res.status(404).json({ error: 'Usuario no encontrado' });
  return res.json(user);
}

async function updateProfile(req, res) {
  const { currency, name, country, monthlyBudget } = req.body;
  const data = {};
  if (currency) data.currency = currency;
  if (name !== undefined) data.name = name;
  if (country) data.country = country;
  if (monthlyBudget !== undefined) {
    data.monthlyBudget =
      monthlyBudget != null ? parseFloat(monthlyBudget) : null;
  }

  const user = await prisma.user.update({
    where: { id: req.userId },
    data,
    select: {
      id: true,
      email: true,
      name: true,
      currency: true,
      country: true,
      monthlyBudget: true,
      isPremium: true,
    },
  });
  return res.json(user);
}

// Activa Premium. En producción esto debe ir precedido por la verificación
// del pago (Stripe/PayPal). Por ahora es un placeholder de "compra".
async function activatePremium(req, res) {
  const user = await prisma.user.update({
    where: { id: req.userId },
    data: { isPremium: true },
    select: {
      id: true,
      email: true,
      name: true,
      currency: true,
      country: true,
      monthlyBudget: true,
      isPremium: true,
    },
  });
  return res.json(user);
}

module.exports = { getProfile, updateProfile, activatePremium };
