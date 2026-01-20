const { Router } = require('express');
const { getMyNotifications, markNotificationAsRead } = require('../controllers/notification.controller.js');
const { protect } = require('../middlewares/auth.middleware.js');

const router = Router();

router.get('/', protect, getMyNotifications);
router.patch('/:id/read', protect, markNotificationAsRead);

module.exports = router;
