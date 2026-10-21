const { db } = require('../config/database');

function generateOtp(email, type = 'register') {
  // Generate 6 digit code
  const code = Math.floor(100000 + Math.random() * 900000).toString();
  // Valid for 5 minutes
  const expiresAt = new Date(Date.now() + 5 * 60 * 1000).toISOString();

  // Invalidate previous OTPs for this email and type
  const invalidateStmt = db.prepare(`
    UPDATE otp_codes SET is_used = 1 WHERE email = ? AND type = ? AND is_used = 0
  `);
  invalidateStmt.run(email, type);

  // Insert new OTP
  const insertStmt = db.prepare(`
    INSERT INTO otp_codes (email, otp_code, type, expires_at)
    VALUES (?, ?, ?, ?)
  `);
  insertStmt.run(email, code, type, expiresAt);

  console.log(`[OTP] Generated OTP for ${email} (${type}): ${code}`);
  return { code, expiresAt };
}

function verifyOtp(email, code, type = 'register') {
  const stmt = db.prepare(`
    SELECT * FROM otp_codes 
    WHERE email = ? AND otp_code = ? AND type = ? AND is_used = 0
    ORDER BY id DESC LIMIT 1
  `);
  const record = stmt.get(email, code, type);

  if (!record) {
    return { valid: false, message: 'Mã OTP không chính xác hoặc đã được sử dụng.' };
  }

  const now = new Date();
  const expiresAt = new Date(record.expires_at);

  if (now > expiresAt) {
    return { valid: false, message: 'Mã OTP đã hết hạn (chỉ có hiệu lực trong 5 phút).' };
  }

  // Mark as used
  db.prepare('UPDATE otp_codes SET is_used = 1 WHERE id = ?').run(record.id);
  return { valid: true, message: 'Xác thực OTP thành công!' };
}

module.exports = {
  generateOtp,
  verifyOtp,
};
