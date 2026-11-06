const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { askAdvisor } = require('../controllers/advisor.controller');
const router = express.Router();

router.use(authMiddleware);
router.post('/chat', askAdvisor);

module.exports = router;
