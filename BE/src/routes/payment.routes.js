import { Router } from 'express';
import { checkoutPayment } from '../controllers/payment.controller.js';
import { protect } from '../middlewares/auth.middleware.js';

const router = Router();

router.post('/checkout', protect, checkoutPayment);

export default router;
