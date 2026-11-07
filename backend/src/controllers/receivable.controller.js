const prisma = require('../lib/prisma');

function parseDate(value) {
  if (value === undefined || value === null || value === '') return null;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? null : d;
}

async function listReceivables(req, res) {
  const receivables = await prisma.receivable.findMany({
    where: { userId: req.userId },
    orderBy: [{ status: 'asc' }, { createdAt: 'desc' }],
  });
  return res.json(receivables);
}

async function createReceivable(req, res) {
  const { person, amount, note, dueDate, details } = req.body;
  const trimmedPerson = person != null ? String(person).trim() : '';
  const parsedAmount = parseFloat(amount);
  if (!trimmedPerson || !parsedAmount || parsedAmount <= 0) {
    return res.status(400).json({ error: 'Persona y monto válido son obligatorios' });
  }
  if (dueDate !== undefined && dueDate !== null && dueDate !== '' && parseDate(dueDate) === null) {
    return res.status(400).json({ error: 'Fecha inválida' });
  }
  const receivable = await prisma.receivable.create({
    data: {
      person: trimmedPerson,
      amount: parsedAmount,
      note: note || null,
      dueDate: parseDate(dueDate),
      details: details || undefined,
      userId: req.userId,
    },
  });
  return res.status(201).json(receivable);
}

async function collectReceivable(req, res) {
  const { id } = req.params;
  const { amount } = req.body;
  const parsedAmount = parseFloat(amount);
  if (!parsedAmount || parsedAmount <= 0) {
    return res.status(400).json({ error: 'Monto válido es obligatorio' });
  }
  const receivable = await prisma.receivable.findFirst({
    where: { id, userId: req.userId },
  });
  if (!receivable) return res.status(404).json({ error: 'Cobro no encontrado' });

  const newAmount = Math.max(0, Number(receivable.amount) - parsedAmount);
  const updated = await prisma.receivable.update({
    where: { id },
    data: {
      amount: newAmount,
      status: newAmount <= 0 ? 'collected' : 'pending',
    },
  });
  return res.json(updated);
}

async function updateReceivable(req, res) {
  const { id } = req.params;
  const { person, amount, note, dueDate, status, details } = req.body;

  const receivable = await prisma.receivable.findFirst({
    where: { id, userId: req.userId },
  });
  if (!receivable) return res.status(404).json({ error: 'Cobro no encontrado' });

  if (dueDate !== undefined && dueDate !== null && dueDate !== '' && parseDate(dueDate) === null) {
    return res.status(400).json({ error: 'Fecha inválida' });
  }

  const data = {};
  if (person !== undefined) data.person = String(person).trim();
  if (amount !== undefined) {
    const parsed = parseFloat(amount);
    if (Number.isNaN(parsed) || parsed < 0) {
      return res.status(400).json({ error: 'Monto inválido' });
    }
    data.amount = parsed;
  }
  if (note !== undefined) data.note = note || null;
  if (dueDate !== undefined) data.dueDate = parseDate(dueDate);
  if (status !== undefined) {
    data.status = status === 'collected' ? 'collected' : 'pending';
  }
  if (details !== undefined) data.details = details;

  const updated = await prisma.receivable.update({ where: { id }, data });
  return res.json(updated);
}

async function deleteReceivable(req, res) {
  const { id } = req.params;
  const receivable = await prisma.receivable.findFirst({
    where: { id, userId: req.userId },
  });
  if (!receivable) return res.status(404).json({ error: 'Cobro no encontrado' });
  await prisma.receivable.delete({ where: { id } });
  return res.json({ ok: true });
}

module.exports = {
  listReceivables,
  createReceivable,
  collectReceivable,
  updateReceivable,
  deleteReceivable,
};
