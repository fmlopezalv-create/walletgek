const prisma = require('../lib/prisma');

// Convierte un valor de fecha a Date; devuelve null si es inválido.
function parseDate(value) {
  if (value === undefined || value === null || value === '') return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

function monthRange(month) {
  // month: 'YYYY-MM'
  if (month && /^\d{4}-(0[1-9]|1[0-2])$/.test(month)) {
    const [y, m] = month.split('-').map(Number);
    return {
      gte: new Date(y, m - 1, 1),
      lt: new Date(y, m, 1),
    };
  }
  return null;
}

async function listTransactions(req, res) {
  const { month, page, limit } = req.query;
  const where = { userId: req.userId };

  const range = monthRange(month);
  if (range) where.date = range;

  const pageNum = Math.max(1, parseInt(page, 10) || 1);
  const limitNum = Math.min(100, Math.max(1, parseInt(limit, 10) || 50));
  const skip = (pageNum - 1) * limitNum;

  const [transactions, total] = await Promise.all([
    prisma.transaction.findMany({
      where,
      include: { category: true },
      orderBy: { date: 'desc' },
      skip,
      take: limitNum,
    }),
    prisma.transaction.count({ where }),
  ]);

  return res.json({
    transactions,
    total,
    page: pageNum,
    limit: limitNum,
  });
}

async function createTransaction(req, res) {
  const { amount, type, note, categoryId, date } = req.body;
  const parsedAmount = parseFloat(amount);
  if (!parsedAmount || parsedAmount <= 0 || !['income', 'expense'].includes(type)) {
    return res.status(400).json({ error: 'Monto válido y tipo (income|expense) son obligatorios' });
  }

  const parsedDate = parseDate(date);
  if (date !== undefined && date !== null && date !== '' && parsedDate === null) {
    return res.status(400).json({ error: 'Fecha inválida' });
  }

  const data = {
    amount: parsedAmount,
    type,
    note,
    userId: req.userId,
    date: parsedDate || new Date(),
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
  if (date !== undefined) {
    const parsedDate = parseDate(date);
    if (parsedDate === null) {
      return res.status(400).json({ error: 'Fecha inválida' });
    }
    data.date = parsedDate;
  }

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
