const { Router } = require('express');
const { 
  getMyNotifications, 
  getUnreadCount,
  markNotificationAsRead,
  markAllAsRead
} = require('../controllers/notification.controller.js');
const { protect } = require('../middlewares/auth.middleware.js');

const router = Router();

router.get('/', protect, getMyNotifications);
router.get('/unread-count', protect, getUnreadCount);
router.patch('/:id/read', protect, markNotificationAsRead);
router.patch('/read-all', protect, markAllAsRead);

module.exports = router;
