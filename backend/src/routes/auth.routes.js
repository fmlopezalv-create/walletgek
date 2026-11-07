const express = require('express');
const { register, login } = require('../controllers/auth.controller');
const { rateLimit } = require('../middleware/rateLimit');
const router = express.Router();

router.post('/register', rateLimit, register);
router.post('/login', rateLimit, login);

module.exports = router;
