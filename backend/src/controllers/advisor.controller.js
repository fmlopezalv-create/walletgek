const prisma = require('../lib/prisma');
const { chat } = require('../services/advisor');

async function askAdvisor(req, res) {
  const user = await prisma.user.findUnique({
    where: { id: req.userId },
    select: { isPremium: true },
  });
  if (!user?.isPremium) {
    return res.status(403).json({
      error: 'El asesor financiero es una función Premium. Activa Premium para usarlo.',
    });
  }

  const { message } = req.body;
  if (!message || !message.trim()) {
    return res.status(400).json({ error: 'Escribe un mensaje' });
  }
  const text = message.trim();
  if (text.length > 1000) {
    return res.status(400).json({
      error: 'El mensaje es demasiado largo (máximo 1000 caracteres)',
    });
  }

  try {
    const { reply } = await chat(req.userId, text);
    return res.json({ reply });
  } catch (e) {
    const status = e.statusCode || 500;
    return res.status(status).json({ error: e.message });
  }
}

module.exports = { askAdvisor };
