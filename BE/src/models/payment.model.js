import mongoose from 'mongoose';

const { Schema } = mongoose;

const paymentSchema = new Schema(
  {
    orderId: { type: Schema.Types.ObjectId, ref: 'Order', required: true, index: true },
    provider: { type: String, enum: ['cash', 'momo', 'sepay'], default: 'cash', required: true },
    transactionId: { type: String, trim: true },
    amount: { type: Number, required: true, min: 0 },
    status: {
      type: String,
      enum: ['pending', 'success', 'failed'],
      default: 'pending',
      required: true,
      index: true
    },
    rawResponse: { type: Schema.Types.Mixed, default: null }
  },
  { timestamps: true }
);

paymentSchema.index({ orderId: 1, provider: 1 });
paymentSchema.index(
  { transactionId: 1 },
  { unique: true, sparse: true, partialFilterExpression: { transactionId: { $type: 'string' } } }
);

const Payment = mongoose.model('Payment', paymentSchema);

export default Payment;
