const { Router } = require('express');
const { createOrder, getAllOrders, getMyOrders, getOrderById, updateOrderStatus } = require('../controllers/order.controller.js');
const { protect, allowRoles, allowUserOnly } = require('../middlewares/auth.middleware.js');

const router = Router();

router.post('/', protect, allowUserOnly, createOrder);
router.post('/create', protect, allowUserOnly, createOrder);
router.get('/me', protect, getMyOrders);
router.get('/user', protect, getMyOrders);
router.get('/admin/all', protect, allowRoles('admin'), getAllOrders);
router.get('/:id', protect, getOrderById);
router.patch('/:id/status', protect, allowRoles('admin'), updateOrderStatus);

module.exports = router;
