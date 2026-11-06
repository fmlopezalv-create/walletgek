const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { exportBackup, importBackup, clearAll } = require('../controllers/backup.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/', exportBackup);
router.post('/restore', importBackup);
router.delete('/all', clearAll);

module.exports = router;
