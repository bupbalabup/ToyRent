const Order = require('../models/order.model.js');
const mongoose = require('mongoose');
const {
  createOrderWithTransaction,
  createAdminOrderWithTransaction,
  updateOrderStatusWithNotification,
  endRentalOrder,
  buildOrderPopulatedQuery,
  normalizeOrderStatus
} = require('../services/order.service.js');

const ORDER_ITEM_TOY_POPULATE = { path: 'items.toyId', select: 'name images description' };
const ORDER_USER_POPULATE = { path: 'userId', select: 'name email phone avatar role' };

const createOrder = async (req, res, next) => {
  try {
    if (req.user.role === 'admin') {
      return res.status(403).json({ success: false, message: 'Admin cannot place orders', data: {} });
    }

    const {
      items,
      rentalStartDate,
      rentalEndDate,
      rentalDurationHours,
      paymentMethod
    } = req.body;

    const order = await createOrderWithTransaction({
      userId: req.user._id,
      items,
      rentalStartDate,
      rentalEndDate,
      rentalDurationHours,
      paymentMethod
    });

    return res.status(201).json({ success: true, message: 'Order created', data: { order } });
  } catch (error) {
    return next(error);
  }
};

const getMyOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({ userId: req.user._id })
      .populate(ORDER_USER_POPULATE)
      .populate(ORDER_ITEM_TOY_POPULATE)
      .sort({ createdAt: -1 });

    return res.status(200).json({ success: true, message: 'Orders fetched', data: { orders } });
  } catch (error) {
    return next(error);
  }
};

const getOrderById = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid order id', data: {} });
    }

    const order = await buildOrderPopulatedQuery(req.params.id);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found', data: {} });
    }

    const ownerId = order.userId?._id ? order.userId._id.toString() : order.userId.toString();
    if (req.user.role !== 'admin' && ownerId !== req.user._id.toString()) {
      return res.status(403).json({ success: false, message: 'Forbidden', data: {} });
    }

    return res.status(200).json({ success: true, message: 'Order fetched', data: { order } });
  } catch (error) {
    return next(error);
  }
};

const updateOrderStatus = async (req, res, next) => {
  try {
    const { orderStatus } = req.body;

    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid order id', data: {} });
    }

    if (!orderStatus || typeof orderStatus !== 'string') {
      return res.status(400).json({
        success: false,
        message: 'orderStatus is required and must be a string',
        data: {}
      });
    }

    await updateOrderStatusWithNotification({
      orderId: req.params.id,
      status: orderStatus
    });

    const updatedOrder = await buildOrderPopulatedQuery(req.params.id);
    return res.status(200).json({
      success: true,
      message: 'Order status updated',
      data: { order: updatedOrder }
    });
  } catch (error) {
    if (error?.statusCode === 403) {
      return res.status(403).json({ success: false, message: error.message, data: {} });
    }
    return next(error);
  }
};

const getAllOrders = async (req, res, next) => {
  try {
    const { status } = req.query;
    const query = {};
    if (status) {
      query.orderStatus = normalizeOrderStatus(status) || status;
    }

    const orders = await Order.find(query)
      .populate(ORDER_USER_POPULATE)
      .populate(ORDER_ITEM_TOY_POPULATE)
      .sort({ createdAt: -1 });

    return res.status(200).json({ success: true, message: 'All orders fetched', data: { orders } });
  } catch (error) {
    return next(error);
  }
};

const createOrderByAdmin = async (req, res, next) => {
  try {
    const { userId, items, rentalType, durationHours } = req.body;

    if (!userId || !Array.isArray(items) || items.length === 0 || !rentalType) {
      return res.status(400).json({
        success: false,
        message: 'userId, items and rentalType are required',
        data: {}
      });
    }

    if (!mongoose.Types.ObjectId.isValid(userId)) {
      return res.status(400).json({ success: false, message: 'Invalid userId', data: {} });
    }

    const hasInvalidItem = items.some((item) => !item?.toyId || !mongoose.Types.ObjectId.isValid(item.toyId) || !Number.isInteger(Number(item.quantity)) || Number(item.quantity) < 1);
    if (hasInvalidItem) {
      return res.status(400).json({ success: false, message: 'Each item must include valid toyId and quantity >= 1', data: {} });
    }

    if (String(rentalType).toUpperCase() === 'HOURLY' && (!Number.isInteger(Number(durationHours)) || Number(durationHours) < 1)) {
      return res.status(400).json({ success: false, message: 'durationHours must be >= 1 for HOURLY rental', data: {} });
    }

    const order = await createAdminOrderWithTransaction({
      userId,
      items,
      rentalType,
      durationHours
    });

    return res.status(201).json({
      success: true,
      message: 'Admin order created',
      data: { order }
    });
  } catch (error) {
    return next(error);
  }
};

const endRental = async (req, res, next) => {
  try {
    if (!mongoose.Types.ObjectId.isValid(req.params.id)) {
      return res.status(400).json({ success: false, message: 'Invalid order id', data: {} });
    }

    const order = await endRentalOrder({ orderId: req.params.id });
    return res.status(200).json({
      success: true,
      message: 'Rental ended successfully',
      data: { order }
    });
  } catch (error) {
    if (error?.statusCode === 403) {
      return res.status(403).json({ success: false, message: error.message, data: {} });
    }
    return next(error);
  }
};

module.exports = {
  createOrder,
  createOrderByAdmin,
  getMyOrders,
  getOrderById,
  updateOrderStatus,
  getAllOrders,
  endRental
};
