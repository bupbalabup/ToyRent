import { Router } from 'express';
import {
  createReview,
  getReviewsByToy,
  updateReview,
  deleteReview
} from '../controllers/review.controller.js';
import { protect } from '../middlewares/auth.middleware.js';
import validateObjectId from '../middlewares/validateObjectId.middleware.js';

const router = Router();

router.get('/toy/:toyId', validateObjectId('toyId'), getReviewsByToy);
router.post('/', protect, createReview);
router.put('/:id', protect, validateObjectId('id'), updateReview);
router.delete('/:id', protect, validateObjectId('id'), deleteReview);

export default router;
