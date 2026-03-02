import mongoose from 'mongoose';

const { Schema } = mongoose;

const addressSchema = new Schema(
  {
    fullName: { type: String, trim: true },
    phone: { type: String, trim: true },
    street: { type: String, trim: true },
    district: { type: String, trim: true },
    city: { type: String, trim: true }
  },
  { _id: false }
);

const cartItemSchema = new Schema(
  {
    toyId: { type: Schema.Types.ObjectId, ref: 'Toy', required: true },
    quantity: { type: Number, required: true, min: 1, default: 1 },
    rentalDays: { type: Number, required: true, min: 1, default: 1 }
  },
  { _id: false }
);

const userSchema = new Schema(
  {
    name: { type: String, required: true, trim: true },
    email: {
      type: String,
      required: true,
      unique: true,
      lowercase: true,
      trim: true,
      match: [/^\S+@\S+\.\S+$/, 'Invalid email format']
    },
    phone: { type: String, trim: true, index: true },
    password: { type: String, required: true },
    avatar: { type: String, trim: true },
    role: { type: String, enum: ['user', 'admin'], default: 'user' },
    address: { type: addressSchema, default: undefined },
    isVerified: { type: Boolean, default: false },
    cart: { type: [cartItemSchema], default: [] }
  },
  { timestamps: true }
);

const User = mongoose.model('User', userSchema);

export default User;
