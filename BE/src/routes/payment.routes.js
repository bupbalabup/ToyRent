const { Router } = require('express');
const { checkoutPayment, syncPaypalPayment, capturePaypalPayment, expireOrderPayment } = require('../controllers/payment.controller.js');
const { protect } = require('../middlewares/auth.middleware.js');

const router = Router();

router.post('/checkout', protect, checkoutPayment);
router.get('/paypal/orders/:orderId/sync', protect, syncPaypalPayment);
router.post('/paypal/orders/:orderId/capture', protect, capturePaypalPayment);
router.post('/orders/:orderId/expire', protect, expireOrderPayment);

module.exports = router;
