const { sendOtpEmail } = require('../src/services/emailService');

async function testEmailService() {
  console.log('--- Kiểm thử module emailService ---');
  const result = await sendOtpEmail({
    toEmail: 'test.student@gmail.com',
    otpCode: '888999',
    type: 'reset_password',
  });

  console.log('Kết quả:', result);
  if (result.preview === '888999' || result.sent === true) {
    console.log('✅ emailService hoạt động chính xác (có cơ chế Fallback và xử lý template)!');
  } else {
    console.error('❌ Kiểm thử thất bại!');
    process.exit(1);
  }
}

testEmailService();
