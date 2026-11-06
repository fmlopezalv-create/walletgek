const express = require('express');
const cors = require('cors');
const authRoutes = require('./routes/auth.routes');
const categoryRoutes = require('./routes/category.routes');
const transactionRoutes = require('./routes/transaction.routes');
const userRoutes = require('./routes/user.routes');
const debtRoutes = require('./routes/debt.routes');
const budgetRoutes = require('./routes/budget.routes');
const dashboardRoutes = require('./routes/dashboard.routes');
const advisorRoutes = require('./routes/advisor.routes');
const backupRoutes = require('./routes/backup.routes');

const app = express();
app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => res.json({ status: 'ok' }));
app.use('/auth', authRoutes);
app.use('/categories', categoryRoutes);
app.use('/transactions', transactionRoutes);
app.use('/users', userRoutes);
app.use('/debts', debtRoutes);
app.use('/budget', budgetRoutes);
app.use('/dashboard', dashboardRoutes);
app.use('/advisor', advisorRoutes);
app.use('/backup', backupRoutes);

// Manejo de errores global (F6)
app.use((err, req, res, next) => {
  console.error(err);
  res.status(500).json({ error: 'Error interno del servidor' });
});

module.exports = app;
