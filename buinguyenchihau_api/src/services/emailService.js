require('dotenv').config();
const nodemailer = require('nodemailer');

let transporter = null;

function getTransporter() {
  const user = process.env.GMAIL_USER;
  const pass = process.env.GMAIL_APP_PASSWORD;

  if (!user || !pass) {
    return null;
  }

  if (!transporter) {
    transporter = nodemailer.createTransport({
      service: 'gmail',
      auth: {
        user: user.trim(),
        pass: pass.trim().replace(/\s+/g, ''), // Xóa khoảng trắng nếu user dán app password có dấu cách
      },
    });
  }

  return transporter;
}

/**
 * Gửi email OTP xác thực tài khoản hoặc khôi phục mật khẩu
 * @param {Object} options
 * @param {string} options.toEmail
 * @param {string} options.otpCode
 * @param {'register' | 'reset_password' | 'login'} options.type
 */
async function sendOtpEmail({ toEmail, otpCode, type = 'register' }) {
  const isReset = type === 'reset_password';
  const isLogin = type === 'login';
  const actionTitle = isReset
    ? 'Khôi Phục Mật Khẩu'
    : isLogin
    ? 'Xác Thực Đăng Nhập (2FA)'
    : 'Kích Hoạt Tài Khoản Đăng Ký';
  const subject = `[PRIME Attendance] Mã xác thực OTP ${actionTitle}: ${otpCode}`;

  const htmlContent = `
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <style>
      body { font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f1f5f9; margin: 0; padding: 20px; color: #1e293b; }
      .container { max-width: 540px; margin: 0 auto; background: #ffffff; border-radius: 16px; overflow: hidden; box-shadow: 0 4px 15px rgba(0,0,0,0.06); }
      .header { background: linear-gradient(135deg, #1E3A8A 0%, #3B82F6 100%); color: #ffffff; padding: 28px 24px; text-align: center; }
      .header h1 { margin: 0; font-size: 22px; font-weight: 800; letter-spacing: 0.5px; }
      .header p { margin: 6px 0 0; font-size: 13px; opacity: 0.9; }
      .content { padding: 30px 24px; }
      .greeting { font-size: 16px; font-weight: 600; margin-bottom: 12px; }
      .desc { font-size: 14px; line-height: 1.6; color: #475569; margin-bottom: 24px; }
      .otp-box { background: #f8fafc; border: 2px dashed #3b82f6; border-radius: 12px; padding: 20px; text-align: center; margin: 20px 0; }
      .otp-code { font-size: 34px; font-weight: 800; letter-spacing: 8px; color: #1d4ed8; font-family: monospace; }
      .notice { font-size: 13px; color: #64748b; margin-top: 10px; }
      .warning { font-size: 12px; color: #dc2626; margin-top: 18px; line-height: 1.5; }
      .footer { background: #f8fafc; padding: 18px; text-align: center; font-size: 12px; color: #94a3b8; border-top: 1px solid #e2e8f0; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>PRIME ATTENDANCE</h1>
        <p>Hệ thống Điểm danh Sinh viên Thông minh • Bùi Nguyễn Chí Hậu</p>
      </div>
      <div class="content">
        <div class="greeting">Xin chào bạn,</div>
        <div class="desc">
          Bạn đang thực hiện thao tác <strong>${actionTitle}</strong> trên ứng dụng điểm danh PRIME Attendance. 
          Vui lòng sử dụng mã xác thực OTP 6 chữ số dưới đây để hoàn tất:
        </div>
        <div class="otp-box">
          <div class="otp-code">${otpCode}</div>
          <div class="notice">Mã OTP có hiệu lực trong vòng <strong>5 phút</strong>.</div>
        </div>
        <div class="warning">
          ⚠️ <strong>Lưu ý bảo mật:</strong> Tuyệt đối không chia sẻ mã này cho bất kỳ ai. Nếu bạn không thực hiện yêu cầu này, vui lòng bỏ qua email.
        </div>
      </div>
      <div class="footer">
        Được gửi tự động từ hệ thống PRIME Attendance WebAPI.<br>
        Bản quyền © 2026 Bùi Nguyễn Chí Hậu. Bảo lưu mọi quyền.
      </div>
    </div>
  </body>
  </html>
  `;

  const mailTransporter = getTransporter();

  if (!mailTransporter) {
    console.log(`[EmailService] ⚠️ Gmail chưa cấu hình GMAIL_USER/GMAIL_APP_PASSWORD trong .env.`);
    console.log(`[EmailService] 💡 Chế độ Fallback: Mã OTP cho ${toEmail} là: [ ${otpCode} ]`);
    return {
      sent: false,
      reason: 'GMAIL_NOT_CONFIGURED',
      preview: otpCode,
    };
  }

  try {
    const info = await mailTransporter.sendMail({
      from: `"PRIME Attendance System" <${process.env.GMAIL_USER}>`,
      to: toEmail,
      subject: subject,
      html: htmlContent,
    });

    console.log(`[EmailService] ✉️ Đã gửi email OTP thành công đến: ${toEmail} (MessageId: ${info.messageId})`);
    return {
      sent: true,
      messageId: info.messageId,
    };
  } catch (error) {
    console.error(`[EmailService] ❌ Gửi email đến ${toEmail} thất bại:`, error.message);
    return {
      sent: false,
      error: error.message,
      preview: otpCode,
    };
  }
}

module.exports = {
  sendOtpEmail,
};
