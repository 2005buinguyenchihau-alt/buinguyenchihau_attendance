const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');
const { authenticateToken, optionalAuth } = require('../middlewares/auth');

// Đăng ký qua Email & kích hoạt OTP
router.post('/register', authController.register);
router.post('/verify-register-otp', authController.verifyRegisterOtp);

// Đăng nhập 2 bước (Mật khẩu + OTP)
router.post('/login', authController.login);
router.post('/verify-login-otp', authController.verifyLoginOtp);

// Quên mật khẩu & Đặt lại mật khẩu qua OTP
router.post('/forgot-password', authController.forgotPassword);
router.post('/reset-password', authController.resetPassword);

// Cập nhật khuôn mặt và xem thông tin cá nhân
router.post('/face-register', optionalAuth, authController.registerFace);
router.post('/face-login', authController.faceLogin);
router.get('/profile', authenticateToken, authController.getProfile);

module.exports = router;
