const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { db } = require('../config/database');
const { generateOtp, verifyOtp } = require('../utils/otp');
const { JWT_SECRET } = require('../middlewares/auth');

// Lưu tạm thông tin đăng ký chờ xác thực OTP
const pendingRegistrations = new Map();

/**
 * 1. Đăng ký tài khoản qua Email (Bước 1: Nhập thông tin & gửi OTP)
 */
function register(req, res) {
  try {
    const { username, email, password, full_name, code, role } = req.body;

    if (!username || !email || !password || !full_name || !code) {
      return res.status(400).json({ success: false, message: 'Vui lòng điền đầy đủ các thông tin bắt buộc.' });
    }

    const assignedRole = role === 'lecturer' ? 'lecturer' : role === 'admin' ? 'admin' : 'student';

    // Kiểm tra username hoặc email đã tồn tại chưa
    const existing = db.prepare('SELECT id, username, email FROM users WHERE username = ? OR email = ?').get(username, email);
    if (existing) {
      if (existing.username === username) {
        return res.status(400).json({ success: false, message: 'Tên đăng nhập này đã được sử dụng.' });
      }
      return res.status(400).json({ success: false, message: 'Email này đã được đăng ký tài khoản.' });
    }

    const salt = bcrypt.genSaltSync(10);
    const password_hash = bcrypt.hashSync(password, salt);

    // Lưu vào pending map
    pendingRegistrations.set(email, {
      username,
      email,
      password_hash,
      full_name,
      code,
      role: assignedRole,
    });

    // Sinh mã OTP 6 số
    const { code: otpCode, expiresAt } = generateOtp(email, 'register');

    return res.status(200).json({
      success: true,
      message: `Mã OTP xác thực đăng ký đã được gửi đến ${email}.`,
      data: {
        email,
        expiresAt,
        // Cung cấp otpCode để demo/thuyết trình và test nhanh mà không bị phụ thuộc SMTP
        otpPreview: otpCode,
      },
    });
  } catch (error) {
    console.error('Error in register:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ nội bộ: ' + error.message });
  }
}

/**
 * 2. Xác thực OTP đăng ký (Bước 2: Kích hoạt tài khoản và cấp Token)
 */
function verifyRegisterOtp(req, res) {
  try {
    const { email, otp_code } = req.body;

    if (!email || !otp_code) {
      return res.status(400).json({ success: false, message: 'Thiếu email hoặc mã OTP.' });
    }

    const otpResult = verifyOtp(email, otp_code, 'register');
    if (!otpResult.valid) {
      return res.status(400).json({ success: false, message: otpResult.message });
    }

    const pending = pendingRegistrations.get(email);
    if (!pending) {
      return res.status(400).json({ success: false, message: 'Không tìm thấy phiên đăng ký hoặc phiên đã hết hạn. Vui lòng đăng ký lại.' });
    }

    const insertStmt = db.prepare(`
      INSERT INTO users (username, email, password_hash, full_name, code, role)
      VALUES (?, ?, ?, ?, ?, ?)
    `);

    const result = insertStmt.run(
      pending.username,
      pending.email,
      pending.password_hash,
      pending.full_name,
      pending.code,
      pending.role
    );

    pendingRegistrations.delete(email);

    const newUser = db.prepare('SELECT id, username, email, full_name, code, role, avatar, created_at FROM users WHERE id = ?').get(result.lastInsertRowid);

    const token = jwt.sign(
      { id: newUser.id, username: newUser.username, email: newUser.email, role: newUser.role },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(201).json({
      success: true,
      message: 'Đăng ký và kích hoạt tài khoản thành công!',
      data: {
        user: newUser,
        token,
      },
    });
  } catch (error) {
    console.error('Error in verifyRegisterOtp:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

/**
 * 3. Đăng nhập (Username + Mật khẩu + Yêu cầu mã OTP 2FA)
 */
function login(req, res) {
  try {
    const { usernameOrEmail, password } = req.body;

    if (!usernameOrEmail || !password) {
      return res.status(400).json({ success: false, message: 'Vui lòng nhập tên đăng nhập/email và mật khẩu.' });
    }

    const user = db.prepare('SELECT * FROM users WHERE username = ? OR email = ?').get(usernameOrEmail, usernameOrEmail);
    if (!user) {
      return res.status(401).json({ success: false, message: 'Tài khoản không tồn tại trên hệ thống PRIME.' });
    }

    const isMatch = bcrypt.compareSync(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: 'Mật khẩu không chính xác.' });
    }

    // Sinh mã OTP 2FA cho phiên đăng nhập
    const { code: otpCode, expiresAt } = generateOtp(user.email, 'login');

    return res.status(200).json({
      success: true,
      message: `Đăng nhập bước 1 thành công. Vui lòng nhập mã OTP gửi tới ${user.email}.`,
      data: {
        email: user.email,
        username: user.username,
        role: user.role,
        requiresOtp: true,
        expiresAt,
        otpPreview: otpCode, // Tiện lợi cho thuyết trình
      },
    });
  } catch (error) {
    console.error('Error in login:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

/**
 * 4. Xác thực OTP Đăng nhập (Bước 2 của Đăng nhập 2FA)
 */
function verifyLoginOtp(req, res) {
  try {
    const { email, otp_code } = req.body;

    if (!email || !otp_code) {
      return res.status(400).json({ success: false, message: 'Thiếu email hoặc mã OTP.' });
    }

    const otpResult = verifyOtp(email, otp_code, 'login');
    if (!otpResult.valid) {
      return res.status(400).json({ success: false, message: otpResult.message });
    }

    const user = db.prepare('SELECT id, username, email, full_name, code, role, avatar, face_data, created_at FROM users WHERE email = ?').get(email);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng tương ứng.' });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, email: user.email, role: user.role, full_name: user.full_name },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    return res.status(200).json({
      success: true,
      message: 'Đăng nhập thành công!',
      data: {
        user,
        token,
      },
    });
  } catch (error) {
    console.error('Error in verifyLoginOtp:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

/**
 * 5. Cập nhật dữ liệu khuôn mặt mẫu (Face Registration)
 */
function registerFace(req, res) {
  try {
    const userId = req.user.id;
    const { face_data, avatar } = req.body;

    if (!face_data) {
      return res.status(400).json({ success: false, message: 'Thiếu dữ liệu khuôn mặt.' });
    }

    db.prepare('UPDATE users SET face_data = ?, avatar = COALESCE(?, avatar) WHERE id = ?').run(face_data, avatar || null, userId);

    return res.status(200).json({
      success: true,
      message: 'Đã lưu mẫu khuôn mặt sinh trắc học thành công!',
    });
  } catch (error) {
    console.error('Error in registerFace:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

/**
 * 6. Lấy thông tin cá nhân
 */
function getProfile(req, res) {
  try {
    const user = db.prepare('SELECT id, username, email, full_name, code, role, avatar, face_data, created_at FROM users WHERE id = ?').get(req.user.id);
    return res.status(200).json({ success: true, data: user });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  register,
  verifyRegisterOtp,
  login,
  verifyLoginOtp,
  registerFace,
  getProfile,
};
