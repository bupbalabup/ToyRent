const mongoose = require('mongoose');

const { Schema } = mongoose;

const toySchema = new Schema(
  {
    name: { 
      type: String, 
      required: true, 
      trim: true 
    },
    description: { 
      type: String, 
      trim: true, 
      default: '' 
    },
    categoryId: { 
      type: Schema.Types.ObjectId, 
      ref: 'Category' 
    },
    images: { 
      type: [String], 
      default: [] 
    },
    rentalPrice: { 
      type: Number, 
      required: true, 
      min: 0 },
    depositAmount: { 
      type: Number, 
      required: true, 
      min: 0, 
      default: 0 
    },
    maxRentalDuration: { 
      type: Number, 
      min: 1, 
      default: 24 },
    stock: { 
      type: Number, 
      required: true, 
      min: 0 },
    isActive: {
      type: Boolean,
      default: true },
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

const Toy = mongoose.model('Toy', toySchema);

module.exports = Toy;
