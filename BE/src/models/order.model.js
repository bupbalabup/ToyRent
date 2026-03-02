import mongoose from 'mongoose';

const { Schema } = mongoose;

const shippingAddressSchema = new Schema(
  {
    fullName: { type: String, trim: true },
    phone: { type: String, trim: true },
    province: { type: String, trim: true },
    district: { type: String, trim: true },
    ward: { type: String, trim: true },
    street: { type: String, trim: true }
  },
  { _id: false }
);

const orderItemSchema = new Schema(
  {
    toyId: { type: Schema.Types.ObjectId, ref: 'Toy', required: true },
    name: { type: String, required: true, trim: true },
    image: { type: String, trim: true },
    rentalPricePerDay: { type: Number, required: true, min: 0 },
    rentalDays: { type: Number, required: true, min: 1 },
    quantity: { type: Number, required: true, min: 1 },
    subtotal: { type: Number, required: true, min: 0 }
  },
  { _id: false }
);

const orderSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    items: {
      type: [orderItemSchema],
      required: true,
      validate: {
        validator: (value) => Array.isArray(value) && value.length > 0,
        message: 'Order must contain at least one item'
      }
    },
    rentalStartDate: { type: Date, required: true },
    rentalEndDate: {
      type: Date,
      required: true,
      validate: {
        validator: function validateRentalEndDate(value) {
          return !this.rentalStartDate || value >= this.rentalStartDate;
        },
        message: 'rentalEndDate must be greater than or equal to rentalStartDate'
      }
    },
    fulfillmentType: {
      type: String,
      enum: ['pickup', 'delivery'],
      default: 'pickup',
      required: true,
      index: true
    },
    shippingAddress: { type: shippingAddressSchema, default: undefined },
    totalPrice: { type: Number, required: true, min: 0 },
    discountAmount: { type: Number, default: 0, min: 0 },
    voucherId: { type: Schema.Types.ObjectId, ref: 'Voucher' },
    orderStatus: {
      type: String,
      enum: ['pending', 'confirmed', 'delivering', 'completed', 'cancelled'],
      default: 'pending',
      required: true,
      index: true
    },
    paymentStatus: {
      type: String,
      enum: ['pending', 'paid', 'failed'],
      default: 'pending',
      required: true,
      index: true
    },
    paymentMethod: {
      type: String,
      enum: ['cash', 'momo', 'sepay'],
      default: 'cash',
      required: true
    }
  },
  { timestamps: true }
);

orderSchema.index({ userId: 1, createdAt: -1 });

const Order = mongoose.model('Order', orderSchema);

export default Order;
