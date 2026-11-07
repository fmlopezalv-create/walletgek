const prisma = require('../lib/prisma');
const { computeDebtPlan } = require('../services/debtPlan');

// Convierte un valor de fecha a Date; devuelve null si es inválido.
function parseDate(value) {
  if (value === undefined || value === null || value === '') return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

function parseNonNegative(value, fallback = 0) {
  const n = parseFloat(value);
  if (Number.isNaN(n) || n < 0) return fallback;
  return n;
}

async function listDebts(req, res) {
  const debts = await prisma.debt.findMany({
    where: { userId: req.userId },
    include: { payments: true },
    orderBy: { createdAt: 'asc' },
  });
  return res.json(debts);
}

async function createDebt(req, res) {
  const {
    name,
    type,
    color,
    balance,
    interestRate,
    minimumPayment,
    dueDate,
    institution,
    status,
    monthsLate,
    paymentType,
    totalInstallments,
    paidInstallments,
    notifyEnabled,
    details,
  } = req.body;
  const trimmedName = name != null ? String(name).trim() : '';
  const parsedBalance = parseFloat(balance);
  if (!trimmedName || !parsedBalance || parsedBalance <= 0) {
    return res.status(400).json({ error: 'Nombre y saldo válido son obligatorios' });
  }
  if (dueDate !== undefined && dueDate !== null && dueDate !== '' && parseDate(dueDate) === null) {
    return res.status(400).json({ error: 'Fecha de vencimiento inválida' });
  }
  const debt = await prisma.debt.create({
    data: {
      name: trimmedName,
      type: type || 'other',
      color: color || null,
      balance: parsedBalance,
      interestRate: parseNonNegative(interestRate),
      minimumPayment: parseNonNegative(minimumPayment),
      dueDate: parseDate(dueDate),
      institution: institution || null,
      status: status || 'up_to_date',
      monthsLate: Math.max(0, parseInt(monthsLate) || 0),
      paymentType: paymentType || null,
      totalInstallments: parseInt(totalInstallments) || null,
      paidInstallments: Math.max(0, parseInt(paidInstallments) || 0),
      notifyEnabled: notifyEnabled !== false,
      details: details || undefined,
      userId: req.userId,
    },
    include: { payments: true },
  });
  return res.status(201).json(debt);
}

async function payDebt(req, res) {
  const { id } = req.params;
  const { amount, cuotas, date } = req.body;
  const parsedAmount = parseFloat(amount);
  if (!parsedAmount || parsedAmount <= 0) {
    return res.status(400).json({ error: 'Monto válido es obligatorio' });
  }
  const debt = await prisma.debt.findFirst({ where: { id, userId: req.userId } });
  if (!debt) return res.status(404).json({ error: 'Deuda no encontrada' });

  const cuotasCount = Math.max(1, parseInt(cuotas) || 1);
  const paymentDate = parseDate(date) || new Date();

  const newBalance = Math.max(0, Number(debt.balance) - parsedAmount);
  await prisma.debtPayment.create({
    data: { amount: parsedAmount, debtId: id, date: paymentDate },
  });
  const updated = await prisma.debt.update({
    where: { id },
    data: {
      balance: newBalance,
      paidInstallments: { increment: cuotasCount },
    },
    include: { payments: true },
  });
  return res.json(updated);
}

async function deleteDebt(req, res) {
  const { id } = req.params;
  const debt = await prisma.debt.findFirst({ where: { id, userId: req.userId } });
  if (!debt) return res.status(404).json({ error: 'Deuda no encontrada' });
  await prisma.debt.delete({ where: { id } });
  return res.json({ ok: true });
}

async function debtPlan(req, res) {
  const strategy = req.query.strategy === 'avalanche' ? 'avalanche' : 'snowball';
  const monthlyBudget = parseFloat(req.query.monthlyBudget) || 0;
  const debts = await prisma.debt.findMany({ where: { userId: req.userId } });

  if (debts.length === 0) {
    return res.json({ strategy, monthlyBudget, monthsToPayoff: 0, totalInterest: 0, schedule: [] });
  }

  const totalMin = debts.reduce((sum, d) => sum + Number(d.minimumPayment), 0);
  const budget = monthlyBudget > 0 ? monthlyBudget : totalMin;
  const plan = computeDebtPlan(debts, strategy, budget);
  return res.json(plan);
}

async function updateDebt(req, res) {
  const { id } = req.params;
  const {
    name,
    color,
    balance,
    interestRate,
    minimumPayment,
    dueDate,
    institution,
    status,
    monthsLate,
    paymentType,
    totalInstallments,
    paidInstallments,
    notifyEnabled,
    details,
  } = req.body;

  const debt = await prisma.debt.findFirst({ where: { id, userId: req.userId } });
  if (!debt) return res.status(404).json({ error: 'Deuda no encontrada' });

  if (dueDate !== undefined && dueDate !== null && dueDate !== '' && parseDate(dueDate) === null) {
    return res.status(400).json({ error: 'Fecha de vencimiento inválida' });
  }

  const data = {};
  if (name !== undefined) data.name = String(name).trim();
  if (color !== undefined) data.color = color || null;
  if (balance !== undefined) {
    const parsed = parseFloat(balance);
    if (Number.isNaN(parsed) || parsed <= 0) {
      return res.status(400).json({ error: 'Saldo válido obligatorio' });
    }
    data.balance = parsed;
  }
  if (interestRate !== undefined) data.interestRate = parseNonNegative(interestRate);
  if (minimumPayment !== undefined) data.minimumPayment = parseNonNegative(minimumPayment);
  if (dueDate !== undefined) data.dueDate = parseDate(dueDate);
  if (institution !== undefined) data.institution = institution || null;
  if (status !== undefined) data.status = status;
  if (monthsLate !== undefined) data.monthsLate = Math.max(0, parseInt(monthsLate) || 0);
  if (paymentType !== undefined) data.paymentType = paymentType || null;
  if (totalInstallments !== undefined) {
    data.totalInstallments =
      totalInstallments != null ? parseInt(totalInstallments) : null;
  }
  if (paidInstallments !== undefined) {
    data.paidInstallments = Math.max(0, parseInt(paidInstallments) || 0);
  }
  if (notifyEnabled !== undefined) data.notifyEnabled = notifyEnabled === true;
  if (details !== undefined) data.details = details;

  const updated = await prisma.debt.update({
    where: { id },
    data,
    include: { payments: true },
  });
  return res.json(updated);
}

module.exports = { listDebts, createDebt, payDebt, deleteDebt, debtPlan, updateDebt };
