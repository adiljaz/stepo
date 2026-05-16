const express = require('express');
const router = express.Router();
const { googleLogin, refreshToken, logout, register, emailLogin } = require('../controllers/authController');
const { protect } = require('../middlewares/authMiddleware');

router.post('/google', googleLogin);
router.post('/register', register);
router.post('/login', emailLogin);
router.post('/refresh', refreshToken);
router.post('/logout', protect, logout);

module.exports = router;
