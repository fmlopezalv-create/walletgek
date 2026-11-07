function computeDebtPlan(debts, strategy, monthlyBudget) {
  const ordered = [...debts].sort((a, b) => {
    if (strategy === 'avalanche') {
      return Number(b.interestRate) - Number(a.interestRate);
    }
    return Number(a.balance) - Number(b.balance); // snowball: menor saldo primero
  });

  const state = ordered.map((d) => ({
    name: d.name,
    balance: Number(d.balance),
    interestRate: Number(d.interestRate),
    minimumPayment: Number(d.minimumPayment),
    paidOffMonth: null,
  }));

  let month = 0;
  let totalInterest = 0;
  const maxMonths = 600;

  // Si el presupuesto es menor que la suma de mínimos, al menos se pagan los
  // mínimos (no se deja disponible negativo, que corrompería el cálculo).
  const totalMinimums = state.reduce(
    (sum, d) => sum + Math.min(d.minimumPayment, d.balance),
    0,
  );
  const effectiveBudget = Math.max(monthlyBudget, totalMinimums);

  while (state.some((d) => d.balance > 0.01) && month < maxMonths) {
    month++;
    let available = effectiveBudget;

    // 1. Aplicar interés mensual (tasa anual / 12)
    for (const d of state) {
      if (d.balance > 0.01) {
        const interest = d.balance * (d.interestRate / 100 / 12);
        d.balance += interest;
        totalInterest += interest;
      }
    }

    // 2. Pagar el mínimo de cada deuda
    for (const d of state) {
      if (d.balance <= 0.01) continue;
      const pay = Math.min(d.minimumPayment, d.balance);
      d.balance -= pay;
      available -= pay;
    }

    // 3. Pago extra a la deuda prioritaria (según estrategia)
    if (available > 0) {
      for (const d of state) {
        if (available <= 0) break;
        if (d.balance <= 0.01) continue;
        const extra = Math.min(available, d.balance);
        d.balance -= extra;
        available -= extra;
      }
    }

    // Registrar el mes en que se liquida cada deuda
    for (const d of state) {
      if (d.paidOffMonth === null && d.balance <= 0.01) {
        d.paidOffMonth = month;
      }
    }
  }

  return {
    strategy,
    monthlyBudget: effectiveBudget,
    monthsToPayoff: month,
    totalInterest: Math.round(totalInterest * 100) / 100,
    schedule: state.map((d) => ({
      name: d.name,
      paidOffMonth: d.paidOffMonth,
    })),
  };
}

module.exports = { computeDebtPlan };
