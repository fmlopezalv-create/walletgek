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
  const trimmedName = name != null ? String(name).trim() : '';
  if (!trimmedName || !['income', 'expense'].includes(type)) {
    return res.status(400).json({ error: 'Nombre y tipo (income|expense) son obligatorios' });
  }
  try {
    const category = await prisma.category.create({
      data: {
        name: trimmedName,
        type,
        color,
        monthlyBudget: monthlyBudget != null ? parseFloat(monthlyBudget) : null,
        userId: req.userId,
      },
    });
    return res.status(201).json(category);
  } catch (e) {
    // Violación de @@unique([userId, name, type])
    if (e.code === 'P2002') {
      return res.status(409).json({
        error: 'Ya tienes una categoría con ese nombre y tipo',
      });
    }
    throw e;
  }
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

async function deleteCategory(req, res) {
  const { id } = req.params;
  const category = await prisma.category.findFirst({ where: { id, userId: req.userId } });
  if (!category) return res.status(404).json({ error: 'Categoría no encontrada' });

  // Las transacciones asociadas quedan "sin categoría" (categoryId = null)
  // gracias a onDelete: SetNull en el schema.
  await prisma.category.delete({ where: { id } });
  return res.json({ ok: true });
}

module.exports = { listCategories, createCategory, updateCategory, deleteCategory };
