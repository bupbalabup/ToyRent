import Toy from '../models/toy.model.js';
import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';

export const createToy = asyncHandler(async (req, res) => {
  const { name, rentalPricePerDay, stock } = req.body;

  if (!name || rentalPricePerDay === undefined || stock === undefined) {
    throw new AppError('name, rentalPricePerDay and stock are required', 400);
  }

  const toy = await Toy.create(req.body);
  return sendResponse(res, 201, 'Toy created', { toy });
});

export const getToys = asyncHandler(async (req, res) => {
  const page = Math.max(Number(req.query.page) || 1, 1);
  const limit = Math.min(Math.max(Number(req.query.limit) || 10, 1), 100);
  const skip = (page - 1) * limit;

  const query = {};

  if (req.query.categoryId) {
    query.categoryId = req.query.categoryId;
  }

  if (req.query.isActive !== undefined) {
    query.isActive = req.query.isActive === 'true';
  }

  if (req.query.q) {
    query.$text = { $search: req.query.q };
  }

  const [toys, total] = await Promise.all([
    Toy.find(query)
      .populate('categoryId')
      .sort(req.query.q ? { score: { $meta: 'textScore' } } : { createdAt: -1 })
      .skip(skip)
      .limit(limit),
    Toy.countDocuments(query)
  ]);

  return sendResponse(res, 200, 'Toys fetched', {
    items: toys,
    pagination: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit)
    }
  });
});

export const getToyById = asyncHandler(async (req, res) => {
  const toy = await Toy.findById(req.params.id).populate('categoryId');

  if (!toy) {
    throw new AppError('Toy not found', 404);
  }

  return sendResponse(res, 200, 'Toy fetched', { toy });
});

export const updateToy = asyncHandler(async (req, res) => {
  const toy = await Toy.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true
  });

  if (!toy) {
    throw new AppError('Toy not found', 404);
  }

  return sendResponse(res, 200, 'Toy updated', { toy });
});

export const deleteToy = asyncHandler(async (req, res) => {
  const toy = await Toy.findByIdAndDelete(req.params.id);

  if (!toy) {
    throw new AppError('Toy not found', 404);
  }

  return sendResponse(res, 200, 'Toy deleted', { toyId: toy._id });
});
