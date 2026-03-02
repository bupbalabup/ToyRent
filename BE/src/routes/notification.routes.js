import { Router } from 'express';
import {
  getMyNotifications,
  markNotificationAsRead
} from '../controllers/notification.controller.js';
import { protect } from '../middlewares/auth.middleware.js';
import validateObjectId from '../middlewares/validateObjectId.middleware.js';

const router = Router();

router.get('/', protect, getMyNotifications);
router.patch('/:id/read', protect, validateObjectId('id'), markNotificationAsRead);

export default router;
