const mongoose = require('mongoose');
const Order = require('../models/order.model.js');
const Payment = require('../models/payment.model.js');
const { createOrderStatusNotification } = require('./notification.service.js');
const { releaseOrderReservations } = require('./order.service.js');
const { emitPaymentSuccess, emitPaymentFailed } = require('../socket.js');

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

const isTransactionUnsupportedError = (error) => {
  const message = String(error?.message || '');
  return message.includes('Transaction numbers are only allowed on a replica set member or mongos');
};

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
  let response;
  try {
    response = await fetch(`${PAYPAL_BASE_URL}${path}`, {
      method,
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${accessToken}`
      },
      body: body ? JSON.stringify(body) : undefined
    });
  } catch (error) {
    throw new AppError('Unable to reach PayPal API', 502);
  }

  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new AppError(payload?.message || 'PayPal API request failed', 502);
  }

  return payload;
};

const getPayPalAccessToken = async () => {
  const { clientId, clientSecret } = getPayPalCredentials();
  const basicAuth = Buffer.from(`${clientId}:${clientSecret}`).toString('base64');

  let response;
  try {
    response = await fetch(`${PAYPAL_BASE_URL}/v1/oauth2/token`, {
      method: 'POST',
      headers: {
        Authorization: `Basic ${basicAuth}`,
        'Content-Type': 'application/x-www-form-urlencoded'
      },
      body: 'grant_type=client_credentials'
    });
  } catch (error) {
    throw new AppError('Unable to connect to PayPal for access token', 502);
  }

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

  const executeCashCheckout = async (txnSession = null) => {
    const order = await ensureOrderAccessible({ orderId, userId, role, session: txnSession });

    if (order.paymentStatus === 'paid') {
      throw new AppError('Order has already been paid', 409);
    }

    if (order.paymentStatus !== 'pending') {
      throw new AppError('Order is not payable', 409);
    }

    let payment;
    if (txnSession) {
      const [createdPayment] = await Payment.create(
        [
          {
            orderId: order._id,
            provider: 'cash',
            transactionId: `CASH_${Date.now()}`,
            amount: order.totalAmount || order.totalPrice,
            status: 'success'
          }
        ],
        { session: txnSession }
      );
      payment = createdPayment;
    } else {
      payment = await Payment.create({
        orderId: order._id,
        provider: 'cash',
        transactionId: `CASH_${Date.now()}`,
        amount: order.totalAmount || order.totalPrice,
        status: 'success'
      });
    }

    order.paymentMethod = 'cash';
    order.paymentStatus = 'paid';
    const oldStatus = order.orderStatus;
    order.orderStatus = 'ACTIVE';
    order.updatedAt = new Date();

    if (txnSession) {
      await order.save({ session: txnSession });
    } else {
      await order.save();
    }

    await createOrderStatusNotification(order.userId, order._id, oldStatus, 'ACTIVE', txnSession || undefined);

    return {
      orderId: order._id.toString(),
      payment,
      paymentUrl: null,
      amount: order.totalAmount || order.totalPrice,
      orderStatus: order.orderStatus,
      paymentStatus: order.paymentStatus
    };
  };

  try {
    try {
      await session.withTransaction(async () => {
        result = await executeCashCheckout(session);
      });
    } catch (error) {
      if (!isTransactionUnsupportedError(error)) {
        throw error;
      }

      result = await executeCashCheckout();
    }
  } finally {
    session.endSession();
  }

  // Emit socket events for cash payment success
  if (result) {
    const populatedOrder = await Order.findById(result.orderId).populate({ path: 'items.toyId', select: 'name images' });
    emitPaymentSuccess(populatedOrder.userId.toString(), populatedOrder);
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
    const oldStatus = order.orderStatus;
    order.paymentStatus = 'paid';
    order.orderStatus = 'ACTIVE';
    order.paymentMethod = 'paypal';
    order.updatedAt = new Date();
    await order.save();

    if (payment) {
      payment.status = 'success';
      payment.updatedAt = new Date();
      await payment.save();
    }

    await createOrderStatusNotification(order.userId, order._id, oldStatus, 'ACTIVE');

    // Emit socket event for PayPal payment success
    const populatedOrder = await Order.findById(orderId).populate({ path: 'items.toyId', select: 'name images' });
    emitPaymentSuccess(order.userId.toString(), populatedOrder);
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
    const oldStatus = order.orderStatus;
    order.paymentStatus = 'paid';
    order.orderStatus = 'ACTIVE';
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

    await createOrderStatusNotification(order.userId, order._id, oldStatus, 'ACTIVE');
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
  order.orderStatus = 'CANCELLED';
  await releaseOrderReservations({ order });
  order.updatedAt = new Date();
  await order.save();

  return {
    order,
    expired: true
  };
};

module.exports = { processPaymentCheckout, capturePaypalPaymentStatus, syncPaypalPaymentStatus, expirePaymentSession };
