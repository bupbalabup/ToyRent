import mongoose from 'mongoose';
import Order from '../models/order.model.js';
import Toy from '../models/toy.model.js';
import Voucher from '../models/voucher.model.js';
import RentalSchedule from '../models/rentalSchedule.model.js';
import AppError from '../utils/appError.js';
import { normalizeDateToUTC, enumerateDatesUTC } from '../utils/date.js';
import { createOrderConfirmedNotification } from './notification.service.js';

const VALID_PAYMENT_METHODS = ['cash', 'momo', 'sepay'];
const VALID_FULFILLMENT_TYPES = ['pickup', 'delivery'];

const reserveQuantityForDate = async ({ session, toyId, date, quantity, stock }) => {
  const maxAllowedBooked = stock - quantity;

  if (maxAllowedBooked < 0) {
    throw new AppError('Requested quantity exceeds stock', 409);
  }

  const updated = await RentalSchedule.updateOne(
    {
      toyId,
      date,
      bookedQuantity: { $lte: maxAllowedBooked }
    },
    { $inc: { bookedQuantity: quantity } },
    { session }
  );

  if (updated.modifiedCount === 1) {
    return;
  }

  try {
    await RentalSchedule.create([{ toyId, date, bookedQuantity: quantity }], { session });
    return;
  } catch (error) {
    if (error?.code !== 11000) {
      throw error;
    }
  }

  const retried = await RentalSchedule.updateOne(
    {
      toyId,
      date,
      bookedQuantity: { $lte: maxAllowedBooked }
    },
    { $inc: { bookedQuantity: quantity } },
    { session }
  );

  if (retried.modifiedCount !== 1) {
    throw new AppError('Insufficient stock for selected rental dates', 409);
  }
};

export const createOrderWithTransaction = async ({
  userId,
  items,
  rentalStartDate,
  rentalEndDate,
  voucherCode,
  fulfillmentType = 'pickup',
  shippingAddress,
  paymentMethod = 'cash'
}) => {
  if (!Array.isArray(items) || items.length === 0) {
    throw new AppError('Items are required', 400);
  }

  if (!VALID_PAYMENT_METHODS.includes(paymentMethod)) {
    throw new AppError('Invalid paymentMethod', 400);
  }

  if (!VALID_FULFILLMENT_TYPES.includes(fulfillmentType)) {
    throw new AppError('Invalid fulfillmentType', 400);
  }

  if (fulfillmentType === 'delivery') {
    const requiredAddressFields = ['fullName', 'phone', 'province', 'district', 'ward', 'street'];
    const missingAddressField = requiredAddressFields.find(
      (field) => !shippingAddress || !String(shippingAddress[field] || '').trim()
    );

    if (missingAddressField) {
      throw new AppError(`shippingAddress.${missingAddressField} is required for delivery`, 400);
    }
  }

  const startDate = normalizeDateToUTC(rentalStartDate);
  const endDate = normalizeDateToUTC(rentalEndDate);

  if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
    throw new AppError('Invalid rental date range', 400);
  }

  if (endDate < startDate) {
    throw new AppError('rentalEndDate must be greater than or equal to rentalStartDate', 400);
  }

  const dates = enumerateDatesUTC(startDate, endDate);
  const rentalDays = dates.length;
  const session = await mongoose.startSession();
  let createdOrder = null;

  try {
    await session.withTransaction(async () => {
      const itemToyIds = items.map((item) => item.toyId);

      if (itemToyIds.some((toyId) => !mongoose.Types.ObjectId.isValid(toyId))) {
        throw new AppError('Invalid toyId in items', 400);
      }

      const toys = await Toy.find({ _id: { $in: itemToyIds }, isActive: true }).session(session);
      const toyMap = new Map(toys.map((toy) => [toy._id.toString(), toy]));

      if (toys.length !== itemToyIds.length) {
        throw new AppError('One or more toys are invalid or inactive', 400);
      }

      const orderItems = [];
      let totalPrice = 0;

      for (const requestItem of items) {
        const toy = toyMap.get(requestItem.toyId.toString());
        const quantity = Number(requestItem.quantity);

        if (!Number.isInteger(quantity) || quantity < 1) {
          throw new AppError('Invalid item quantity', 400);
        }

        for (const date of dates) {
          await reserveQuantityForDate({
            session,
            toyId: toy._id,
            date,
            quantity,
            stock: toy.stock
          });
        }

        const subtotal = toy.rentalPricePerDay * rentalDays * quantity;
        totalPrice += subtotal;

        orderItems.push({
          toyId: toy._id,
          name: toy.name,
          image: toy.images?.[0] || '',
          rentalPricePerDay: toy.rentalPricePerDay,
          rentalDays,
          quantity,
          subtotal
        });
      }

      let discountAmount = 0;
      let voucherId = undefined;

      if (voucherCode) {
        const normalizedCode = String(voucherCode).trim().toUpperCase();

        const voucher = await Voucher.findOne({
          code: normalizedCode,
          isActive: true,
          expiredAt: { $gte: new Date() },
          $expr: { $lt: ['$usedCount', '$usageLimit'] }
        }).session(session);

        if (!voucher) {
          throw new AppError('Invalid or expired voucher', 400);
        }

        if (totalPrice < voucher.minOrderValue) {
          throw new AppError('Order does not meet voucher minimum value', 400);
        }

        discountAmount = Math.min((totalPrice * voucher.discountPercent) / 100, voucher.maxDiscount);
        voucherId = voucher._id;

        await Voucher.updateOne({ _id: voucher._id }, { $inc: { usedCount: 1 } }, { session });
      }

      const finalTotal = Math.max(totalPrice - discountAmount, 0);

      const [order] = await Order.create(
        [
          {
            userId,
            items: orderItems,
            rentalStartDate: startDate,
            rentalEndDate: endDate,
            totalPrice: finalTotal,
            discountAmount,
            voucherId,
            fulfillmentType,
            shippingAddress: fulfillmentType === 'delivery' ? shippingAddress : undefined,
            orderStatus: 'pending',
            paymentStatus: 'pending',
            paymentMethod
          }
        ],
        { session }
      );

      createdOrder = order;
    });
  } finally {
    session.endSession();
  }

  return createdOrder;
};

export const updateOrderStatusWithNotification = async ({ orderId, status }) => {
  const order = await Order.findById(orderId);

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  order.orderStatus = status;

  await order.save();

  if (status === 'confirmed') {
    await createOrderConfirmedNotification(order);
  }

  return order;
};
