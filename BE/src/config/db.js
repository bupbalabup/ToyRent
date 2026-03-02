import mongoose from 'mongoose';
import env from './env.js';

const connectDB = async () => {
  mongoose.set('strictQuery', true);

  await mongoose.connect(env.mongoUri, {
    autoIndex: false,
    maxPoolSize: 20
  });
};

export default connectDB;
