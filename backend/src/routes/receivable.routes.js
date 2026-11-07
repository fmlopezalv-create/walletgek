const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const {
  listReceivables,
  createReceivable,
  collectReceivable,
  updateReceivable,
  deleteReceivable,
} = require('../controllers/receivable.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/', listReceivables);
router.post('/', createReceivable);
router.post('/:id/collect', collectReceivable);
router.patch('/:id', updateReceivable);
router.delete('/:id', deleteReceivable);

module.exports = router;
