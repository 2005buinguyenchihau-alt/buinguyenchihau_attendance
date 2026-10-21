const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken } = require('../middlewares/auth');

// Đăng ký qua Email & kích hoạt OTP
router.post('/register', authController.register);
router.post('/verify-register-otp', authController.verifyRegisterOtp);

// Đăng nhập 2 bước (Mật khẩu + OTP)
router.post('/login', authController.login);
router.post('/verify-login-otp', authController.verifyLoginOtp);

// Cập nhật khuôn mặt và xem thông tin cá nhân
router.post('/face-register', authenticateToken, authController.registerFace);
router.get('/profile', authenticateToken, authController.getProfile);

module.exports = router;
