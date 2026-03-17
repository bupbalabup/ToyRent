const { registerUser, loginUser } = require('../services/auth.service.js');
const User = require('../models/user.model.js');

const EMAIL_REGEX = /^\S+@\S+\.\S+$/;
const PHONE_REGEX = /^[0-9+\-()\s]{8,20}$/;

const isValidUrl = (value) => {
  if (!value) return true;
  try {
    const parsed = new URL(value);
    return parsed.protocol === 'http:' || parsed.protocol === 'https:';
  } catch (_) {
    return false;
  }
};

const register = async (req, res, next) => {
  try {
    const { name, email, phone, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({
        success: false,
        message: 'name, email and password are required',
        data: {}
      });
    }

    if (!EMAIL_REGEX.test(String(email).trim())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format',
        data: {}
      });
    }

    if (String(password).length < 6) {
      return res.status(400).json({
        success: false,
        message: 'password must be at least 6 characters',
        data: {}
      });
    }

    if (phone !== undefined && phone !== null && String(phone).trim().length > 0 && !PHONE_REGEX.test(String(phone).trim())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid phone format',
        data: {}
      });
    }

    const data = await registerUser({ name, email, phone, password });
    return res.status(201).json({ success: true, message: 'Register successful', data });
  } catch (error) {
    return next(error);
  }
};

const login = async (req, res, next) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'email and password are required',
        data: {}
      });
    }

    if (!EMAIL_REGEX.test(String(email).trim())) {
      return res.status(400).json({
        success: false,
        message: 'Invalid email format',
        data: {}
      });
    }

    const data = await loginUser({ email, password });
    return res.status(200).json({ success: true, message: 'Login successful', data });
  } catch (error) {
    return next(error);
  }
};

const getProfile = async (req, res, next) => {
  try {
    return res.status(200).json({
      success: true,
      message: 'Profile fetched',
      data: { user: req.user }
    });
  } catch (error) {
    return next(error);
  }
};

const getAdminUserStats = async (req, res, next) => {
  try {
    const [totalUsers, adminUsers, regularUsers, activeUsers, inactiveUsers, verifiedUsers] = await Promise.all([
      User.countDocuments({}),
      User.countDocuments({ role: 'admin' }),
      User.countDocuments({ role: 'user' }),
      User.countDocuments({ isActive: { $ne: false } }),
      User.countDocuments({ isActive: false }),
      User.countDocuments({ isVerified: true })
    ]);

    return res.status(200).json({
      success: true,
      message: 'User stats fetched',
      data: {
        totalUsers,
        adminUsers,
        regularUsers,
        activeUsers,
        inactiveUsers,
        verifiedUsers
      }
    });
  } catch (error) {
    return next(error);
  }
};

const getAllUsers = async (req, res, next) => {
  try {
    const {
      search = '',
      role = 'all',
      status = 'all',
      verified = 'all',
      page = '1',
      limit = '10'
    } = req.query;

    const parsedPage = Math.max(parseInt(page, 10) || 1, 1);
    const parsedLimit = Math.min(Math.max(parseInt(limit, 10) || 10, 1), 100);

    const query = {};

    if (search) {
      const regex = new RegExp(search.trim(), 'i');
      query.$or = [{ name: regex }, { email: regex }, { phone: regex }];
    }

    if (role !== 'all') {
      query.role = role;
    }

    if (status === 'active') {
      query.isActive = { $ne: false };
    } else if (status === 'inactive') {
      query.isActive = false;
    }

    if (verified === 'verified') {
      query.isVerified = true;
    } else if (verified === 'unverified') {
      query.isVerified = false;
    }

    const [users, total] = await Promise.all([
      User.find(query)
        .select('-password')
        .sort({ createdAt: -1 })
        .skip((parsedPage - 1) * parsedLimit)
        .limit(parsedLimit),
      User.countDocuments(query)
    ]);

    const totalPages = Math.ceil(total / parsedLimit) || 1;

    return res.status(200).json({
      success: true,
      message: 'Users fetched',
      data: {
        users,
        pagination: {
          page: parsedPage,
          limit: parsedLimit,
          total,
          totalPages,
          hasNextPage: parsedPage < totalPages,
          hasPreviousPage: parsedPage > 1
        }
      }
    });
  } catch (error) {
    return next(error);
  }
};

const updateUserRole = async (req, res, next) => {
  try {
    const { role } = req.body;
    if (!['user', 'admin'].includes(role)) {
      return res.status(400).json({
        success: false,
        message: 'role must be either user or admin',
        data: {}
      });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { role, updatedAt: new Date() },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found', data: {} });
    }

    return res.status(200).json({ success: true, message: 'User role updated', data: { user } });
  } catch (error) {
    return next(error);
  }
};

const updateUserStatus = async (req, res, next) => {
  try {
    const { isActive } = req.body;

    if (typeof isActive !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isActive must be a boolean',
        data: {}
      });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isActive, updatedAt: new Date() },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found', data: {} });
    }

    return res.status(200).json({
      success: true,
      message: 'User status updated',
      data: { user }
    });
  } catch (error) {
    return next(error);
  }
};

const updateUserVerification = async (req, res, next) => {
  try {
    const { isVerified } = req.body;

    if (typeof isVerified !== 'boolean') {
      return res.status(400).json({
        success: false,
        message: 'isVerified must be a boolean',
        data: {}
      });
    }

    const user = await User.findByIdAndUpdate(
      req.params.id,
      { isVerified, updatedAt: new Date() },
      { new: true, runValidators: true }
    ).select('-password');

    if (!user) {
      return res.status(404).json({ success: false, message: 'User not found', data: {} });
    }

    return res.status(200).json({
      success: true,
      message: 'User verification updated',
      data: { user }
    });
  } catch (error) {
    return next(error);
  }
};

const updateProfile = async (req, res, next) => {
  try {
    const { name, email, avatar } = req.body;
    const updates = {};

    if (name !== undefined) {
      if (!name || typeof name !== 'string') {
        return res.status(400).json({ success: false, message: 'name must be a non-empty string', data: {} });
      }
      updates.name = name.trim();
    }

    if (email !== undefined) {
      if (!email || typeof email !== 'string') {
        return res.status(400).json({ success: false, message: 'email must be a non-empty string', data: {} });
      }
      const normalizedEmail = email.toLowerCase().trim();
      if (!EMAIL_REGEX.test(normalizedEmail)) {
        return res.status(400).json({ success: false, message: 'Invalid email format', data: {} });
      }
      const emailExists = await User.findOne({
        email: normalizedEmail,
        _id: { $ne: req.user._id }
      });
      if (emailExists) {
        return res.status(409).json({ success: false, message: 'Email already in use', data: {} });
      }
      updates.email = normalizedEmail;
    }

    if (avatar !== undefined) {
      if (avatar && (typeof avatar !== 'string' || !isValidUrl(avatar))) {
        return res.status(400).json({ success: false, message: 'avatar must be a valid http/https URL', data: {} });
      }
      updates.avatar = avatar || null;
    }

    updates.updatedAt = new Date();

    const user = await User.findByIdAndUpdate(req.user._id, updates, {
      new: true,
      runValidators: true
    }).select('-password');

    return res.status(200).json({
      success: true,
      message: 'Profile updated',
      data: { user }
    });
  } catch (error) {
    return next(error);
  }
};

module.exports = {
  register,
  login,
  getProfile,
  getAdminUserStats,
  getAllUsers,
  updateUserRole,
  updateUserStatus,
  updateUserVerification,
  updateProfile
};
