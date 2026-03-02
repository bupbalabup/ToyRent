import { Router } from 'express';
import {
  createOrder,
  getMyOrders,
  getOrderById,
  updateOrderStatus
} from '../controllers/order.controller.js';
import { protect, allowRoles } from '../middlewares/auth.middleware.js';
import validateObjectId from '../middlewares/validateObjectId.middleware.js';

const router = Router();

router.post('/', protect, createOrder);
router.get('/me', protect, getMyOrders);
router.get('/:id', protect, validateObjectId('id'), getOrderById);
router.patch('/:id/status', protect, allowRoles('admin'), validateObjectId('id'), updateOrderStatus);

export default router;
