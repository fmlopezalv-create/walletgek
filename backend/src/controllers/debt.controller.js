const prisma = require('../lib/prisma');
const { computeDebtPlan } = require('../services/debtPlan');

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
    details,
  } = req.body;
  const parsedBalance = parseFloat(balance);
  if (!name || !parsedBalance || parsedBalance <= 0) {
    return res.status(400).json({ error: 'Nombre y saldo válido son obligatorios' });
  }
  const debt = await prisma.debt.create({
    data: {
      name,
      type: type || 'other',
      color: color || null,
      balance: parsedBalance,
      interestRate: parseFloat(interestRate) || 0,
      minimumPayment: parseFloat(minimumPayment) || 0,
      dueDate: dueDate ? new Date(dueDate) : null,
      institution: institution || null,
      status: status || 'up_to_date',
      monthsLate: parseInt(monthsLate) || 0,
      paymentType: paymentType || null,
      totalInstallments: parseInt(totalInstallments) || null,
      paidInstallments: parseInt(paidInstallments) || 0,
      details: details || undefined,
      userId: req.userId,
    },
    include: { payments: true },
  });
  return res.status(201).json(debt);
}

async function payDebt(req, res) {
  const { id } = req.params;
  const { amount, cuotas } = req.body;
  const parsedAmount = parseFloat(amount);
  if (!parsedAmount || parsedAmount <= 0) {
    return res.status(400).json({ error: 'Monto válido es obligatorio' });
  }
  const debt = await prisma.debt.findFirst({ where: { id, userId: req.userId } });
  if (!debt) return res.status(404).json({ error: 'Deuda no encontrada' });

  const newBalance = Math.max(0, Number(debt.balance) - parsedAmount);
  const cuotasCount = parseInt(cuotas) || 1;
  await prisma.debtPayment.create({ data: { amount: parsedAmount, debtId: id } });
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
    details,
  } = req.body;

  const debt = await prisma.debt.findFirst({ where: { id, userId: req.userId } });
  if (!debt) return res.status(404).json({ error: 'Deuda no encontrada' });

  const data = {};
  if (name !== undefined) data.name = name;
  if (color !== undefined) data.color = color || null;
  if (balance !== undefined) data.balance = parseFloat(balance);
  if (interestRate !== undefined) data.interestRate = parseFloat(interestRate) || 0;
  if (minimumPayment !== undefined) data.minimumPayment = parseFloat(minimumPayment) || 0;
  if (dueDate !== undefined) data.dueDate = dueDate ? new Date(dueDate) : null;
  if (institution !== undefined) data.institution = institution || null;
  if (status !== undefined) data.status = status;
  if (monthsLate !== undefined) data.monthsLate = parseInt(monthsLate) || 0;
  if (paymentType !== undefined) data.paymentType = paymentType || null;
  if (totalInstallments !== undefined) {
    data.totalInstallments =
      totalInstallments != null ? parseInt(totalInstallments) : null;
  }
  if (paidInstallments !== undefined) {
    data.paidInstallments = parseInt(paidInstallments) || 0;
  }
  if (details !== undefined) data.details = details;

  const updated = await prisma.debt.update({
    where: { id },
    data,
    include: { payments: true },
  });
  return res.json(updated);
}

module.exports = { listDebts, createDebt, payDebt, deleteDebt, debtPlan, updateDebt };
