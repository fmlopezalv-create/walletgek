const prisma = require('../lib/prisma');

async function listCategories(req, res) {
  const categories = await prisma.category.findMany({
    where: { userId: req.userId },
    orderBy: { name: 'asc' },
  });
  return res.json(categories);
}

async function createCategory(req, res) {
  const { name, type, color, monthlyBudget } = req.body;
  if (!name || !['income', 'expense'].includes(type)) {
    return res.status(400).json({ error: 'Nombre y tipo (income|expense) son obligatorios' });
  }
  const category = await prisma.category.create({
    data: {
      name,
      type,
      color,
      monthlyBudget: monthlyBudget != null ? parseFloat(monthlyBudget) : null,
      userId: req.userId,
    },
  });
  return res.status(201).json(category);
}

async function updateCategory(req, res) {
  const { id } = req.params;
  const { name, color, monthlyBudget } = req.body;
  const category = await prisma.category.findFirst({ where: { id, userId: req.userId } });
  if (!category) return res.status(404).json({ error: 'Categoría no encontrada' });

  const data = {};
  if (name !== undefined) data.name = name;
  if (color !== undefined) data.color = color;
  if (monthlyBudget !== undefined) {
    data.monthlyBudget = monthlyBudget != null ? parseFloat(monthlyBudget) : null;
  }
  const updated = await prisma.category.update({ where: { id }, data });
  return res.json(updated);
}

module.exports = { listCategories, createCategory, updateCategory };
