const Notification = require('../models/notification.model.js');
const { emitNotification } = require('../socket.js');

const createNotification = async (userId, title, message, type = 'system', relatedId = null, session = null) => {
  const payload = {
    userId,
    title,
    message,
    type,
    relatedId
  };

  let notification;
  if (session) {
    const result = await Notification.create([payload], { session });
    notification = result[0];
  } else {
    notification = await Notification.create(payload);
  }

  // Emit real-time notification via Socket.IO
  emitNotification(userId.toString(), notification);

  return notification;
};

const createOrderConfirmedNotification = async (order, session = null) => {
  return createNotification(
    order.userId,
    'Order Confirmed',
    `Your order ${order._id.toString().substring(0, 8)} has been confirmed.`,
    'order',
    order._id,
    session
  );
};

const createPaymentSuccessNotification = async (userId, orderId, session = null) => {
  return createNotification(
    userId,
    'Payment Successful',
    'Your payment has been processed successfully.',
    'payment',
    orderId,
    session
  );
};

const createOrderStatusNotification = async (userId, orderId, oldStatus, newStatus, session = null) => {
  const statusMessages = {
    PENDING: 'Your order is pending',
    ACTIVE: 'Your order is now active',
    SUCCESS: 'Your order has been completed successfully',
    CANCELLED: 'Your order has been cancelled',
    FAILED: 'Your order has failed',
    pending: 'Your order is pending',
    confirmed: 'Your order has been confirmed',
    completed: 'Your order has been completed',
    cancelled: 'Your order has been cancelled'
  };

  return createNotification(
    userId,
    `Order Status Changed to ${newStatus}`,
    statusMessages[newStatus] || `Your order status changed from ${oldStatus} to ${newStatus}`,
    'order',
    orderId,
    session
  );
};

const createSystemNotification = async (userId, title, message, session = null) => {
  return createNotification(userId, title, message, 'system', null, session);
};

module.exports = {
  createNotification,
  createOrderConfirmedNotification,
  createPaymentSuccessNotification,
  createOrderStatusNotification,
  createSystemNotification
};
