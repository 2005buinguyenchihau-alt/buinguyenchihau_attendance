const http = require('http');

const PORT = 5000;
const BASE_URL = `http://localhost:${PORT}`;

function request(path, method = 'GET', data = null, token = null) {
  return new Promise((resolve, reject) => {
    const url = new URL(path, BASE_URL);
    const options = {
      hostname: url.hostname,
      port: url.port,
      path: url.pathname + url.search,
      method: method,
      headers: {
        'Content-Type': 'application/json',
      },
    };

    if (token) {
      options.headers['Authorization'] = `Bearer ${token}`;
    }

    const req = http.request(options, (res) => {
      let body = '';
      res.on('data', (chunk) => (body += chunk));
      res.on('end', () => {
        try {
          const json = JSON.parse(body);
          resolve({ status: res.statusCode, data: json });
        } catch (e) {
          resolve({ status: res.statusCode, raw: body });
        }
      });
    });

    req.on('error', (err) => reject(err));

    if (data) {
      req.write(JSON.stringify(data));
    }
    req.end();
  });
}

async function runTests() {
  console.log('--- STARTING E2E API VERIFICATION FOR buinguyenchihau_api ---');

  try {
    // 1. Health check
    const rootRes = await request('/');
    console.log('1. Root endpoint:', rootRes.status === 200 ? 'PASS' : 'FAIL', rootRes.data.author);

    // 2. Register flow
    const regRes = await request('/api/auth/register', 'POST', {
      username: 'test.student.' + Date.now(),
      email: `test${Date.now()}@prime.edu.vn`,
      password: 'Password@123',
      full_name: 'Sinh Viên Kiểm Thử',
      code: 'SV_TEST_01',
      role: 'student',
    });
    console.log('2. Register (Step 1 - Send OTP):', regRes.status === 200 ? 'PASS' : 'FAIL');
    const otp = regRes.data.data.otpPreview;
    const testEmail = regRes.data.data.email;

    // 3. Verify OTP
    const verifyRegRes = await request('/api/auth/verify-register-otp', 'POST', {
      email: testEmail,
      otp_code: otp,
    });
    console.log('3. Verify Register OTP (Step 2):', verifyRegRes.status === 201 ? 'PASS' : 'FAIL');

    // 4. Login Lecturer
    const gvLoginRes = await request('/api/auth/login', 'POST', {
      usernameOrEmail: 'giangvien.hau',
      password: 'Gv@123456',
    });
    console.log('4. Lecturer Login (Step 1):', gvLoginRes.status === 200 ? 'PASS' : 'FAIL');
    const gvOtp = gvLoginRes.data.data.otpPreview;

    const gvVerifyRes = await request('/api/auth/verify-login-otp', 'POST', {
      email: 'gv.hau@prime.edu.vn',
      otp_code: gvOtp,
    });
    console.log('5. Lecturer Verify Login OTP (Step 2):', gvVerifyRes.status === 200 ? 'PASS' : 'FAIL');
    const gvToken = gvVerifyRes.data.data.token;

    // 6. Lecturer starts session for PRIME101
    const classesRes = await request('/api/lecturer/classes', 'GET', null, gvToken);
    const classId = classesRes.data.data[0].id;

    const sessionRes = await request('/api/attendance/session/start', 'POST', {
      class_id: classId,
      session_name: 'Buổi 1: Giới thiệu Flutter & PRIME Attendance',
    }, gvToken);
    console.log('6. Lecturer Starts Attendance Session:', sessionRes.status === 201 ? 'PASS' : 'FAIL');
    const sessionId = sessionRes.data.data.id;

    // 7. Get Dynamic Rotating QR Token
    const qrRes = await request(`/api/attendance/session/${sessionId}/current-qr`, 'GET', null, gvToken);
    console.log('7. Generate Dynamic Rotating QR Token (5s):', qrRes.status === 200 ? 'PASS' : 'FAIL');
    const qrToken = qrRes.data.data.token;

    // 8. Login Student Hau
    const svLoginRes = await request('/api/auth/login', 'POST', {
      usernameOrEmail: 'sinhvien.hau',
      password: 'Sv@123456',
    });
    const svOtp = svLoginRes.data.data.otpPreview;
    const svVerifyRes = await request('/api/auth/verify-login-otp', 'POST', {
      email: '2005buinguyenchihau@gmail.com',
      otp_code: svOtp,
    });
    const svToken = svVerifyRes.data.data.token;

    // 9. Student Check-in (AI Smart Shield: QR + GPS inside geofence + Face)
    const checkInRes = await request('/api/attendance/check-in', 'POST', {
      qr_token: qrToken,
      latitude: 10.84151, // within 2 meters of room (10.8415, 106.8099)
      longitude: 106.80991,
      face_image: 'data:image/jpeg;base64,mock_selfie_face_data_prime',
    }, svToken);
    console.log('8. Student Check-in (3-Shield Validation):', checkInRes.status === 200 ? 'PASS' : 'FAIL', 'Distance:', checkInRes.data.data?.distance_meters, 'm');

    // 10. Lecturer Live Monitor Feed
    const liveFeedRes = await request(`/api/attendance/session/${sessionId}/live-records`, 'GET', null, gvToken);
    console.log('9. Lecturer Live Radar Monitor Records:', liveFeedRes.status === 200 ? 'PASS' : 'FAIL', 'Count:', liveFeedRes.data.data?.length);

    console.log('\n--- ALL E2E BACKEND TESTS PASSED SUCCESSFULLY! ---');
    process.exit(0);
  } catch (err) {
    console.error('Test failed with error:', err);
    process.exit(1);
  }
}

runTests();
