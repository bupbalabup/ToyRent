const { Router } = require('express');
const {
	register,
	login,
	getProfile,
	getAdminUserStats,
	getAllUsers,
	updateUserRole,
	updateUserStatus,
	updateUserVerification,
	updateProfile
} = require('../controllers/auth.controller.js');
const { protect, allowAdminOnly } = require('../middlewares/auth.middleware.js');

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/profile', protect, getProfile);
router.patch('/profile', protect, updateProfile);
router.get('/admin/user-stats', protect, allowAdminOnly, getAdminUserStats);
router.get('/admin/users', protect, allowAdminOnly, getAllUsers);
router.patch('/admin/users/:id/role', protect, allowAdminOnly, updateUserRole);
router.patch('/admin/users/:id/status', protect, allowAdminOnly, updateUserStatus);
router.patch('/admin/users/:id/verify', protect, allowAdminOnly, updateUserVerification);

module.exports = router;
