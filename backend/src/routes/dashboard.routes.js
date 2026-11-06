const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { healthSummary, homeSummary } = require('../controllers/dashboard.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/health', healthSummary);
router.get('/home', homeSummary);

module.exports = router;
