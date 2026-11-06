const express = require('express');
const { authMiddleware } = require('../middleware/auth');
const { listCategories, createCategory, updateCategory } = require('../controllers/category.controller');
const router = express.Router();

router.use(authMiddleware);
router.get('/', listCategories);
router.post('/', createCategory);
router.patch('/:id', updateCategory);

module.exports = router;
