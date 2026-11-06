const prisma = require('../lib/prisma');

async function listTransactions(req, res) {
  const transactions = await prisma.transaction.findMany({
    where: { userId: req.userId },
    include: { category: true },
    orderBy: { date: 'desc' },
    take: 200,
  });
  return res.json(transactions);
}

async function createTransaction(req, res) {
  const { amount, type, note, categoryId, date } = req.body;
  const parsedAmount = parseFloat(amount);
  if (!parsedAmount || parsedAmount <= 0 || !['income', 'expense'].includes(type)) {
    return res.status(400).json({ error: 'Monto válido y tipo (income|expense) son obligatorios' });
  }

  const data = {
    amount: parsedAmount,
    type,
    note,
    userId: req.userId,
    date: date ? new Date(date) : new Date(),
  };

  if (categoryId) {
    const category = await prisma.category.findFirst({
      where: { id: categoryId, userId: req.userId },
    });
    if (!category) {
      return res.status(400).json({ error: 'Categoría no válida' });
    }
    data.categoryId = categoryId;
  }

  const transaction = await prisma.transaction.create({
    data,
    include: { category: true },
  });
  return res.status(201).json(transaction);
}

async function updateTransaction(req, res) {
  const { id } = req.params;
  const { amount, type, note, categoryId, date } = req.body;

  const existing = await prisma.transaction.findFirst({
    where: { id, userId: req.userId },
  });
  if (!existing) {
    return res.status(404).json({ error: 'Movimiento no encontrado' });
  }

  const data = {};
  if (amount !== undefined) {
    const parsedAmount = parseFloat(amount);
    if (!parsedAmount || parsedAmount <= 0) {
      return res.status(400).json({ error: 'Monto válido obligatorio' });
    }
    data.amount = parsedAmount;
  }
  if (type !== undefined) {
    if (!['income', 'expense'].includes(type)) {
      return res.status(400).json({ error: 'Tipo inválido' });
    }
    data.type = type;
  }
  if (note !== undefined) data.note = note;
  if (date !== undefined) data.date = new Date(date);

  if (categoryId !== undefined) {
    if (categoryId === null) {
      data.categoryId = null;
    } else {
      const category = await prisma.category.findFirst({
        where: { id: categoryId, userId: req.userId },
      });
      if (!category) {
        return res.status(400).json({ error: 'Categoría no válida' });
      }
      data.categoryId = categoryId;
    }
  }

  const transaction = await prisma.transaction.update({
    where: { id },
    data,
    include: { category: true },
  });
  return res.json(transaction);
}

async function deleteTransaction(req, res) {
  const { id } = req.params;
  const existing = await prisma.transaction.findFirst({
    where: { id, userId: req.userId },
  });
  if (!existing) {
    return res.status(404).json({ error: 'Movimiento no encontrado' });
  }
  await prisma.transaction.delete({ where: { id } });
  return res.json({ ok: true });
}

module.exports = {
  listTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
};
