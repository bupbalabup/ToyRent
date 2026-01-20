const Notification = require('../models/notification.model.js');

const createOrderConfirmedNotification = async (order, session = null) => {
  const payload = {
    userId: order.userId,
    title: 'Order Confirmed',
    message: `Your order ${order._id.toString()} has been confirmed.`
  };

  if (session) {
    await Notification.create([payload], { session });
    return;
  }

  await Notification.create(payload);
};

module.exports = { createOrderConfirmedNotification };
