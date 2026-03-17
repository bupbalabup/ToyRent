require('dotenv/config');
const bcrypt = require('bcrypt');
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
const jwtExpiresIn = process.env.JWT_EXPIRES_IN || '7d';

if (!jwtSecret) {
  throw new Error('JWT_SECRET is required');
}

const signToken = (userId) =>
  jwt.sign({ userId }, jwtSecret, {
    expiresIn: jwtExpiresIn
  });

const registerUser = async ({ name, email, phone, password }) => {
  const existingUser = await User.findOne({ email: email.toLowerCase() });

  if (existingUser) {
    throw new AppError('Email already in use', 409);
  }

  const hashedPassword = await bcrypt.hash(password, 12);

  const user = await User.create({
    name,
    email,
    phone,
    password: hashedPassword
  });

  const token = signToken(user._id);

  const safeUser = {
    _id: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    isActive: user.isActive,
    isVerified: user.isVerified,
    avatar: user.avatar
  };

  return { user: safeUser, token };
};

const loginUser = async ({ email, password }) => {
  const user = await User.findOne({ email: email.toLowerCase() });

  if (!user) {
    throw new AppError('Invalid credentials', 401);
  }

  if (user.isActive === false) {
    throw new AppError('Your account is inactive. Please contact admin.', 403);
  }

  const passwordMatched = await bcrypt.compare(password, user.password);

  if (!passwordMatched) {
    throw new AppError('Invalid credentials', 401);
  }

  const token = signToken(user._id);

  const safeUser = {
    _id: user._id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    isActive: user.isActive,
    isVerified: user.isVerified,
    avatar: user.avatar
  };

  return { user: safeUser, token };
};

module.exports = { registerUser, loginUser };
