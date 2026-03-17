const mongoose = require('mongoose');
const Order = require('../models/order.model.js');
const Toy = require('../models/toy.model.js');
const RentalSchedule = require('../models/rentalSchedule.model.js');
const { createOrderStatusNotification } = require('./notification.service.js');
const {
  emitOrderCreated,
  emitOrderStatusChanged
} = require('../socket.js');

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
const VALID_RENTAL_TYPES = ['HOURLY', 'MANUAL'];
const EDIT_BLOCKED_STATUSES = ['CANCELLED', 'SUCCESS'];

const LEGACY_STATUS_MAP = {
  pending: 'PENDING',
  confirmed: 'ACTIVE',
  delivering: 'ACTIVE',
  completed: 'SUCCESS',
  cancelled: 'CANCELLED',
  failed: 'FAILED',
  active: 'ACTIVE',
  success: 'SUCCESS'
};

const normalizeOrderStatus = (status) => {
  if (!status) return null;
  const normalized = String(status).trim();
  if (!normalized) return null;

  const upper = normalized.toUpperCase();
  if (Order.ORDER_STATUSES.includes(upper)) {
    return upper;
  }

  const mapped = LEGACY_STATUS_MAP[normalized.toLowerCase()];
  return mapped || null;
};

const buildOrderPopulatedQuery = (id) => Order.findById(id)
  .populate({ path: 'userId', select: 'name email phone avatar role' })
  .populate({ path: 'items.toyId', select: 'name images imageUrl description rentalPrice depositAmount' });

const getOrderItemsSubtotal = ({ orderItems, durationHours }) =>
  orderItems.reduce((sum, item) => sum + (Number(item.rentalPrice || 0) * Number(item.quantity || 0) * durationHours), 0);

const reserveQuantityForDate = async ({ session, toyId, date, quantity, stock }) => {
  const maxAllowedBooked = stock - quantity;

  if (maxAllowedBooked < 0) {
    throw new AppError('Requested quantity exceeds stock', 409);
  }

  const updateOptions = session ? { session } : {};

  const updated = await RentalSchedule.updateOne(
    {
      toyId,
      date,
      bookedQuantity: { $lte: maxAllowedBooked }
    },
    { $inc: { bookedQuantity: quantity } },
    updateOptions
  );

  if (updated.modifiedCount === 1) {
    return;
  }

  try {
    const createOptions = session ? { session } : undefined;
    await RentalSchedule.create([{ toyId, date, bookedQuantity: quantity }], createOptions);
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
    updateOptions
  );

  if (retried.modifiedCount !== 1) {
    throw new AppError('Insufficient stock for selected rental dates', 409);
  }
};

const releaseQuantityForDate = async ({ session, toyId, date, quantity }) => {
  const query = RentalSchedule.findOne({ toyId, date });
  const schedule = session ? await query.session(session) : await query;

  if (!schedule) {
    return;
  }

  const current = Number(schedule.bookedQuantity || 0);
  const next = Math.max(current - quantity, 0);

  schedule.bookedQuantity = next;
  schedule.updatedAt = new Date();

  if (session) {
    await schedule.save({ session });
  } else {
    await schedule.save();
  }
};

const getReservedDatesFromOrder = (order) => {
  const start = normalizeDateToUTC(order.rentalStartTime || order.createdAt || new Date());
  const end = normalizeDateToUTC(order.rentalEndTime || order.rentalStartTime || order.createdAt || start);
  return enumerateDatesUTC(start, end);
};

const releaseOrderReservations = async ({ order, session = null }) => {
  if (!order || order.reservationReleased) {
    return false;
  }

  const dates = getReservedDatesFromOrder(order);
  for (const item of order.items || []) {
    const toyId = item?.toyId?._id || item?.toyId;
    const quantity = Number(item?.quantity || 0);

    if (!toyId || !Number.isInteger(quantity) || quantity <= 0) {
      continue;
    }

    for (const date of dates) {
      await releaseQuantityForDate({
        session,
        toyId,
        date,
        quantity
      });
    }
  }

  order.reservationReleased = true;
  order.updatedAt = new Date();
  return true;
};

const createOrderWithTransaction = async ({
  userId,
  items,
  rentalStartDate,
  rentalEndDate,
  rentalDurationHours,
  rentalType = 'HOURLY',
  durationHours,
  paymentMethod = 'cash'
}) => {
  if (!Array.isArray(items) || items.length === 0) {
    throw new AppError('Items are required', 400);
  }

  if (!VALID_PAYMENT_METHODS.includes(paymentMethod)) {
    throw new AppError('Invalid paymentMethod', 400);
  }

  const normalizedRentalType = String(rentalType || 'HOURLY').toUpperCase();
  if (!VALID_RENTAL_TYPES.includes(normalizedRentalType)) {
    throw new AppError('rentalType must be HOURLY or MANUAL', 400);
  }

  let normalizedRentalDurationHours = Number(durationHours ?? rentalDurationHours ?? 1);
  if (normalizedRentalType === 'HOURLY') {
    if (!Number.isFinite(normalizedRentalDurationHours) || normalizedRentalDurationHours < 1) {
      throw new AppError('durationHours must be greater than 0 for HOURLY rental', 400);
    }
  } else {
    normalizedRentalDurationHours = 0;
  }

  const now = new Date();
  const parsedStart = rentalStartDate ? new Date(rentalStartDate) : now;
  const startTime = Number.isNaN(parsedStart.getTime()) ? now : parsedStart;
  const endTime = normalizedRentalType === 'HOURLY'
    ? new Date(startTime.getTime() + normalizedRentalDurationHours * 60 * 60 * 1000)
    : null;

  const startDate = normalizeDateToUTC(startTime);
  const endDate = normalizeDateToUTC(endTime || startTime);
  const dates = enumerateDatesUTC(startDate, endDate);

  const executeCreateOrder = async (session = null) => {
    const itemToyIds = items.map((item) => item.toyId);

    if (itemToyIds.some((toyId) => !mongoose.Types.ObjectId.isValid(toyId))) {
      throw new AppError('Invalid toyId in items', 400);
    }

    const toyQuery = Toy.find({ _id: { $in: itemToyIds }, isActive: true });
    const toys = session ? await toyQuery.session(session) : await toyQuery;
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
      if (normalizedRentalType === 'HOURLY' && normalizedRentalDurationHours > maxDuration) {
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
      const itemTotal = normalizedRentalType === 'HOURLY'
        ? effectiveRentalPrice * normalizedRentalDurationHours * quantity
        : 0;

      totalPrice += itemTotal;
      depositAmountTotal += itemDeposit;

      orderItems.push({
        toyId: toy._id,
        rentalPrice: effectiveRentalPrice,
        rentalDurationHours: normalizedRentalType === 'HOURLY' ? normalizedRentalDurationHours : 0,
        quantity
      });
    }

    const finalTotal = totalPrice + depositAmountTotal;
    const payload = {
      userId,
      items: orderItems,
      totalAmount: finalTotal,
      depositAmount: depositAmountTotal,
      totalPrice,
      rentalType: normalizedRentalType,
      rentalStartTime: startTime,
      rentalEndTime: endTime,
      actualEndTime: null,
      orderStatus: 'PENDING',
      paymentStatus: 'pending',
      paymentMethod
    };

    if (session) {
      const [order] = await Order.create([payload], { session });
      return order;
    }

    return Order.create(payload);
  };

  const session = await mongoose.startSession();
  let createdOrder = null;

  try {
    try {
      await session.withTransaction(async () => {
        createdOrder = await executeCreateOrder(session);
      });
    } catch (error) {
      if (!isTransactionUnsupportedError(error)) {
        throw error;
      }

      createdOrder = await executeCreateOrder();
    }
  } finally {
    session.endSession();
  }

  // Emit socket event for order creation
  const populatedOrder = await buildOrderPopulatedQuery(createdOrder._id);
  emitOrderCreated(userId, populatedOrder);

  return createdOrder;
};

const updateOrderStatusWithNotification = async ({ orderId, status }) => {
  const order = await Order.findById(orderId);

  if (!order) {
    throw new AppError('Order not found', 404);
  }

  if (EDIT_BLOCKED_STATUSES.includes(order.orderStatus)) {
    throw new AppError('Order cannot be edited in current status', 403);
  }

  const normalizedStatus = normalizeOrderStatus(status);
  if (!normalizedStatus) {
    throw new AppError('Invalid order status', 400);
  }

  const oldStatus = order.orderStatus;
  order.orderStatus = normalizedStatus;
  order.updatedAt = new Date();

  if (normalizedStatus === 'SUCCESS') {
    order.actualEndTime = order.actualEndTime || new Date();
  }

  if (['CANCELLED', 'FAILED'].includes(normalizedStatus)) {
    await releaseOrderReservations({ order });
  }

  await order.save();

  await createOrderStatusNotification(order.userId, order._id, oldStatus, normalizedStatus);

  // Emit socket event for status change
  const populatedOrder = await buildOrderPopulatedQuery(orderId);
  emitOrderStatusChanged(order.userId.toString(), populatedOrder, oldStatus, normalizedStatus);

  return order;
};

const createAdminOrderWithTransaction = async ({
  userId,
  items,
  rentalType,
  durationHours
}) => {
  if (!mongoose.Types.ObjectId.isValid(userId)) {
    throw new AppError('Invalid userId', 400);
  }

  const normalizedRentalType = String(rentalType || '').toUpperCase();
  if (!VALID_RENTAL_TYPES.includes(normalizedRentalType)) {
    throw new AppError('rentalType must be HOURLY or MANUAL', 400);
  }

  const now = new Date();
  const normalizedDuration = normalizedRentalType === 'HOURLY'
    ? Number(durationHours)
    : 0;

  if (normalizedRentalType === 'HOURLY' && (!Number.isFinite(normalizedDuration) || normalizedDuration < 1)) {
    throw new AppError('durationHours must be greater than 0 for HOURLY rental', 400);
  }

  const createdOrder = await createOrderWithTransaction({
    userId,
    items,
    paymentMethod: 'cash',
    rentalType: normalizedRentalType,
    durationHours: normalizedDuration,
    rentalStartDate: now.toISOString()
  });

  createdOrder.orderStatus = 'ACTIVE';
  createdOrder.paymentMethod = 'cash';
  createdOrder.paymentStatus = 'pending';
  createdOrder.updatedAt = new Date();
  await createdOrder.save();

  const populated = await buildOrderPopulatedQuery(createdOrder._id);
  emitOrderStatusChanged(userId.toString(), populated, 'PENDING', 'ACTIVE');
  return populated;
};

const endRentalOrder = async ({ orderId }) => {
  const order = await Order.findById(orderId);
  if (!order) {
    throw new AppError('Order not found', 404);
  }

  if (EDIT_BLOCKED_STATUSES.includes(order.orderStatus)) {
    throw new AppError('Order cannot be edited in current status', 403);
  }

  if (order.orderStatus !== 'ACTIVE') {
    throw new AppError('Only ACTIVE order can be ended', 400);
  }

  const now = new Date();
  const rentalStart = order.rentalStartTime || order.createdAt || now;
  let totalPrice = Number(order.totalPrice || 0);

  if (order.rentalType === 'HOURLY') {
    const rentalEnd = order.rentalEndTime;
    if (rentalEnd && now.getTime() > rentalEnd.getTime()) {
      const extraMs = now.getTime() - rentalEnd.getTime();
      const extraHours = Math.ceil(extraMs / (60 * 60 * 1000));
      const extraAmount = order.items.reduce(
        (sum, item) => sum + Number(item.rentalPrice || 0) * Number(item.quantity || 0) * extraHours,
        0
      );
      totalPrice += extraAmount;
    }
  } else {
    const durationMs = Math.max(now.getTime() - rentalStart.getTime(), 0);
    const durationHours = Math.max(Math.ceil(durationMs / (60 * 60 * 1000)), 1);
    totalPrice = getOrderItemsSubtotal({ orderItems: order.items, durationHours });
    order.items = order.items.map((item) => ({
      ...item.toObject(),
      rentalDurationHours: durationHours
    }));
  }

  const depositAmount = Number(order.depositAmount || 0);
  const expectedTotalAmount = totalPrice + depositAmount;

  order.totalPrice = totalPrice;
  order.totalAmount = expectedTotalAmount;
  order.actualEndTime = now;
  const previousStatus = order.orderStatus;
  order.orderStatus = 'SUCCESS';
  order.paymentMethod = 'cash';
  order.paymentStatus = 'paid';
  order.updatedAt = now;

  await order.save();
  await createOrderStatusNotification(order.userId, order._id, previousStatus, 'SUCCESS');

  const populated = await buildOrderPopulatedQuery(order._id);
  emitOrderStatusChanged(order.userId.toString(), populated, previousStatus, 'SUCCESS');
  return populated;
};

module.exports = {
  createOrderWithTransaction,
  createAdminOrderWithTransaction,
  updateOrderStatusWithNotification,
  endRentalOrder,
  normalizeOrderStatus,
  buildOrderPopulatedQuery,
  releaseOrderReservations,
  EDIT_BLOCKED_STATUSES
};
