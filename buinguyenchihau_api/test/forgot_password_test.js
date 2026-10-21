const http = require('http');
const path = require('path');
const { DatabaseSync } = require('node:sqlite');
const db = new DatabaseSync(path.join(__dirname, '../buinguyenchihau_db.sqlite'));

function getLatestOtp(email) {
  const row = db.prepare('SELECT otp_code FROM otp_codes WHERE LOWER(email) = LOWER(?) ORDER BY id DESC LIMIT 1').get(email);
  return row ? row.otp_code : null;
}

function post(path, body) {
  return new Promise((resolve, reject) => {
    const data = JSON.stringify(body);
    const req = http.request(
      {
        hostname: 'localhost',
        port: 5000,
        path: path,
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(data),
        },
      },
      (res) => {
        let resData = '';
        res.on('data', (chunk) => (resData += chunk));
        res.on('end', () => {
          try {
            resolve({ status: res.statusCode, body: JSON.parse(resData) });
          } catch (e) {
            resolve({ status: res.statusCode, raw: resData });
          }
        });
      }
    );
    req.on('error', reject);
    req.write(data);
    req.end();
  });
}

async function run() {
  console.log('--- Testing Forgot Password Flow ---');
  const email = '2005buinguyenchihau@gmail.com';

  // Step 1: Request OTP for password reset
  console.log(`1. Requesting forgot password OTP for ${email}...`);
  const step1 = await post('/api/auth/forgot-password', { email });
  console.log('Response 1:', step1);
  if (step1.status !== 200 || !step1.body.success) {
    throw new Error('Forgot password request failed: ' + JSON.stringify(step1));
  }

  const otpCode = step1.body.data?.otpPreview || getLatestOtp(email);
  console.log(`Using OTP: ${otpCode}`);

  // Step 2: Reset password
  const newPassword = 'student_new_pass_123';
  console.log(`2. Resetting password with OTP...`);
  const step2 = await post('/api/auth/reset-password', {
    email,
    otpCode,
    newPassword,
  });
  console.log('Response 2:', step2);
  if (step2.status !== 200 || !step2.body.success) {
    throw new Error('Reset password failed: ' + JSON.stringify(step2));
  }

  // Step 3: Login with new password
  console.log(`3. Logging in with new password...`);
  const step3 = await post('/api/auth/login', {
    usernameOrEmail: email,
    password: newPassword,
  });
  console.log('Login Response:', step3.status, step3.body.success ? 'SUCCESS' : 'FAILED');
  if (step3.status !== 200 || !step3.body.success) {
    throw new Error('Login with new password failed');
  }

  // Step 4: Reset back to 'Sv@123456' so default credentials remain intact
  console.log(`4. Resetting back to default password 'Sv@123456'...`);
  const step4Forgot = await post('/api/auth/forgot-password', { email });
  const resetOtp = step4Forgot.body.data?.otpPreview || getLatestOtp(email);
  await post('/api/auth/reset-password', {
    email,
    otpCode: resetOtp,
    newPassword: 'Sv@123456',
  });
  console.log('Restored default password successfully!');

  console.log('\n✅ ALL FORGOT PASSWORD FLOW TESTS PASSED!');
}

run().catch((err) => {
  console.error('❌ Test failed:', err);
  process.exit(1);
});
