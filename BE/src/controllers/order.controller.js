const Order = require('../models/order.model.js');
const { createOrderWithTransaction, updateOrderStatusWithNotification } = require('../services/order.service.js');

const ORDER_ITEM_TOY_POPULATE = { path: 'items.toyId', select: 'name images description' };

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
      .populate(ORDER_ITEM_TOY_POPULATE)
      .sort({ createdAt: -1 });

    return res.status(200).json({ success: true, message: 'Orders fetched', data: { orders } });
  } catch (error) {
    return next(error);
  }
};

const getOrderById = async (req, res, next) => {
  try {
    const order = await Order.findById(req.params.id).populate(ORDER_ITEM_TOY_POPULATE);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found', data: {} });
    }

    if (req.user.role !== 'admin' && order.userId.toString() !== req.user._id.toString()) {
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

    if (!orderStatus) {
      return res.status(400).json({
        success: false,
        message: 'orderStatus is required',
        data: {}
      });
    }

    const order = await Order.findById(req.params.id);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found', data: {} });
    }

    await updateOrderStatusWithNotification({
      orderId: req.params.id,
      status: orderStatus
    });

    const updatedOrder = await Order.findById(req.params.id).populate(ORDER_ITEM_TOY_POPULATE);
    return res.status(200).json({
      success: true,
      message: 'Order status updated',
      data: { order: updatedOrder }
    });
  } catch (error) {
    return next(error);
  }
};

const getAllOrders = async (req, res, next) => {
  try {
    const orders = await Order.find({})
      .populate(ORDER_ITEM_TOY_POPULATE)
      .sort({ createdAt: -1 });

    return res.status(200).json({ success: true, message: 'All orders fetched', data: { orders } });
  } catch (error) {
    return next(error);
  }
};

module.exports = { createOrder, getMyOrders, getOrderById, updateOrderStatus, getAllOrders };
