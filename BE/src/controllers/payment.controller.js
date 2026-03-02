import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';
import { processPaymentCheckout } from '../services/payment.service.js';
import mongoose from 'mongoose';

export const checkoutPayment = asyncHandler(async (req, res) => {
  const { orderId, paymentMethod, rawResponse, returnUrl } = req.body;

  if (!orderId) {
    throw new AppError('orderId is required', 400);
  }

  if (!mongoose.Types.ObjectId.isValid(orderId)) {
    throw new AppError('Invalid orderId', 400);
  }

  if (!paymentMethod) {
    throw new AppError('paymentMethod is required', 400);
  }

  const payment = await processPaymentCheckout({
    orderId,
    paymentMethod,
    rawResponse: rawResponse || null,
    returnUrl: returnUrl || null
  });

  return sendResponse(res, 201, 'Payment processed', payment);
});
