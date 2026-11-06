const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { budgetSummary } = require('../controllers/budget.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/summary', budgetSummary);

module.exports = router;
