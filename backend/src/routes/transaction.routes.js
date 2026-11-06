const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const {
  listTransactions,
  createTransaction,
  updateTransaction,
  deleteTransaction,
} = require('../controllers/transaction.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/', listTransactions);
router.post('/', createTransaction);
router.patch('/:id', updateTransaction);
router.delete('/:id', deleteTransaction);

module.exports = router;
