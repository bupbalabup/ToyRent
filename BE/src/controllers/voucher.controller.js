import Voucher from '../models/voucher.model.js';
import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';

export const createVoucher = asyncHandler(async (req, res) => {
  const { code, discountPercent, maxDiscount, minOrderValue, expiredAt, usageLimit } = req.body;

  if (!code || discountPercent === undefined || maxDiscount === undefined || minOrderValue === undefined || !expiredAt || usageLimit === undefined) {
    throw new AppError('Missing required voucher fields', 400);
  }

  const voucher = await Voucher.create(req.body);
  return sendResponse(res, 201, 'Voucher created', { voucher });
});

export const getVouchers = asyncHandler(async (req, res) => {
  const vouchers = await Voucher.find().sort({ createdAt: -1 });
  return sendResponse(res, 200, 'Vouchers fetched', { vouchers });
});

export const getVoucherById = asyncHandler(async (req, res) => {
  const voucher = await Voucher.findById(req.params.id);

  if (!voucher) {
    throw new AppError('Voucher not found', 404);
  }

  return sendResponse(res, 200, 'Voucher fetched', { voucher });
});

export const updateVoucher = asyncHandler(async (req, res) => {
  const voucher = await Voucher.findByIdAndUpdate(req.params.id, req.body, {
    new: true,
    runValidators: true
  });

  if (!voucher) {
    throw new AppError('Voucher not found', 404);
  }

  return sendResponse(res, 200, 'Voucher updated', { voucher });
});

export const deleteVoucher = asyncHandler(async (req, res) => {
  const voucher = await Voucher.findByIdAndDelete(req.params.id);

  if (!voucher) {
    throw new AppError('Voucher not found', 404);
  }

  return sendResponse(res, 200, 'Voucher deleted', { voucherId: voucher._id });
});
