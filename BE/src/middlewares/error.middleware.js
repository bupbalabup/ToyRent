import mongoose from 'mongoose';
import { sendResponse } from '../utils/apiResponse.js';

const errorMiddleware = (err, req, res, next) => {
  let statusCode = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';

  if (err instanceof mongoose.Error.ValidationError) {
    statusCode = 400;
    message = Object.values(err.errors)
      .map((e) => e.message)
      .join(', ');
  }

  if (err?.code === 11000) {
    statusCode = 409;
    message = 'Duplicate value error';
  }

  if (err instanceof mongoose.Error.CastError) {
    statusCode = 400;
    message = 'Invalid resource identifier';
  }

  return sendResponse(res, statusCode, message, {});
};

export default errorMiddleware;
