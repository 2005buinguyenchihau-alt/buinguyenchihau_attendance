const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { db } = require('../config/database');
const { generateOtp, verifyOtp } = require('../utils/otp');
const { JWT_SECRET } = require('../middlewares/auth');
const { sendOtpEmail } = require('../services/emailService');

// Lưu tạm thông tin đăng ký chờ xác thực OTP
const pendingRegistrations = new Map();

/**
 * 1. Đăng ký tài khoản qua Email (Bước 1: Nhập thông tin & gửi OTP)
 */
async function register(req, res) {
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

    // Gửi email OTP xác thực tài khoản qua Gmail
    let mailResult = null;
    try {
      mailResult = await sendOtpEmail({ toEmail: email, otpCode, type: 'register' });
    } catch (err) {
      console.error('[Register] Error sending email:', err.message);
    }

    return res.status(200).json({
      success: true,
      message: `Mã OTP xác thực đăng ký đã được gửi đến ${email}.`,
      data: {
        email,
        expiresAt,
        // Chỉ gửi otpPreview nếu mail KHÔNG gửi được (fallback chế độ demo/offline)
        otpPreview: mailResult?.sent ? undefined : otpCode,
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
async function login(req, res) {
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

    let mailResult = null;
    try {
      mailResult = await sendOtpEmail({ toEmail: user.email, otpCode, type: 'login' });
    } catch (err) {
      console.error('[Login] Error sending email:', err.message);
    }

    return res.status(200).json({
      success: true,
      message: `Đăng nhập bước 1 thành công. Vui lòng nhập mã OTP gửi tới ${user.email}.`,
      data: {
        email: user.email,
        username: user.username,
        role: user.role,
        requiresOtp: true,
        expiresAt,
        otpPreview: mailResult?.sent ? undefined : otpCode,
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
    const userId = req.user?.id;
    const { usernameOrEmail, face_data, avatar } = req.body;

    if (!face_data) {
      return res.status(400).json({ success: false, message: 'Vui lòng cung cấp dữ liệu hình ảnh khuôn mặt.' });
    }

    let user = null;
    if (userId) {
      user = db.prepare('SELECT * FROM users WHERE id = ?').get(userId);
    } else if (usernameOrEmail && usernameOrEmail.trim().length > 0) {
      const trimmed = usernameOrEmail.trim();
      user = db.prepare('SELECT * FROM users WHERE LOWER(username) = LOWER(?) OR LOWER(email) = LOWER(?)').get(trimmed, trimmed);
    }

    if (!user) {
      return res.status(400).json({ success: false, message: 'Vui lòng chỉ định tài khoản hợp lệ để đăng ký khuôn mặt.' });
    }

    db.prepare('UPDATE users SET face_data = ?, avatar = COALESCE(?, avatar) WHERE id = ?').run(face_data, avatar || null, user.id);

    console.log(`[FaceRegister] Đã đăng ký khuôn mặt thành công cho: ${user.full_name} (${user.username})`);

    return res.status(200).json({
      success: true,
      message: `Đã đăng ký và lưu mẫu khuôn mặt thành công cho ${user.full_name}!`,
      data: {
        username: user.username,
        full_name: user.full_name,
      },
    });
  } catch (error) {
    console.error('Error in registerFace:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

/**
 * 5b. Đăng nhập bằng sinh trắc học khuôn mặt (Face Login)
 */
function faceLogin(req, res) {
  try {
    const { usernameOrEmail, face_data } = req.body;

    if (!face_data) {
      return res.status(400).json({ success: false, message: 'Vui lòng cung cấp dữ liệu hình ảnh khuôn mặt.' });
    }

    if (!usernameOrEmail || usernameOrEmail.trim().length === 0) {
      return res.status(400).json({ success: false, message: 'Vui lòng chọn hoặc nhập tài khoản cần đăng nhập bằng khuôn mặt.' });
    }

    const trimmedAccount = usernameOrEmail.trim();
    const user = db.prepare('SELECT * FROM users WHERE LOWER(username) = LOWER(?) OR LOWER(email) = LOWER(?)').get(trimmedAccount, trimmedAccount);

    if (!user) {
      return res.status(404).json({ success: false, message: `Không tìm thấy tài khoản "${trimmedAccount}" trong hệ thống.` });
    }

    // 1. Kiểm tra tài khoản đã đăng ký khuôn mặt hay chưa
    if (!user.face_data) {
      return res.status(400).json({
        success: false,
        notRegistered: true,
        message: `Tài khoản "${user.full_name}" CHƯA ĐĂNG KÝ khuôn mặt! Vui lòng bấm "Đăng ký khuôn mặt này" trước để hệ thống ghi nhớ gương mặt bạn.`,
      });
    }

    // 2. So khớp khuôn mặt: Bắt buộc khuôn mặt quét phải trùng khớp với khuôn mặt đã đăng ký
    if (user.face_data !== face_data) {
      return res.status(401).json({
        success: false,
        message: `Khuôn mặt quét được KHÔNG TRÙNG KHỚP với khuôn mặt đã đăng ký của ${user.full_name}! Truy cập bị từ chối.`,
      });
    }

    const token = jwt.sign(
      { id: user.id, username: user.username, email: user.email, role: user.role, full_name: user.full_name },
      JWT_SECRET,
      { expiresIn: '7d' }
    );

    const safeUser = {
      id: user.id,
      username: user.username,
      email: user.email,
      full_name: user.full_name,
      code: user.code,
      role: user.role,
      avatar: user.avatar,
    };

    console.log(`[FaceLogin] Xác thực khuôn mặt CHÍNH CHỦ thành công: ${user.full_name} (${user.role})`);

    return res.status(200).json({
      success: true,
      message: `Xác thực khuôn mặt thành công! Chào mừng ${user.full_name}.`,
      data: {
        user: safeUser,
        token,
      },
    });
  } catch (error) {
    console.error('Error in faceLogin:', error);
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

/**
 * 7. Quên mật khẩu - Yêu cầu gửi mã OTP về Gmail
 */
async function forgotPassword(req, res) {
  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ success: false, message: 'Vui lòng cung cấp địa chỉ email.' });
    }

    const trimmedEmail = email.trim().toLowerCase();
    const user = db.prepare('SELECT id, username, email, full_name FROM users WHERE LOWER(email) = ?').get(trimmedEmail);

    if (!user) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy tài khoản nào gắn với email này.' });
    }

    // Sinh mã OTP loại reset_password
    const { code: otpCode, expiresAt } = generateOtp(user.email, 'reset_password');

    // Gửi email OTP khôi phục mật khẩu qua Gmail
    let mailResult = null;
    try {
      mailResult = await sendOtpEmail({ toEmail: user.email, otpCode, type: 'reset_password' });
    } catch (err) {
      console.error('[ForgotPassword] Error sending email:', err.message);
    }

    return res.status(200).json({
      success: true,
      message: `Mã OTP khôi phục mật khẩu đã được gửi đến ${user.email}.`,
      data: {
        email: user.email,
        expiresAt,
        otpPreview: mailResult?.sent ? undefined : otpCode,
      },
    });
  } catch (error) {
    console.error('Error in forgotPassword:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

/**
 * 8. Đặt lại mật khẩu mới bằng mã OTP
 */
function resetPassword(req, res) {
  try {
    const email = req.body.email;
    const otp_code = req.body.otp_code || req.body.otpCode;
    const new_password = req.body.new_password || req.body.newPassword;

    if (!email || !otp_code || !new_password) {
      return res.status(400).json({ success: false, message: 'Vui lòng điền đầy đủ email, mã OTP và mật khẩu mới.' });
    }

    if (new_password.length < 6) {
      return res.status(400).json({ success: false, message: 'Mật khẩu mới phải có ít nhất 6 ký tự.' });
    }

    const trimmedEmail = email.trim().toLowerCase();
    const otpResult = verifyOtp(trimmedEmail, otp_code.trim(), 'reset_password');

    if (!otpResult.valid) {
      return res.status(400).json({ success: false, message: otpResult.message });
    }

    const user = db.prepare('SELECT id FROM users WHERE LOWER(email) = ?').get(trimmedEmail);
    if (!user) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy người dùng tương ứng.' });
    }

    const salt = bcrypt.genSaltSync(10);
    const password_hash = bcrypt.hashSync(new_password, salt);

    db.prepare('UPDATE users SET password_hash = ? WHERE id = ?').run(password_hash, user.id);

    console.log(`[Auth] Đã đổi mật khẩu thành công cho tài khoản ${trimmedEmail}`);

    return res.status(200).json({
      success: true,
      message: 'Đặt lại mật khẩu thành công! Bạn có thể đăng nhập bằng mật khẩu mới.',
    });
  } catch (error) {
    console.error('Error in resetPassword:', error);
    return res.status(500).json({ success: false, message: 'Lỗi máy chủ: ' + error.message });
  }
}

module.exports = {
  register,
  verifyRegisterOtp,
  login,
  verifyLoginOtp,
  registerFace,
  faceLogin,
  getProfile,
  forgotPassword,
  resetPassword,
};
