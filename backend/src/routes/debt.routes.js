const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const {
  listDebts,
  createDebt,
  payDebt,
  deleteDebt,
  debtPlan,
  updateDebt,
} = require('../controllers/debt.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/', listDebts);
router.post('/', createDebt);
router.get('/plan', debtPlan);
router.post('/:id/payments', payDebt);
router.patch('/:id', updateDebt);
router.delete('/:id', deleteDebt);

module.exports = router;
