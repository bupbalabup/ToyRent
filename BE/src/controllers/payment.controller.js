const { processPaymentCheckout, syncPaypalPaymentStatus, capturePaypalPaymentStatus, expirePaymentSession } = require('../services/payment.service.js');
const mongoose = require('mongoose');

const checkoutPayment = async (req, res, next) => {
  try {
    const { orderId, paymentMethod, returnUrl } = req.body;
    const normalizedPaymentMethod = String(paymentMethod || 'cash').toLowerCase();

    if (!orderId) {
      return res.status(400).json({ success: false, message: 'orderId is required', data: {} });
    }

    if (!mongoose.Types.ObjectId.isValid(orderId)) {
      return res.status(400).json({ success: false, message: 'Invalid orderId', data: {} });
    }

    const payment = await processPaymentCheckout({
      orderId,
      paymentMethod: normalizedPaymentMethod,
      returnUrl: returnUrl || null,
      userId: req.user._id,
      role: req.user.role
    });

    return res.status(201).json({ success: true, message: 'Payment processed', data: payment });
  } catch (error) {
    return next(error);
  }
};

const syncPaypalPayment = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const { paypalOrderId } = req.query;

    if (!paypalOrderId) {
      return res.status(400).json({ success: false, message: 'paypalOrderId is required', data: {} });
    }

    const result = await syncPaypalPaymentStatus({
      orderId,
      paypalOrderId: String(paypalOrderId),
      userId: req.user._id,
      role: req.user.role
    });

    return res.status(200).json({ success: true, message: 'PayPal payment synced', data: result });
  } catch (error) {
    return next(error);
  }
};

const capturePaypalPayment = async (req, res, next) => {
  try {
    const { orderId } = req.params;
    const paypalOrderId = req.body?.paypalOrderId || req.query?.paypalOrderId;

    if (!paypalOrderId) {
      return res.status(400).json({ success: false, message: 'paypalOrderId is required', data: {} });
    }

    const result = await capturePaypalPaymentStatus({
      orderId,
      paypalOrderId: String(paypalOrderId),
      userId: req.user._id,
      role: req.user.role
    });

    return res.status(200).json({ success: true, message: 'PayPal payment captured', data: result });
  } catch (error) {
    return next(error);
  }
};

const expireOrderPayment = async (req, res, next) => {
  try {
    const { orderId } = req.params;

    const result = await expirePaymentSession({
      orderId,
      userId: req.user._id,
      role: req.user.role
    });

    return res.status(200).json({
      success: true,
      message: 'Payment session expiration handled',
      data: result
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = { checkoutPayment, syncPaypalPayment, capturePaypalPayment, expireOrderPayment };
