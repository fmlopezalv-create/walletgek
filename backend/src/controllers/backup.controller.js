const prisma = require('../lib/prisma');

// Exporta todos los datos del usuario como JSON (copia de seguridad).
async function exportBackup(req, res) {
  const userId = req.userId;

  const [user, categories, transactions, debts, debtPayments] =
    await Promise.all([
      prisma.user.findUnique({
        where: { id: userId },
        select: {
          id: true, email: true, name: true, currency: true,
          country: true, monthlyBudget: true, isPremium: true,
        },
      }),
      prisma.category.findMany({
        where: { userId },
        orderBy: { name: 'asc' },
      }),
      prisma.transaction.findMany({
        where: { userId },
        orderBy: { date: 'asc' },
      }),
      prisma.debt.findMany({
        where: { userId },
        orderBy: { createdAt: 'asc' },
      }),
      prisma.debtPayment.findMany({
        where: { debt: { userId } },
        orderBy: { date: 'asc' },
      }),
    ]);

  const backup = {
    app: 'walletgek',
    version: 1,
    exportedAt: new Date().toISOString(),
    profile: {
      name: user?.name,
      currency: user?.currency,
      country: user?.country,
      monthlyBudget: user?.monthlyBudget != null ? user.monthlyBudget.toString() : null,
      isPremium: user?.isPremium ?? false,
    },
    categories: categories.map((c) => ({
      id: c.id, name: c.name, type: c.type, color: c.color,
      monthlyBudget: c.monthlyBudget != null ? c.monthlyBudget.toString() : null,
    })),
    transactions: transactions.map((t) => ({
      id: t.id, amount: t.amount.toString(), type: t.type,
      note: t.note, date: t.date.toISOString(), categoryId: t.categoryId,
    })),
    debts: debts.map((d) => ({
      id: d.id, name: d.name, type: d.type, color: d.color,
      balance: d.balance.toString(), interestRate: d.interestRate.toString(),
      minimumPayment: d.minimumPayment.toString(),
      dueDate: d.dueDate ? d.dueDate.toISOString() : null,
      institution: d.institution, status: d.status, monthsLate: d.monthsLate,
      paymentType: d.paymentType, totalInstallments: d.totalInstallments,
      paidInstallments: d.paidInstallments, details: d.details,
    })),
    debtPayments: debtPayments.map((p) => ({
      id: p.id, amount: p.amount.toString(),
      date: p.date.toISOString(), debtId: p.debtId,
    })),
  };

  return res.json(backup);
}

// Restaura los datos desde un backup (reemplaza todo lo existente).
async function importBackup(req, res) {
  const userId = req.userId;
  const backup = req.body;

  if (!backup || typeof backup !== 'object') {
    return res.status(400).json({ error: 'Backup inválido' });
  }
  if (backup.app !== 'walletgek') {
    return res.status(400).json({ error: 'Este archivo no es un backup de walletgek' });
  }

  try {
    await prisma.$transaction(async (tx) => {
      // 1. Borrar datos existentes del usuario.
      await tx.debtPayment.deleteMany({ where: { debt: { userId } } });
      await tx.debt.deleteMany({ where: { userId } });
      await tx.transaction.deleteMany({ where: { userId } });
      await tx.category.deleteMany({ where: { userId } });

      // 2. Perfil.
      const profile = backup.profile ?? {};
      const profileData = {};
      if (profile.name !== undefined) profileData.name = profile.name;
      if (profile.currency) profileData.currency = profile.currency;
      if (profile.country) profileData.country = profile.country;
      if (profile.monthlyBudget !== undefined) {
        profileData.monthlyBudget = profile.monthlyBudget != null
          ? parseFloat(profile.monthlyBudget) : null;
      }
      if (Object.keys(profileData).length > 0) {
        await tx.user.update({ where: { id: userId }, data: profileData });
      }

      // 3. Categorías (mapeo de id viejo -> id nuevo para preservar relaciones).
      const categoryMap = {};
      const cats = Array.isArray(backup.categories) ? backup.categories : [];
      for (const c of cats) {
        const created = await tx.category.create({
          data: {
            name: c.name || 'Categoría',
            type: c.type === 'income' ? 'income' : 'expense',
            color: c.color ?? null,
            monthlyBudget: c.monthlyBudget != null ? parseFloat(c.monthlyBudget) : null,
            userId,
          },
        });
        if (c.id) categoryMap[c.id] = created.id;
      }

      // 4. Transacciones.
      const txs = Array.isArray(backup.transactions) ? backup.transactions : [];
      for (const t of txs) {
        await tx.transaction.create({
          data: {
            amount: parseFloat(t.amount) || 0,
            type: t.type === 'income' ? 'income' : 'expense',
            note: t.note ?? null,
            date: t.date ? new Date(t.date) : new Date(),
            categoryId: t.categoryId ? categoryMap[t.categoryId] ?? null : null,
            userId,
          },
        });
      }

      // 5. Deudas.
      const debtMap = {};
      const debts = Array.isArray(backup.debts) ? backup.debts : [];
      for (const d of debts) {
        const created = await tx.debt.create({
          data: {
            name: d.name || 'Deuda',
            type: d.type || 'other',
            color: d.color ?? null,
            balance: parseFloat(d.balance) || 0,
            interestRate: parseFloat(d.interestRate) || 0,
            minimumPayment: parseFloat(d.minimumPayment) || 0,
            dueDate: d.dueDate ? new Date(d.dueDate) : null,
            institution: d.institution ?? null,
            status: d.status || 'up_to_date',
            monthsLate: d.monthsLate ?? 0,
            paymentType: d.paymentType ?? null,
            totalInstallments: d.totalInstallments ?? null,
            paidInstallments: d.paidInstallments ?? 0,
            details: d.details ?? undefined,
            userId,
          },
        });
        if (d.id) debtMap[d.id] = created.id;
      }

      // 6. Pagos de deuda.
      const payments = Array.isArray(backup.debtPayments) ? backup.debtPayments : [];
      for (const p of payments) {
        const debtId = p.debtId ? debtMap[p.debtId] : null;
        if (!debtId) continue;
        await tx.debtPayment.create({
          data: {
            amount: parseFloat(p.amount) || 0,
            date: p.date ? new Date(p.date) : new Date(),
            debtId,
          },
        });
      }
    });
    return res.json({ ok: true });
  } catch (e) {
    console.error(e);
    return res.status(500).json({ error: 'No se pudo restaurar el backup' });
  }
}

// Borra todos los datos financieros del usuario (no elimina la cuenta).
async function clearAll(req, res) {
  const userId = req.userId;
  await prisma.$transaction(async (tx) => {
    await tx.debtPayment.deleteMany({ where: { debt: { userId } } });
    await tx.debt.deleteMany({ where: { userId } });
    await tx.transaction.deleteMany({ where: { userId } });
    await tx.category.deleteMany({ where: { userId } });
    await tx.user.update({
      where: { id: userId },
      data: { monthlyBudget: null },
    });
  });
  return res.json({ ok: true });
}

module.exports = { exportBackup, importBackup, clearAll };
