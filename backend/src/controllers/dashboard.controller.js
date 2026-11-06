const prisma = require('../lib/prisma');

async function healthSummary(req, res) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const [incomeAgg, expenseAgg, debts] = await Promise.all([
    prisma.transaction.aggregate({
      where: { userId: req.userId, type: 'income', date: { gte: start, lt: end } },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: { userId: req.userId, type: 'expense', date: { gte: start, lt: end } },
      _sum: { amount: true },
    }),
    prisma.debt.findMany({
      where: { userId: req.userId },
      select: { minimumPayment: true },
    }),
  ]);

  const income = Number(incomeAgg._sum.amount || 0);
  const expense = Number(expenseAgg._sum.amount || 0);
  const savings = income - expense;
  const savingsRate = income > 0 ? (savings / income) : null;

  const monthlyDebt = debts.reduce((s, d) => s + Number(d.minimumPayment), 0);
  const dti = income > 0 ? (monthlyDebt / income) : null;

  return res.json({
    month: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
    income: Math.round(income * 100) / 100,
    expense: Math.round(expense * 100) / 100,
    savingsRate: savingsRate != null ? Math.round(savingsRate * 10000) / 100 : null,
    monthlyDebt: Math.round(monthlyDebt * 100) / 100,
    dti: dti != null ? Math.round(dti * 10000) / 100 : null,
  });
}

async function homeSummary(req, res) {
  const now = new Date();
  let start = new Date(now.getFullYear(), now.getMonth(), 1);
  // Soporta selector de mes: /dashboard/home?month=YYYY-MM
  const monthParam = req.query.month;
  if (monthParam && /^\d{4}-(0[1-9]|1[0-2])$/.test(monthParam)) {
    const [y, m] = monthParam.split('-').map(Number);
    start = new Date(y, m - 1, 1);
  }
  const end = new Date(start.getFullYear(), start.getMonth() + 1, 1);
  const prevStart = new Date(start.getFullYear(), start.getMonth() - 1, 1);

  const [incAgg, expAgg, prevIncAgg, prevExpAgg, debts, monthTx] =
    await Promise.all([
      prisma.transaction.aggregate({
        where: { userId: req.userId, type: 'income', date: { gte: start, lt: end } },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: { userId: req.userId, type: 'expense', date: { gte: start, lt: end } },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: { userId: req.userId, type: 'income', date: { gte: prevStart, lt: start } },
        _sum: { amount: true },
      }),
      prisma.transaction.aggregate({
        where: { userId: req.userId, type: 'expense', date: { gte: prevStart, lt: start } },
        _sum: { amount: true },
      }),
      prisma.debt.findMany({
        where: { userId: req.userId },
        select: {
          id: true, name: true, balance: true, minimumPayment: true,
          dueDate: true, color: true, type: true,
        },
      }),
      prisma.transaction.findMany({
        where: { userId: req.userId, type: 'expense', date: { gte: start, lt: end } },
        select: { categoryId: true, amount: true },
      }),
    ]);

  const income = Number(incAgg._sum.amount || 0);
  const expense = Number(expAgg._sum.amount || 0);
  const prevIncome = Number(prevIncAgg._sum.amount || 0);
  const prevExpense = Number(prevExpAgg._sum.amount || 0);
  const balance = income - expense;
  const prevBalance = prevIncome - prevExpense;
  const variation =
    prevBalance !== 0 ? ((balance - prevBalance) / Math.abs(prevBalance)) * 100 : null;

  const upcoming = debts
    .filter((d) => Number(d.minimumPayment) > 0)
    .sort((a, b) => {
      const ad = a.dueDate ? new Date(a.dueDate).getTime() : Infinity;
      const bd = b.dueDate ? new Date(b.dueDate).getTime() : Infinity;
      return ad - bd;
    })
    .slice(0, 3)
    .map((d) => ({
      id: d.id,
      name: d.name,
      color: d.color,
      type: d.type,
      dueDate: d.dueDate ? d.dueDate.toISOString() : null,
      minimumPayment: Number(d.minimumPayment),
    }));

  const debtTotal = debts.reduce((s, d) => s + Number(d.balance), 0);
  const debtMonthly = debts.reduce((s, d) => s + Number(d.minimumPayment), 0);

  const spentByCat = {};
  for (const t of monthTx) {
    if (t.categoryId) {
      spentByCat[t.categoryId] = (spentByCat[t.categoryId] || 0) + Number(t.amount);
    }
  }
  const categories = await prisma.category.findMany({
    where: { userId: req.userId, type: 'expense' },
    select: { id: true, name: true, monthlyBudget: true },
  });
  const topCategories = categories
    .map((c) => ({
      id: c.id,
      name: c.name,
      spent: Math.round((spentByCat[c.id] || 0) * 100) / 100,
      budget: c.monthlyBudget != null ? Number(c.monthlyBudget) : 0,
    }))
    .filter((c) => c.spent > 0)
    .sort((a, b) => b.spent - a.spent)
    .slice(0, 5);

  return res.json({
    month: `${start.getFullYear()}-${String(start.getMonth() + 1).padStart(2, '0')}`,
    balance: Math.round(balance * 100) / 100,
    variation: variation != null ? Math.round(variation * 100) / 100 : null,
    income: Math.round(income * 100) / 100,
    expense: Math.round(expense * 100) / 100,
    upcomingPayments: upcoming,
    debtTotal: Math.round(debtTotal * 100) / 100,
    debtMonthly: Math.round(debtMonthly * 100) / 100,
    debtCount: debts.length,
    topCategories,
  });
}

module.exports = { healthSummary, homeSummary };
