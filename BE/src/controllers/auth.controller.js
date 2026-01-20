const { registerUser, loginUser } = require('../services/auth.service.js');

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

module.exports = { register, login, getProfile };
