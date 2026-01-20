const mongoose = require('mongoose');

const { Schema } = mongoose;

const paymentSchema = new Schema(
  {
    orderId: { 
      type: Schema.Types.ObjectId, 
      ref: 'Order', 
      required: true 
    },
    provider: { 
      type: String, 
      enum: ['cash', 'paypal'], 
      default: 'cash', 
      required: true 
    },
    transactionId: { 
      type: String, 
      trim: true 
    },
    amount: { 
      type: Number, 
      required: true, 
      min: 0 
    },
    status: {
      type: String,
      enum: ['pending', 'success', 'failed'],
      default: 'pending',
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

const Payment = mongoose.model('Payment', paymentSchema);

module.exports = Payment;
