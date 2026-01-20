const mongoose = require('mongoose');

const { Schema } = mongoose;

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
            min: 1
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
      enum: ['pending', 'confirmed', 'delivering', 'completed', 'cancelled'],
      default: 'pending',
      required: true
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
    createdAt: {
      type: Date,
      default: Date.now
    },
    updatedAt: {
      type: Date,
      default: Date.now
    }
  }
);

const Order = mongoose.model('Order', orderSchema);

module.exports = Order;
