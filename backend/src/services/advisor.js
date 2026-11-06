const prisma = require('../lib/prisma');

// Asesor financiero con IA (DeepSeek).
// Construye un contexto con los datos reales del usuario y pide un consejo
// conciso y accionable. No reemplaza un asesor humano certificado.

const DEEPSEEK_URL = 'https://api.deepseek.com/chat/completions';
const DEEPSEEK_MODEL = 'deepseek-chat';

function round2(v) {
  return Math.round(v * 100) / 100;
}

async function buildContext(userId) {
  const now = new Date();
  const start = new Date(now.getFullYear(), now.getMonth(), 1);
  const end = new Date(now.getFullYear(), now.getMonth() + 1, 1);

  const [user, incAgg, expAgg, debts, cats] = await Promise.all([
    prisma.user.findUnique({ where: { id: userId } }),
    prisma.transaction.aggregate({
      where: { userId, type: 'income', date: { gte: start, lt: end } },
      _sum: { amount: true },
    }),
    prisma.transaction.aggregate({
      where: { userId, type: 'expense', date: { gte: start, lt: end } },
      _sum: { amount: true },
    }),
    prisma.debt.findMany({
      where: { userId },
      orderBy: { balance: 'desc' },
      select: { name: true, balance: true, interestRate: true, minimumPayment: true },
    }),
    prisma.category.findMany({
      where: { userId, type: 'expense' },
      select: { name: true, monthlyBudget: true },
    }),
  ]);

  const income = Number(incAgg._sum.amount || 0);
  const expense = Number(expAgg._sum.amount || 0);
  const debtTotal = debts.reduce((s, d) => s + Number(d.balance), 0);
  const debtMonthly = debts.reduce((s, d) => s + Number(d.minimumPayment), 0);

  const debtsText = debts.length
    ? debts
        .map(
          (d) =>
            `- ${d.name}: saldo ${round2(Number(d.balance))}, interés ${Number(
              d.interestRate,
            )}% anual, pago mínimo ${round2(Number(d.minimumPayment))}`,
        )
        .join('\n')
    : '- Sin deudas registradas';

  const budgetText = (user?.monthlyBudget
    ? `Presupuesto mensual global: ${Number(user.monthlyBudget)}`
    : 'Sin presupuesto mensual global definido');

  return {
    moneda: user?.currency || 'EUR',
    pais: user?.country || 'ES',
    mes: `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
    ingresos: round2(income),
    gastos: round2(expense),
    balance: round2(income - expense),
    deudaTotal: round2(debtTotal),
    pagoMensualDeuda: round2(debtMonthly),
    deudas: debtsText,
    presupuesto: budgetText,
  };
}

function systemPrompt(ctx) {
  return [
    'Eres un asesor financiero personal dentro de la app "WalletGek".',
    'Hablas en español, de forma clara, breve y sin tecnicismos.',
    'Responde máximo en 3 párrafos cortos y, si ayuda, con 2-4 viñetas accionables.',
    'Sé concreto usando los datos del usuario. No inventes cifras.',
    'Si detectas un riesgo (deuda alta, gasto mayor que ingreso, sin ahorro), dilo con calma y propón un siguiente paso simple.',
    'Termina con una pregunta o una acción sugerida. No pidas más datos de los que ya tienes.',
    'Recuerda que no eres un sustituto de un asesor financiero certificado.',
    '',
    `Contexto del usuario (mes actual ${ctx.mes}, moneda ${ctx.moneda}, país ${ctx.pais}):`,
    `- Ingresos: ${ctx.ingresos}`,
    `- Gastos: ${ctx.gastos}`,
    `- Balance del mes: ${ctx.balance}`,
    `- Deuda total: ${ctx.deudaTotal}`,
    `- Pago mensual de deudas: ${ctx.pagoMensualDeuda}`,
    `- Deudas:\n${ctx.deudas}`,
    `- ${ctx.presupuesto}`,
  ].join('\n');
}

async function chat(userId, message) {
  const ctx = await buildContext(userId);

  const body = {
    model: DEEPSEEK_MODEL,
    messages: [
      { role: 'system', content: systemPrompt(ctx) },
      { role: 'user', content: message },
    ],
    temperature: 0.6,
    max_tokens: 600,
  };

  const apiKey = process.env.DEEPSEEK_API_KEY;
  if (!apiKey) {
    throw Object.assign(new Error('Falta configurar DEEPSEEK_API_KEY'), {
      statusCode: 500,
    });
  }

  const res = await fetch(DEEPSEEK_URL, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
    },
    body: JSON.stringify(body),
  });

  if (!res.ok) {
    const text = await res.text();
    throw Object.assign(new Error(`Error de DeepSeek: ${text}`), {
      statusCode: 502,
    });
  }

  const data = await res.json();
  const content = data?.choices?.[0]?.message?.content;
  if (!content) {
    throw Object.assign(new Error('Respuesta vacía de DeepSeek'), {
      statusCode: 502,
    });
  }
  return { reply: content };
}

module.exports = { chat, buildContext };
