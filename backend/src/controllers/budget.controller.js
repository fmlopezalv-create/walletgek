const prisma = require('../lib/prisma');

const round2 = (n) => Math.round(n * 100) / 100;

async function budgetSummary(req, res) {
  // Mes opcional (?month=YYYY-MM); por defecto, el mes actual.
  let year;
  let month;
  const monthParam = req.query.month;
  const m = monthParam && /^\d{4}-(0[1-9]|1[0-2])$/.test(monthParam);
  if (m) {
    const [y, mm] = monthParam.split('-').map(Number);
    year = y;
    month = mm - 1; // meses JS empiezan en 0
  } else {
    const now = new Date();
    year = now.getFullYear();
    month = now.getMonth();
  }
  const start = new Date(year, month, 1);
  const end = new Date(year, month + 1, 1);

  const [user, categories, transactions] = await Promise.all([
    prisma.user.findUnique({
      where: { id: req.userId },
      select: { monthlyBudget: true },
    }),
    prisma.category.findMany({ where: { userId: req.userId, type: 'expense' } }),
    prisma.transaction.findMany({
      where: {
        userId: req.userId,
        type: 'expense',
        date: { gte: start, lt: end },
      },
      select: { categoryId: true, amount: true },
    }),
  ]);

  const spentByCategory = {};
  for (const t of transactions) {
    if (t.categoryId) {
      spentByCategory[t.categoryId] =
        (spentByCategory[t.categoryId] || 0) + Number(t.amount);
    }
  }

  const items = categories.map((c) => ({
    id: c.id,
    name: c.name,
    budget: c.monthlyBudget != null ? round2(Number(c.monthlyBudget)) : 0,
    spent: round2(spentByCategory[c.id] || 0),
  }));

  const totalBudget = round2(items.reduce((s, i) => s + i.budget, 0));
  // totalSpent = gasto real del mes (incluye transacciones sin categoría).
  const totalSpent = round2(
    transactions.reduce((s, t) => s + Number(t.amount), 0),
  );

  return res.json({
    month: `${year}-${String(month + 1).padStart(2, '0')}`,
    totalBudget,
    totalSpent,
    globalBudget:
      user && user.monthlyBudget != null
        ? round2(Number(user.monthlyBudget))
        : null,
    categories: items,
  });
}

module.exports = { budgetSummary };
