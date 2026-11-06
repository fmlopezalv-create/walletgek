const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { getProfile, updateProfile, activatePremium } = require('../controllers/user.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/me', getProfile);
router.patch('/me', updateProfile);
router.post('/me/premium', activatePremium);

module.exports = router;
