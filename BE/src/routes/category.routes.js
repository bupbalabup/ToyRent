const { Router } = require('express');
const { createCategory, getCategories, getCategoryById, updateCategory, deleteCategory } = require('../controllers/category.controller.js');
const { protect, allowRoles } = require('../middlewares/auth.middleware.js');

const router = Router();

router.get('/', getCategories);
router.get('/:id', getCategoryById);
router.post('/', protect, allowRoles('admin'), createCategory);
router.put('/:id', protect, allowRoles('admin'), updateCategory);
router.delete('/:id', protect, allowRoles('admin'), deleteCategory);

module.exports = router;
