import mongoose from 'mongoose';
import Review from '../models/review.model.js';
import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';
import { refreshToyRating } from '../services/review.service.js';

export const createReview = asyncHandler(async (req, res) => {
  const { toyId, rating, comment } = req.body;

  if (!toyId || rating === undefined) {
    throw new AppError('toyId and rating are required', 400);
  }

  if (!mongoose.Types.ObjectId.isValid(toyId)) {
    throw new AppError('Invalid toyId', 400);
  }

  const session = await mongoose.startSession();
  let review = null;

  try {
    await session.withTransaction(async () => {
      const [created] = await Review.create(
        [{ userId: req.user._id, toyId, rating, comment }],
        { session }
      );
      review = created;
      await refreshToyRating(toyId, session);
    });
  } finally {
    session.endSession();
  }

  return sendResponse(res, 201, 'Review created', { review });
});

export const getReviewsByToy = asyncHandler(async (req, res) => {
  const reviews = await Review.find({ toyId: req.params.toyId })
    .populate('userId', 'name avatar')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, 'Reviews fetched', { reviews });
});

export const updateReview = asyncHandler(async (req, res) => {
  const review = await Review.findById(req.params.id);

  if (!review) {
    throw new AppError('Review not found', 404);
  }

  if (review.userId.toString() !== req.user._id.toString()) {
    throw new AppError('Forbidden', 403);
  }

  if (req.body.rating !== undefined) {
    review.rating = req.body.rating;
  }

  if (req.body.comment !== undefined) {
    review.comment = req.body.comment;
  }

  await review.save();
  await refreshToyRating(review.toyId);

  return sendResponse(res, 200, 'Review updated', { review });
});

export const deleteReview = asyncHandler(async (req, res) => {
  const review = await Review.findById(req.params.id);

  if (!review) {
    throw new AppError('Review not found', 404);
  }

  const isOwner = review.userId.toString() === req.user._id.toString();

  if (!isOwner && req.user.role !== 'admin') {
    throw new AppError('Forbidden', 403);
  }

  const toyId = review.toyId;
  await review.deleteOne();
  await refreshToyRating(toyId);

  return sendResponse(res, 200, 'Review deleted', { reviewId: review._id });
});
