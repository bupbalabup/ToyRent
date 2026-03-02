import mongoose from 'mongoose';
import AppError from '../utils/appError.js';

const validateObjectId = (paramKey = 'id') => (req, res, next) => {
  const value = req.params[paramKey];

  if (!mongoose.Types.ObjectId.isValid(value)) {
    return next(new AppError('Invalid ObjectId', 400));
  }

  return next();
};

export default validateObjectId;
