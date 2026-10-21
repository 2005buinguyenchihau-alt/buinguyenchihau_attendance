const crypto = require('crypto');

const STEP_SECONDS = 5; // QR đổi mã sau mỗi 5 giây

/**
 * Sinh Dynamic Token cho phiên điểm danh tại thời điểm hiện tại
 * @param {number|string} sessionId ID phiên điểm danh
 * @param {string} secret Khóa bí mật của phiên
 * @returns {{ token: string, expiresInMs: number, timeStep: number }}
 */
function generateDynamicQrToken(sessionId, secret) {
  const now = Date.now();
  const timeStep = Math.floor(now / (STEP_SECONDS * 1000));
  const remainingMs = (timeStep + 1) * STEP_SECONDS * 1000 - now;

  const payload = `${sessionId}:${timeStep}`;
  const signature = crypto.createHmac('sha256', secret).update(payload).digest('hex').substring(0, 16);
  const token = `${sessionId}.${timeStep}.${signature}`;

  return {
    token,
    payload,
    expiresInMs: remainingMs,
    stepSeconds: STEP_SECONDS,
  };
}

/**
 * Xác thực Dynamic Token của QR code
 * @param {string} token Chuỗi token do sinh viên quét được
 * @param {string} secret Khóa bí mật của phiên
 * @returns {{ valid: boolean, message: string }}
 */
function verifyDynamicQrToken(token, secret) {
  if (!token || typeof token !== 'string') {
    return { valid: false, message: 'Mã QR không hợp lệ.' };
  }

  const parts = token.split('.');
  if (parts.length !== 3) {
    return { valid: false, message: 'Định dạng mã QR không đúng chuẩn PRIME.' };
  }

  const [sessionId, timeStepStr, signature] = parts;
  const clientStep = parseInt(timeStepStr, 10);
  const currentStep = Math.floor(Date.now() / (STEP_SECONDS * 1000));

  // Chấp nhận bước hiện tại hoặc bước trước đó 1 bước (chống trễ mạng 2-3s)
  if (clientStep < currentStep - 1) {
    return { valid: false, message: 'Mã QR đã hết hạn! Vui lòng quét lại mã đang hiển thị trên màn hình.' };
  }
  if (clientStep > currentStep + 1) {
    return { valid: false, message: 'Mã QR không hợp lệ (sai lệch thời gian thiết bị).' };
  }

  const expectedPayload = `${sessionId}:${clientStep}`;
  const expectedSignature = crypto.createHmac('sha256', secret).update(expectedPayload).digest('hex').substring(0, 16);

  if (signature !== expectedSignature) {
    return { valid: false, message: 'Chữ ký mã QR không chính xác hoặc đã bị can thiệp.' };
  }

  return { valid: true, sessionId: parseInt(sessionId, 10), message: 'Mã QR hợp lệ.' };
}

module.exports = {
  STEP_SECONDS,
  generateDynamicQrToken,
  verifyDynamicQrToken,
};
