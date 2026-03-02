import mongoose from 'mongoose';

const { Schema } = mongoose;

const rentalScheduleSchema = new Schema(
  {
    toyId: { type: Schema.Types.ObjectId, ref: 'Toy', required: true, index: true },
    date: { type: Date, required: true, index: true },
    bookedQuantity: { type: Number, default: 0, min: 0 }
  },
  { timestamps: true }
);

rentalScheduleSchema.index({ toyId: 1, date: 1 }, { unique: true });

const RentalSchedule = mongoose.model('RentalSchedule', rentalScheduleSchema);

export default RentalSchedule;
