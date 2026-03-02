import { Router } from 'express';
import {
  createCategory,
  getCategories,
  getCategoryById,
  updateCategory,
  deleteCategory
} from '../controllers/category.controller.js';
import { protect, allowRoles } from '../middlewares/auth.middleware.js';
import validateObjectId from '../middlewares/validateObjectId.middleware.js';

const router = Router();

router.get('/', getCategories);
router.get('/:id', validateObjectId('id'), getCategoryById);
router.post('/', protect, allowRoles('admin'), createCategory);
router.put('/:id', protect, allowRoles('admin'), validateObjectId('id'), updateCategory);
router.delete('/:id', protect, allowRoles('admin'), validateObjectId('id'), deleteCategory);

export default router;
