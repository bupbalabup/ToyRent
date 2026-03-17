const mongoose = require('mongoose');

const { Schema } = mongoose;

const ORDER_STATUSES = ['PENDING', 'ACTIVE', 'SUCCESS', 'CANCELLED', 'FAILED'];
const RENTAL_TYPES = ['HOURLY', 'MANUAL'];

const orderSchema = new Schema(
  {
    userId: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true
    },
    items: {
      type: [
        {
          toyId: {
            type: Schema.Types.ObjectId,
            ref: 'Toy',
            required: true
          },
          rentalPrice: {
            type: Number,
            required: true,
            min: 0
          },
          rentalDurationHours: {
            type: Number,
            required: true,
            min: 0,
            default: 0
          },
          quantity: {
            type: Number,
            required: true,
            min: 1
          }
        },
      ],
      required: true,
      validate: {
        validator: (value) => Array.isArray(value) && value.length > 0,
        message: 'Order must contain at least one item'
      }
    },
    totalAmount: { type: Number, min: 0 },
    depositAmount: { type: Number, default: 0, min: 0 },
    totalPrice: { type: Number, required: true, min: 0 },
    orderStatus: {
      type: String,
      enum: ORDER_STATUSES,
      default: 'PENDING',
      required: true
    },
    rentalType: {
      type: String,
      enum: RENTAL_TYPES,
      default: 'HOURLY',
      required: true
    },
    rentalStartTime: {
      type: Date,
      default: Date.now,
      required: true
    },
    rentalEndTime: {
      type: Date,
      default: null
    },
    actualEndTime: {
      type: Date,
      default: null
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed'],
      default: 'pending',
      required: true
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'paypal'],
      default: 'cash',
      required: true
    },
    reservationReleased: {
      type: Boolean,
      default: false
    },
    createdAt: {
      type: Date,
      default: Date.now
    },
    updatedAt: {
      type: Date,
      default: Date.now
    }
  },
  {
    toObject: { virtuals: true },
    toJSON: { virtuals: true }
  }
);

orderSchema.virtual('isEditable').get(function isEditableGetter() {
  return !['CANCELLED', 'SUCCESS'].includes(this.orderStatus);
});

// Legacy aliases to avoid breaking old clients expecting rentalStartDate/rentalEndDate keys.
orderSchema.virtual('rentalStartDate').get(function rentalStartDateGetter() {
  return this.rentalStartTime;
});

orderSchema.virtual('rentalEndDate').get(function rentalEndDateGetter() {
  return this.rentalEndTime;
});

orderSchema.pre('validate', function normalizeOrderStatusPreValidate(next) {
  const status = this.orderStatus;
  const map = {
    pending: 'PENDING',
    confirmed: 'ACTIVE',
    delivering: 'ACTIVE',
    completed: 'SUCCESS',
    cancelled: 'CANCELLED',
    failed: 'FAILED',
    active: 'ACTIVE',
    success: 'SUCCESS'
  };

  if (typeof status === 'string') {
    const mapped = map[status.toLowerCase()];
    if (mapped) {
      this.orderStatus = mapped;
    } else {
      this.orderStatus = status.toUpperCase();
    }
  }
  next();
});

orderSchema.statics.ORDER_STATUSES = ORDER_STATUSES;
orderSchema.statics.RENTAL_TYPES = RENTAL_TYPES;

const Order = mongoose.model('Order', orderSchema);

module.exports = Order;
