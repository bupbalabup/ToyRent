const mongoose = require('mongoose');
const Order = require('../models/order.model.js');
const Payment = require('../models/payment.model.js');
const { createOrderConfirmedNotification } = require('./notification.service.js');

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

const PAYPAL_BASE_URL = process.env.PAYPAL_BASE_URL || 'https://api-m.sandbox.paypal.com';

const getPayPalCredentials = () => {
  const clientId = process.env.PAYPAL_CLIENT_ID;
  const clientSecret = process.env.PAYPAL_CLIENT_SECRET;

  if (!clientId || !clientSecret) {
    throw new AppError('PayPal credentials are missing', 500);
  }

  return { clientId, clientSecret };
};

const getPayPalReturnUrls = (returnUrl) => {
  const successUrl = returnUrl || process.env.PAYPAL_SUCCESS_URL;
  const cancelUrl = process.env.PAYPAL_CANCEL_URL || successUrl;

  if (!successUrl || !cancelUrl) {
    throw new AppError('PayPal return URLs are missing', 500);
  }

  return { successUrl, cancelUrl };
};

const paypalFetch = async ({ path, method = 'GET', accessToken, body }) => {
  const response = await fetch(`${PAYPAL_BASE_URL}${path}`, {
    method,
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${accessToken}`
    },
    body: body ? JSON.stringify(body) : undefined
  });

  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new AppError(payload?.message || 'PayPal API request failed', 502);
  }

  return payload;
};

const getPayPalAccessToken = async () => {
  const { clientId, clientSecret } = getPayPalCredentials();
  const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  const response = await fetch(`${PAYPAL_BASE_URL}/v1/oauth2/token`, {
    method: 'POST',
    headers: {
      Authorization: `Basic ${basicAuth}`,
      'Content-Type': 'application/x-www-form-urlencoded'
    },
    body: 'grant_type=client_credentials'
  });

  const payload = await response.json().catch(() => ({}));

  if (!response.ok || !payload?.access_token) {
    throw new AppError(payload?.error_description || 'Unable to get PayPal access token', 502);
  }

  return payload.access_token;
};

const ensureOrderAccessible = async ({ orderId, userId, role, session = null }) => {
  const query = Order.findById(orderId);
  const order = session ? await query.session(session) : await query;

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  if (role !== 'admin' && order.userId.toString() !== userId.toString()) {
    throw new AppError('Forbidden', 403);
  }

  return order;
};

const createPayPalCheckout = async ({ order, returnUrl }) => {
  if (order.paymentStatus !== 'pending') {
    throw new AppError('Order is not payable', 409);
  }

  const accessToken = await getPayPalAccessToken();
  const { successUrl, cancelUrl } = getPayPalReturnUrls(returnUrl);

  const paypalOrder = await paypalFetch({
    path: '/v2/checkout/orders',
    method: 'POST',
    accessToken,
    body: {
      intent: 'CAPTURE',
      purchase_units: [
        {
          reference_id: order._id.toString(),
          amount: {
            currency_code: 'USD',
            value: Number(order.totalAmount || order.totalPrice || 0).toFixed(2)
          }
        }
      ],
      application_context: {
        return_url: successUrl,
        cancel_url: cancelUrl,
        user_action: 'PAY_NOW'
      }
    }
  });

  const approvalLink = Array.isArray(paypalOrder?.links)
    ? paypalOrder.links.find((link) => link?.rel === 'approve')
    : null;

  if (!approvalLink?.href) {
    throw new AppError('PayPal approval URL not found', 502);
  }

  await Payment.create({
    orderId: order._id,
    provider: 'paypal',
    transactionId: paypalOrder.id,
    amount: order.totalAmount || order.totalPrice,
    status: 'pending'
  });

  order.paymentMethod = 'paypal';
  order.updatedAt = new Date();
  await order.save();

  return {
    orderId: order._id.toString(),
    paypalOrderId: paypalOrder.id,
    paymentUrl: approvalLink.href,
    amount: order.totalAmount || order.totalPrice,
    orderStatus: order.orderStatus,
    paymentStatus: order.paymentStatus
  };
};

const processPaymentCheckout = async ({ orderId, paymentMethod, returnUrl, userId, role }) => {
  const provider = String(paymentMethod || '').toLowerCase();

  if (!['cash', 'paypal'].includes(provider)) {
    throw new AppError('Invalid payment method', 400);
  }

  if (provider === 'paypal') {
    const order = await ensureOrderAccessible({ orderId, userId, role });
    return createPayPalCheckout({ order, returnUrl });
  }

  const session = await mongoose.startSession();
  let result = null;

  try {
    await session.withTransaction(async () => {
      const order = await ensureOrderAccessible({ orderId, userId, role, session });

      if (order.paymentStatus === 'paid') {
        throw new AppError('Order has already been paid', 409);
      }

      if (order.paymentStatus !== 'pending') {
        throw new AppError('Order is not payable', 409);
      }

      const [payment] = await Payment.create(
        [
          {
            orderId: order._id,
            provider: 'cash',
            transactionId: `CASH_${Date.now()}`,
            amount: order.totalAmount || order.totalPrice,
            status: 'success'
          }
        ],
        { session }
      );

      order.paymentMethod = 'cash';
      order.paymentStatus = 'paid';
      order.orderStatus = 'confirmed';
      order.updatedAt = new Date();

      await order.save({ session });
      await createOrderConfirmedNotification(order, session);

      result = {
        orderId: order._id.toString(),
        payment,
        paymentUrl: null,
        amount: order.totalAmount || order.totalPrice,
        orderStatus: order.orderStatus,
        paymentStatus: order.paymentStatus
      };
    });
  } finally {
    session.endSession();
  }

  return result;
};

const syncPaypalPaymentStatus = async ({ orderId, paypalOrderId, userId, role }) => {
  const order = await ensureOrderAccessible({ orderId, userId, role });
  const accessToken = await getPayPalAccessToken();
  const paypalOrder = await paypalFetch({
    path: `/v2/checkout/orders/${paypalOrderId}`,
    accessToken
  });

  const payment = await Payment.findOne({ orderId: order._id, provider: 'paypal', transactionId: paypalOrderId });

  if (paypalOrder.status === 'COMPLETED') {
    order.paymentStatus = 'paid';
    order.orderStatus = 'confirmed';
    order.paymentMethod = 'paypal';
    order.updatedAt = new Date();
    await order.save();

    if (payment) {
      payment.status = 'success';
      payment.updatedAt = new Date();
      await payment.save();
    }

    await createOrderConfirmedNotification(order);
  } else if (payment && paypalOrder.status === 'PAYER_ACTION_REQUIRED') {
    payment.status = 'pending';
    payment.updatedAt = new Date();
    await payment.save();
  }

  return {
    order,
    paypalOrder,
    synced: true
  };
};

const capturePaypalPaymentStatus = async ({ orderId, paypalOrderId, userId, role }) => {
  const order = await ensureOrderAccessible({ orderId, userId, role });
  const accessToken = await getPayPalAccessToken();

  const captureResult = await paypalFetch({
    path: `/v2/checkout/orders/${paypalOrderId}/capture`,
    method: 'POST',
    accessToken,
    body: {}
  });

  const payment = await Payment.findOne({ orderId: order._id, provider: 'paypal', transactionId: paypalOrderId });

  if (captureResult.status === 'COMPLETED') {
    order.paymentStatus = 'paid';
    order.orderStatus = 'confirmed';
    order.paymentMethod = 'paypal';
    order.updatedAt = new Date();
    await order.save();

    if (payment) {
      payment.status = 'success';
      payment.updatedAt = new Date();
      await payment.save();
    } else {
      await Payment.create({
        orderId: order._id,
        provider: 'paypal',
        transactionId: paypalOrderId,
        amount: order.totalAmount || order.totalPrice,
        status: 'success'
      });
    }

    await createOrderConfirmedNotification(order);
  }

  return {
    order,
    captureResult,
    captured: captureResult.status === 'COMPLETED'
  };
};

const expirePaymentSession = async ({ orderId, userId, role }) => {
  const order = await Order.findById(orderId);

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  if (role !== 'admin' && order.userId.toString() !== userId.toString()) {
    throw new AppError('Forbidden', 403);
  }

  if (order.paymentStatus !== 'pending') {
    return { order, expired: false };
  }

  order.paymentStatus = 'failed';
  order.orderStatus = 'cancelled';
  order.updatedAt = new Date();
  await order.save();

  return {
    order,
    expired: true
  };
};

module.exports = { processPaymentCheckout, capturePaypalPaymentStatus, syncPaypalPaymentStatus, expirePaymentSession };
