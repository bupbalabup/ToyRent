import Category from '../models/category.model.js';
import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';

export const createCategory = asyncHandler(async (req, res) => {
  const { name, icon } = req.body;

  if (!name) {
    throw new AppError('name is required', 400);
  }

  const category = await Category.create({ name, icon });
  return sendResponse(res, 201, 'Category created', { category });
});

export const getCategories = asyncHandler(async (req, res) => {
  const categories = await Category.find().sort({ createdAt: -1 });
  return sendResponse(res, 200, 'Categories fetched', { categories });
});

export const getCategoryById = asyncHandler(async (req, res) => {
  const category = await Category.findById(req.params.id);

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  return sendResponse(res, 200, 'Category fetched', { category });
});

export const updateCategory = asyncHandler(async (req, res) => {
  const category = await Category.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true
  });

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  return sendResponse(res, 200, 'Category updated', { category });
});

export const deleteCategory = asyncHandler(async (req, res) => {
  const category = await Category.findByIdAndDelete(req.params.id);

  if (!category) {
    throw new AppError('Category not found', 404);
  }

  return sendResponse(res, 200, 'Category deleted', { categoryId: category._id });
});
