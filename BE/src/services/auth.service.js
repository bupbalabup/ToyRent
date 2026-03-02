import bcrypt from 'bcrypt';
import jwt from 'jsonwebtoken';
import User from '../models/user.model.js';
import env from '../config/env.js';
import AppError from '../utils/appError.js';

const signToken = (userId) =>
  jwt.sign({ userId }, env.jwtSecret, {
    expiresIn: env.jwtExpiresIn
  });

export const registerUser = async ({ name, email, phone, password, avatar }) => {
  const existingUser = await User.findOne({ email: email.toLowerCase() });

  if (existingUser) {
    throw new AppError('Email already in use', 409);
  }

  const hashedPassword = await bcrypt.hash(password, 12);

  const user = await User.create({
    name,
    email,
    phone,
    password: hashedPassword,
    avatar
  });

  const token = signToken(user._id);

  const safeUser = user.toObject();
  delete safeUser.password;

  return { user: safeUser, token };
};

export const loginUser = async ({ email, password }) => {
  const user = await User.findOne({ email: email.toLowerCase() });

  if (!user) {
    throw new AppError('Invalid credentials', 401);
  }

  const passwordMatched = await bcrypt.compare(password, user.password);

  if (!passwordMatched) {
    throw new AppError('Invalid credentials', 401);
  }

  const token = signToken(user._id);

  const safeUser = user.toObject();
  delete safeUser.password;

  return { user: safeUser, token };
};
