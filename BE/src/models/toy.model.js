const mongoose = require('mongoose');

const { Schema } = mongoose;

const isValidUrl = (value) => {
  if (!value) return true;
  try {
    const parsed = new URL(value);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch (_) {
    return false;
  }
};

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
    imageUrl: {
      type: String,
      trim: true,
      validate: {
        validator: isValidUrl,
        message: 'imageUrl must be a valid http/https URL'
      }
    },
    images: { 
      type: [String],
      default: [],
      validate: {
        validator: (arr) => Array.isArray(arr) && arr.every((url) => isValidUrl(url)),
        message: 'All images must be valid http/https URLs'
      }
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
