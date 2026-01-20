const { Router } = require('express');
const { register, login, getProfile } = require('../controllers/auth.controller.js');
const { protect } = require('../middlewares/auth.middleware.js');

const router = Router();

router.post('/register', register);
router.post('/login', login);
router.get('/profile', protect, getProfile);

module.exports = router;
