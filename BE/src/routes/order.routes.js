const { Router } = require('express');
const {
	createOrder,
	createOrderByAdmin,
	getAllOrders,
	getMyOrders,
	getOrderById,
	updateOrderStatus,
	endRental
} = require('../controllers/order.controller.js');
const { protect, allowRoles, allowUserOnly } = require('../middlewares/auth.middleware.js');

const router = Router();

router.post('/', protect, allowUserOnly, createOrder);
router.post('/create', protect, allowUserOnly, createOrder);
router.post('/admin/create', protect, allowRoles('admin'), createOrderByAdmin);
router.get('/me', protect, getMyOrders);
router.get('/user', protect, getMyOrders);
router.get('/admin/all', protect, allowRoles('admin'), getAllOrders);
router.get('/:id', protect, getOrderById);
router.patch('/:id/status', protect, allowRoles('admin'), updateOrderStatus);
router.post('/:id/end-rental', protect, allowRoles('admin'), endRental);

module.exports = router;
