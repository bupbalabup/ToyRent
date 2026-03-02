import mongoose from 'mongoose';

const { Schema } = mongoose;

const reviewSchema = new Schema(
  {
    userId: { type: Schema.Types.ObjectId, ref: 'User', required: true, index: true },
    toyId: { type: Schema.Types.ObjectId, ref: 'Toy', required: true, index: true },
    rating: { type: Number, required: true, min: 1, max: 5 },
    comment: { type: String, trim: true }
  },
  { timestamps: true }
);

reviewSchema.index({ userId: 1, toyId: 1 }, { unique: true });

const Review = mongoose.model('Review', reviewSchema);

export default Review;
