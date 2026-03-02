import mongoose from 'mongoose';
import Order from '../models/order.model.js';
import Payment from '../models/payment.model.js';
import AppError from '../utils/appError.js';
import { createOrderConfirmedNotification } from './notification.service.js';
import env from '../config/env.js';

const callPaymentGateway = async ({ provider, order, returnUrl }) => {
  if (provider === 'cash') {
    return {
      isSuccess: true,
      transactionId: `CASH_${Date.now()}`,
      paymentUrl: null,
      rawResponse: { provider: 'cash', mode: 'manual' }
    };
  }

  const gatewayUrl = provider === 'momo' ? env.momoApiUrl : env.sepayApiUrl;
  const apiKey = provider === 'momo' ? env.momoApiKey : env.sepayApiKey;
  const secretKey = provider === 'momo' ? env.momoSecretKey : undefined;

  if (!gatewayUrl || !apiKey) {
    throw new AppError(`${provider.toUpperCase()} gateway is not configured`, 500);
  }

  const response = await fetch(gatewayUrl, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      Authorization: `Bearer ${apiKey}`,
      ...(secretKey ? { 'x-secret-key': secretKey } : {})
    },
    body: JSON.stringify({
      orderId: order._id.toString(),
      amount: order.totalPrice,
      returnUrl,
      description: `Payment for order ${order._id.toString()}`
    })
  });

  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    throw new AppError(`${provider.toUpperCase()} payment failed`, 502);
  }

  return {
    isSuccess: Boolean(payload.success ?? true),
    transactionId: payload.transactionId || `${provider.toUpperCase()}_${Date.now()}`,
    paymentUrl: payload.paymentUrl || null,
    rawResponse: payload
  };
};

export const processPaymentCheckout = async ({
  orderId,
  paymentMethod,
  rawResponse,
  returnUrl
}) => {
  const provider = String(paymentMethod || '').toLowerCase();

  if (!['cash', 'momo', 'sepay'].includes(provider)) {
    throw new AppError('Unsupported payment method', 400);
  }

  const session = await mongoose.startSession();
  let result = null;

  try {
    await session.withTransaction(async () => {
      const order = await Order.findById(orderId).session(session);

      if (!order) {
        throw new AppError('Order not found', 404);
      }

      if (order.paymentStatus === 'paid') {
        throw new AppError('Order has already been paid', 409);
      }

      const gatewayResult = await callPaymentGateway({
        provider,
        order,
        returnUrl
      });

      const status = gatewayResult.isSuccess ? 'success' : 'failed';

      const [payment] = await Payment.create(
        [
          {
            orderId: order._id,
            provider,
            transactionId: gatewayResult.transactionId,
            amount: order.totalPrice,
            status,
            rawResponse: rawResponse || gatewayResult.rawResponse
          }
        ],
        { session }
      );

      order.paymentMethod = provider;
      order.paymentStatus = gatewayResult.isSuccess
        ? provider === 'cash'
          ? 'pending'
          : 'paid'
        : 'failed';

      if (gatewayResult.isSuccess) {
        order.orderStatus = 'confirmed';
      }

      await order.save({ session });

      if (gatewayResult.isSuccess) {
        await createOrderConfirmedNotification(order, session);
      }

      result = {
        payment,
        paymentUrl: gatewayResult.paymentUrl,
        orderStatus: order.orderStatus,
        paymentStatus: order.paymentStatus
      };
    });
  } finally {
    session.endSession();
  }

  return result;
};
