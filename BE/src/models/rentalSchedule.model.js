const mongoose = require('mongoose');

const { Schema } = mongoose;

const rentalScheduleSchema = new Schema(
  {
    toyId: { 
      type: Schema.Types.ObjectId, 
      ref: 'Toy', 
      required: true },
    date: { 
      type: Date, 
      required: true 
    },
    bookedQuantity: { 
      type: Number, 
      default: 0, 
      min: 0 
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

const RentalSchedule = mongoose.model('RentalSchedule', rentalScheduleSchema);

module.exports = RentalSchedule;