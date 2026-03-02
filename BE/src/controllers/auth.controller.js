import asyncHandler from '../utils/asyncHandler.js';
import { sendResponse } from '../utils/apiResponse.js';
import AppError from '../utils/appError.js';
import { registerUser, loginUser } from '../services/auth.service.js';

export const register = asyncHandler(async (req, res) => {
  const { name, email, phone, password, avatar } = req.body;

  if (!name || !email || !password) {
    throw new AppError('name, email and password are required', 400);
  }

  const data = await registerUser({ name, email, phone, password, avatar });
  return sendResponse(res, 201, 'Register successful', data);
});

export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    throw new AppError('email and password are required', 400);
  }

  const data = await loginUser({ email, password });
  return sendResponse(res, 200, 'Login successful', data);
});

export const getProfile = asyncHandler(async (req, res) =>
  sendResponse(res, 200, 'Profile fetched', { user: req.user })
);
