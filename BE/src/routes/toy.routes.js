import { Router } from 'express';
import {
  createToy,
  getToys,
  getToyById,
  updateToy,
  deleteToy
} from '../controllers/toy.controller.js';
import { protect, allowRoles } from '../middlewares/auth.middleware.js';
import validateObjectId from '../middlewares/validateObjectId.middleware.js';

const router = Router();

router.get('/', getToys);
router.get('/:id', validateObjectId('id'), getToyById);
router.post('/', protect, allowRoles('admin'), createToy);
router.put('/:id', protect, allowRoles('admin'), validateObjectId('id'), updateToy);
router.delete('/:id', protect, allowRoles('admin'), validateObjectId('id'), deleteToy);

export default router;
