const prisma = require('../lib/prisma');

async function budgetSummary(req, res) {
  // Mes opcional (?month=YYYY-MM); por defecto, el mes actual.
  let year;
  let month;
  const monthParam = req.query.month;
  if (monthParam && /^\d{4}-\d{2}$/.test(monthParam)) {
    const [y, m] = monthParam.split('-').map(Number);
    year = y;
    month = m - 1; // meses JS empiezan en 0
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
    budget: c.monthlyBudget != null ? Number(c.monthlyBudget) : 0,
    spent: Math.round((spentByCategory[c.id] || 0) * 100) / 100,
  }));

  const totalBudget =
    Math.round(items.reduce((s, i) => s + i.budget, 0) * 100) / 100;
  const totalSpent =
    Math.round(items.reduce((s, i) => s + i.spent, 0) * 100) / 100;

  return res.json({
    month: `${year}-${String(month + 1).padStart(2, '0')}`,
    totalBudget,
    totalSpent,
    globalBudget:
      user && user.monthlyBudget != null ? Number(user.monthlyBudget) : null,
    categories: items,
  });
}

module.exports = { budgetSummary };
