const prisma = require('../lib/prisma');

const round2 = (n) => Math.round(n * 100) / 100;

const USER_SELECT = {
  id: true,
  email: true,
  name: true,
  currency: true,
  country: true,
  monthlyBudget: true,
  isPremium: true,
  emergencyFundMonths: true,
  emergencyFundSaved: true,
};

async function getProfile(req, res) {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    select: USER_SELECT,
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
    select: USER_SELECT,
  });
  return res.json(user);
}

// Activa Premium. En producción esto debe ir precedido por la verificación
// del pago (Stripe/PayPal). Por ahora es un placeholder de "compra".
async function activatePremium(req, res) {
  const user = await prisma.user.update({
    where: { id: req.userId },
    data: { isPremium: true },
    select: USER_SELECT,
  });
  return res.json(user);
}

/// Gasto esencial mensual = promedio del gasto de los últimos 3 meses
/// (incluido el actual). Se promedian solo los meses con datos.
async function essentialMonthlyExpense(userId) {
  const now = new Date();
  const since = new Date(now.getFullYear(), now.getMonth() - 2, 1);
  const txs = await prisma.transaction.findMany({
    where: { userId, type: 'expense', date: { gte: since } },
    select: { amount: true, date: true },
  });
  const byMonth = {};
  for (const t of txs) {
    const key = `${t.date.getFullYear()}-${t.date.getMonth()}`;
    byMonth[key] = (byMonth[key] || 0) + Number(t.amount);
  }
  const sums = Object.values(byMonth);
  if (sums.length === 0) return 0;
  const total = sums.reduce((a, b) => a + b, 0);
  return round2(total / sums.length);
}

async function emergencyFundPayload(userId) {
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { emergencyFundMonths: true, emergencyFundSaved: true },
  });
  const months = user ? user.emergencyFundMonths : 3;
  const saved = user ? Number(user.emergencyFundSaved) : 0;
  const essentialMonthly = await essentialMonthlyExpense(userId);
  const goal = round2(months * essentialMonthly);
  const progress = goal > 0 ? Math.min(1, saved / goal) : 0;
  return {
    months,
    saved: round2(saved),
    essentialMonthly,
    goal,
    progress: Math.round(progress * 1000) / 1000,
  };
}

async function getEmergencyFund(req, res) {
  return res.json(await emergencyFundPayload(req.userId));
}

async function updateEmergencyFund(req, res) {
  const data = {};
  if (req.body.months !== undefined) {
    const months = parseInt(req.body.months, 10);
    if (!Number.isFinite(months) || months < 1 || months > 12) {
      return res.status(400).json({ error: 'Meses debe estar entre 1 y 12' });
    }
    data.emergencyFundMonths = months;
  }
  if (req.body.saved !== undefined) {
    const saved = parseFloat(req.body.saved);
    if (!Number.isFinite(saved) || saved < 0) {
      return res.status(400).json({ error: 'El ahorro debe ser un monto válido' });
    }
    data.emergencyFundSaved = saved;
  }
  if (Object.keys(data).length > 0) {
    await prisma.user.update({ where: { id: req.userId }, data });
  }
  return res.json(await emergencyFundPayload(req.userId));
}

module.exports = {
  getProfile,
  updateProfile,
  activatePremium,
  getEmergencyFund,
  updateEmergencyFund,
};
