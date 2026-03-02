import { Router } from 'express';
import {
  createVoucher,
  getVouchers,
  getVoucherById,
  updateVoucher,
  deleteVoucher
} from '../controllers/voucher.controller.js';
import { protect, allowRoles } from '../middlewares/auth.middleware.js';
import validateObjectId from '../middlewares/validateObjectId.middleware.js';

const router = Router();

router.get('/', protect, allowRoles('admin'), getVouchers);
router.get('/:id', protect, allowRoles('admin'), validateObjectId('id'), getVoucherById);
router.post('/', protect, allowRoles('admin'), createVoucher);
router.put('/:id', protect, allowRoles('admin'), validateObjectId('id'), updateVoucher);
router.delete('/:id', protect, allowRoles('admin'), validateObjectId('id'), deleteVoucher);

export default router;
