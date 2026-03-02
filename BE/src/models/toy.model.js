import mongoose from 'mongoose';

const { Schema } = mongoose;

const toySchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    description: { type: String, trim: true, default: '' },
    categoryId: { type: Schema.Types.ObjectId, ref: 'Category', index: true },
    images: { type: [String], default: [] },
    rentalPricePerDay: { type: Number, required: true, min: 0 },
    stock: { type: Number, required: true, min: 0 },
    isActive: { type: Boolean, default: true },
    ratingAverage: { type: Number, default: 0, min: 0, max: 5 },
    ratingCount: { type: Number, default: 0, min: 0 }
  },
  { timestamps: true }
);

toySchema.index({ name: 'text', description: 'text' });

const Toy = mongoose.model('Toy', toySchema);

export default Toy;
