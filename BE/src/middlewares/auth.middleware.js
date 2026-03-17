require('dotenv/config');
const jwt = require('jsonwebtoken');
const User = require('../models/user.model.js');

class AppError extends Error {
  constructor(message, statusCode) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    Error.captureStackTrace(this, this.constructor);
  }
}

const jwtSecret = process.env.JWT_SECRET;

if (!jwtSecret) {
  throw new Error('JWT_SECRET is required');
}

const protect = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next(new AppError('Unauthorized', 401));
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, jwtSecret);

    const user = await User.findById(decoded.userId).select('-password');

    if (!user) {
      return next(new AppError('User not found', 401));
    }

    if (user.isActive === false) {
      return next(new AppError('Account is inactive', 403));
    }

    req.user = user;
    return next();
  } catch (error) {
    return next(new AppError('Invalid or expired token', 401));
  }
};

const allowRoles = (...roles) => (req, res, next) => {
  if (!req.user || !roles.includes(req.user.role)) {
    return next(new AppError('Forbidden', 403));
  }

  return next();
};

const allowUserOnly = (req, res, next) => {
  if (!req.user || req.user.role !== 'user') {
    return next(new AppError('Forbidden', 403));
  }

  return next();
};

const allowAdminOnly = (req, res, next) => {
  if (!req.user || req.user.role !== 'admin') {
    return next(new AppError('Forbidden', 403));
  }

  return next();
};

module.exports = { protect, allowRoles, allowUserOnly, allowAdminOnly };
