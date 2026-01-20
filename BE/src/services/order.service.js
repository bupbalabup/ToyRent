const mongoose = require('mongoose');
const Order = require('../models/order.model.js');
const Toy = require('../models/toy.model.js');
const RentalSchedule = require('../models/rentalSchedule.model.js');
const { createOrderConfirmedNotification } = require('./notification.service.js');

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

const normalizeDateToUTC = (dateInput) => {
  const date = new Date(dateInput);
  return new Date(Date.UTC(date.getUTCFullYear(), date.getUTCMonth(), date.getUTCDate()));
};

const enumerateDatesUTC = (startDate, endDate) => {
  const dates = [];
  const cursor = normalizeDateToUTC(startDate);
  const normalizedEnd = normalizeDateToUTC(endDate);

  while (cursor <= normalizedEnd) {
    dates.push(new Date(cursor));
    cursor.setUTCDate(cursor.getUTCDate() + 1);
  }

  return dates;
};

const VALID_PAYMENT_METHODS = ['cash', 'paypal'];
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

const createOrderWithTransaction = async ({
  userId,
  items,
  rentalStartDate,
  rentalEndDate,
  rentalDurationHours,
  paymentMethod = 'cash'
}) => {
  if (!Array.isArray(items) || items.length === 0) {
    throw new AppError('Items are required', 400);
  }

  if (!VALID_PAYMENT_METHODS.includes(paymentMethod)) {
    throw new AppError('Invalid paymentMethod', 400);
  }

  const startDate = normalizeDateToUTC(rentalStartDate);
  const endDate = normalizeDateToUTC(rentalEndDate);

  if (Number.isNaN(startDate.getTime()) || Number.isNaN(endDate.getTime())) {
    throw new AppError('Invalid rental date range', 400);
  }

  if (endDate < startDate) {
    throw new AppError('rentalEndDate must be greater than or equal to rentalStartDate', 400);
  }

  const normalizedRentalDurationHours = Number(rentalDurationHours);
  if (!Number.isFinite(normalizedRentalDurationHours) || normalizedRentalDurationHours < 1) {
    throw new AppError('rentalDurationHours must be greater than 0', 400);
  }
  const dates = enumerateDatesUTC(startDate, endDate);

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
      let depositAmountTotal = 0;

      for (const requestItem of items) {
        const toy = toyMap.get(requestItem.toyId.toString());
        const quantity = Number(requestItem.quantity);

        if (!Number.isInteger(quantity) || quantity < 1) {
          throw new AppError('Invalid item quantity', 400);
        }

        const effectiveRentalPrice = Number(toy.rentalPrice);
        const maxDuration = Number(toy.maxRentalDuration || 24);
        if (normalizedRentalDurationHours > maxDuration) {
          throw new AppError(`Rental duration exceeds maxRentalDuration for ${toy.name}`, 400);
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

        const itemDeposit = Number(toy.depositAmount || 0) * quantity;
        const itemTotal = effectiveRentalPrice * normalizedRentalDurationHours * quantity;

        totalPrice += itemTotal;
        depositAmountTotal += itemDeposit;

        orderItems.push({
          toyId: toy._id,
          rentalPrice: effectiveRentalPrice,
          rentalDurationHours: normalizedRentalDurationHours,
          quantity
        });
      }
      const finalTotal = totalPrice + depositAmountTotal;

      const [order] = await Order.create(
        [
          {
            userId,
            items: orderItems,
            totalAmount: finalTotal,
            depositAmount: depositAmountTotal,
            totalPrice,
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

const updateOrderStatusWithNotification = async ({ orderId, status }) => {
  const order = await Order.findById(orderId);

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  order.orderStatus = status;
  order.updatedAt = new Date();

  await order.save();

  if (status === 'confirmed') {
    await createOrderConfirmedNotification(order);
  }

  return order;
};

module.exports = { createOrderWithTransaction, updateOrderStatusWithNotification };
