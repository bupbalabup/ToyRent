import Order from '../models/order.model.js';
import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';
import { createOrderWithTransaction, updateOrderStatusWithNotification } from '../services/order.service.js';

export const createOrder = asyncHandler(async (req, res) => {
  const {
    items,
    rentalStartDate,
    rentalEndDate,
    voucherCode,
    fulfillmentType,
    shippingAddress,
    paymentMethod
  } = req.body;

  const order = await createOrderWithTransaction({
    userId: req.user._id,
    items,
    rentalStartDate,
    rentalEndDate,
    voucherCode,
    fulfillmentType,
    shippingAddress,
    paymentMethod
  });

  return sendResponse(res, 201, 'Order created', { order });
});

export const getMyOrders = asyncHandler(async (req, res) => {
  const orders = await Order.find({ userId: req.user._id })
    .populate('voucherId')
    .sort({ createdAt: -1 });

  return sendResponse(res, 200, 'Orders fetched', { orders });
});

export const getOrderById = asyncHandler(async (req, res) => {
  const order = await Order.findById(req.params.id).populate('voucherId');

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  if (req.user.role !== 'admin' && order.userId.toString() !== req.user._id.toString()) {
    throw new AppError('Forbidden', 403);
  }

  return sendResponse(res, 200, 'Order fetched', { order });
});

export const updateOrderStatus = asyncHandler(async (req, res) => {
  const { orderStatus } = req.body;

  if (!orderStatus) {
    throw new AppError('orderStatus is required', 400);
  }

  const order = await updateOrderStatusWithNotification({
    orderId: req.params.id,
    status: orderStatus
  });

  return sendResponse(res, 200, 'Order status updated', { order });
});
