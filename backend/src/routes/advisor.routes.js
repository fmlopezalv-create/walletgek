const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { advisorRateLimit } = require('../middleware/rateLimit');
const { askAdvisor } = require('../controllers/advisor.controller');
const router = express.Router();

router.use(authMiddleware);
router.post('/chat', advisorRateLimit, askAdvisor);

module.exports = router;
