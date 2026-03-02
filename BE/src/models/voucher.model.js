import mongoose from 'mongoose';

const { Schema } = mongoose;

const voucherSchema = new Schema(
  {
    code: { type: String, required: true, unique: true, trim: true, uppercase: true },
    discountPercent: { type: Number, required: true, min: 0, max: 100 },
    maxDiscount: { type: Number, required: true, min: 0 },
    minOrderValue: { type: Number, required: true, min: 0 },
    expiredAt: { type: Date, required: true, index: true },
    usageLimit: { type: Number, required: true, min: 0 },
    usedCount: { type: Number, default: 0, min: 0 },
    isActive: { type: Boolean, default: true, index: true }
  },
  { timestamps: true }
);

const Voucher = mongoose.model('Voucher', voucherSchema);

export default Voucher;
