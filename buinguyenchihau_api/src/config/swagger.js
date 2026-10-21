/**
 * OpenAPI 3.0 Specification & Swagger UI Renderer
 * Tác giả: Bùi Nguyễn Chí Hậu - Hệ thống điểm danh sinh viên PRIME
 */

const openapiSpec = {
  openapi: '3.0.0',
  info: {
    title: 'PRIME Student Attendance System API',
    version: '1.0.0',
    description: `### Hệ thống Web API Điểm danh sinh viên thông minh
**Sinh viên thực hiện:** Bùi Nguyễn Chí Hậu  
**Dự án:** Ứng dụng Di động PRIME Flutter & Node.js Backend  
**Công nghệ:** Node.js (v22+), SQLite (WAL Mode), JWT Authentication, Dynamic QR (TOTP 5s), Face ID Biometrics.

---
### 🔑 Tài khoản mẫu để kiểm tra:
* **Admin (Quản trị viên):** \`admin\` / \`Admin@123\`
* **Giảng viên (Lecturer):** \`giangvien.hau\` / \`Gv@123456\`
* **Sinh viên (Student):** \`sinhvien.hau\` / \`Sv@123456\` (Email nhận OTP: \`2005buinguyenchihau@gmail.com\`)
`,
  },
  servers: [
    {
      url: '/',
      description: 'Máy chủ hiện tại (Current Host / Cloudflare / Vercel)',
    },
    {
      url: 'https://temporary-quick-indigo-83rinlq.vercel.app',
      description: 'Vercel Serverless Cloud',
    },
    {
      url: 'http://localhost:5000',
      description: 'Local Development Server',
    },
  ],
  components: {
    securitySchemes: {
      bearerAuth: {
        type: 'http',
        scheme: 'bearer',
        bearerFormat: 'JWT',
        description: 'Nhập JWT Token nhận được từ bước verify-login-otp hoặc đăng ký thành công.',
      },
    },
  },
  tags: [
    { name: 'System', description: 'Thông tin hệ thống & Kiểm tra sức khỏe' },
    { name: 'Auth & Face ID', description: 'Đăng ký, Đăng nhập 2 bước OTP và Nhận diện khuôn mặt' },
    { name: 'Attendance', description: 'Mở ca, Dynamic QR 5s, Check-in 3 lớp và Radar giám sát trực tiếp' },
    { name: 'Classes', description: 'Quản lý lớp học & danh sách sinh viên' },
    { name: 'Requests', description: 'Đơn xin phép nghỉ học và phê duyệt' },
    { name: 'Admin', description: 'Thống kê tổng quan & Quản lý người dùng' },
  ],
  paths: {
    '/': {
      get: {
        tags: ['System'],
        summary: 'Thông tin hệ thống PRIME API',
        responses: {
          200: { description: 'Hệ thống đang trực tuyến' },
        },
      },
    },
    '/api/health': {
      get: {
        tags: ['System'],
        summary: 'Kiểm tra trạng thái máy chủ & kết nối SQLite database',
        responses: {
          200: { description: 'Database connected OK' },
        },
      },
    },
    '/api/auth/login': {
      post: {
        tags: ['Auth & Face ID'],
        summary: '1. Đăng nhập bước 1: Kiểm tra mật khẩu & gửi mã OTP 2FA',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  usernameOrEmail: { type: 'string', example: 'sinhvien.hau' },
                  password: { type: 'string', example: 'Sv@123456' },
                },
                required: ['usernameOrEmail', 'password'],
              },
            },
          },
        },
        responses: {
          200: { description: 'Mật khẩu đúng, OTP đã được gửi đến email người dùng' },
          401: { description: 'Mật khẩu sai hoặc tài khoản không tồn tại' },
        },
      },
    },
    '/api/auth/verify-login-otp': {
      post: {
        tags: ['Auth & Face ID'],
        summary: '2. Đăng nhập bước 2: Xác thực mã OTP 2FA & nhận Token JWT',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  email: { type: 'string', example: '2005buinguyenchihau@gmail.com' },
                  otp_code: { type: 'string', example: '123456' },
                },
                required: ['email', 'otp_code'],
              },
            },
          },
        },
        responses: {
          200: { description: 'Cấp Access Token JWT thành công' },
        },
      },
    },
    '/api/auth/face-login': {
      post: {
        tags: ['Auth & Face ID'],
        summary: '3. Đăng nhập 1-chạm bằng Face ID Biometrics (Chức năng 5.a)',
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  face_data: { type: 'string', example: 'mock_face_embedding_sinhvien_hau' },
                  username: { type: 'string', example: 'sinhvien.hau' },
                },
                required: ['face_data'],
              },
            },
          },
        },
        responses: {
          200: { description: 'Đăng nhập sinh trắc học thành công' },
          401: { description: 'Khuôn mặt người lạ / không khớp' },
        },
      },
    },
    '/api/auth/profile': {
      get: {
        tags: ['Auth & Face ID'],
        summary: 'Lấy thông tin tài khoản hiện tại',
        security: [{ bearerAuth: [] }],
        responses: {
          200: { description: 'Thông tin tài khoản' },
        },
      },
    },
    '/api/attendance/session/start': {
      post: {
        tags: ['Attendance'],
        summary: 'Giảng viên mở ca điểm danh lớp học (Chức năng 2)',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  class_id: { type: 'integer', example: 1 },
                  session_name: { type: 'string', example: 'Buổi 1: Kiến trúc Flutter & API' },
                  latitude: { type: 'number', example: 10.8415 },
                  longitude: { type: 'number', example: 106.8099 },
                  allowed_radius: { type: 'number', example: 50 },
                  duration_minutes: { type: 'integer', example: 45 },
                },
                required: ['class_id'],
              },
            },
          },
        },
        responses: {
          200: { description: 'Ca điểm danh đã mở' },
        },
      },
    },
    '/api/attendance/session/{id}/current-qr': {
      get: {
        tags: ['Attendance'],
        summary: 'Sinh mã Dynamic QR xoay vòng mỗi 5 giây (Chức năng 3)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'integer' }, example: 1 },
        ],
        responses: {
          200: { description: 'Token QR động kèm thời gian hết hạn' },
        },
      },
    },
    '/api/attendance/check-in': {
      post: {
        tags: ['Attendance'],
        summary: 'Sinh viên quét QR & Điểm danh 3 lớp bảo vệ (Chức năng 4)',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  session_id: { type: 'integer', example: 1 },
                  qr_token: { type: 'string', example: 'dynamic_qr_token_here' },
                  latitude: { type: 'number', example: 10.8415 },
                  longitude: { type: 'number', example: 106.8099 },
                  face_verified: { type: 'boolean', example: true },
                },
                required: ['session_id', 'qr_token', 'latitude', 'longitude'],
              },
            },
          },
        },
        responses: {
          200: { description: 'Điểm danh hợp lệ thành công' },
          400: { description: 'Mã QR hết hạn hoặc ngoài bán kính phòng học' },
        },
      },
    },
    '/api/attendance/session/{id}/live-records': {
      get: {
        tags: ['Attendance'],
        summary: 'Radar trực tiếp: Giám sát sinh viên vừa điểm danh (Chức năng 6)',
        security: [{ bearerAuth: [] }],
        parameters: [
          { name: 'id', in: 'path', required: true, schema: { type: 'integer' }, example: 1 },
        ],
        responses: {
          200: { description: 'Danh sách sinh viên có mặt thời gian thực' },
        },
      },
    },
    '/api/classes': {
      get: {
        tags: ['Classes'],
        summary: 'Lấy toàn bộ danh sách lớp học',
        security: [{ bearerAuth: [] }],
        responses: {
          200: { description: 'Danh sách lớp' },
        },
      },
    },
    '/api/requests': {
      get: {
        tags: ['Requests'],
        summary: 'Xem danh sách đơn xin phép nghỉ học',
        security: [{ bearerAuth: [] }],
        responses: {
          200: { description: 'Danh sách đơn' },
        },
      },
      post: {
        tags: ['Requests'],
        summary: 'Sinh viên nộp đơn xin nghỉ có đính kèm ảnh minh chứng',
        security: [{ bearerAuth: [] }],
        requestBody: {
          required: true,
          content: {
            'application/json': {
              schema: {
                type: 'object',
                properties: {
                  class_id: { type: 'integer', example: 1 },
                  reason: { type: 'string', example: 'Em bị sốt xuất huyết xin phép nghỉ buổi học hôm nay.' },
                  evidence_photo: { type: 'string', example: 'data:image/jpeg;base64,...' },
                },
                required: ['class_id', 'reason'],
              },
            },
          },
        },
        responses: {
          200: { description: 'Nộp đơn thành công' },
        },
      },
    },
    '/api/admin/stats': {
      get: {
        tags: ['Admin'],
        summary: 'Thống kê tổng quan hệ thống dành cho Quản trị viên',
        security: [{ bearerAuth: [] }],
        responses: {
          200: { description: 'Dữ liệu thống kê tổng thể' },
        },
      },
    },
  },
};

/**
 * Trả về trang HTML Swagger UI hoàn chỉnh sử dụng CDN chính thức
 */
function renderSwaggerHtml() {
  return `<!DOCTYPE html>
<html lang="vi">
<head>
  <meta charset="UTF-8">
  <title>Swagger UI - PRIME Attendance API | Bùi Nguyễn Chí Hậu</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <link rel="stylesheet" href="https://unpkg.com/swagger-ui-dist@5.18.2/swagger-ui.css" />
  <link rel="icon" type="image/png" href="https://unpkg.com/swagger-ui-dist@5.18.2/favicon-32x32.png" />
  <style>
    body {
      margin: 0;
      background: #0f172a;
      font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
    }
    .custom-topbar {
      background: linear-gradient(135deg, #1e293b 0%, #0f172a 100%);
      border-bottom: 2px solid #3b82f6;
      padding: 16px 24px;
      color: #ffffff;
      display: flex;
      flex-wrap: wrap;
      justify-content: space-between;
      align-items: center;
      gap: 12px;
    }
    .custom-title {
      font-size: 20px;
      font-weight: 700;
      color: #60a5fa;
      display: flex;
      align-items: center;
      gap: 8px;
    }
    .author-badge {
      background: #2563eb;
      color: #fff;
      padding: 4px 12px;
      border-radius: 9999px;
      font-size: 13px;
      font-weight: 600;
    }
    .quick-creds {
      background: rgba(255, 255, 255, 0.05);
      border: 1px solid rgba(255, 255, 255, 0.1);
      padding: 8px 14px;
      border-radius: 8px;
      font-size: 13px;
      color: #cbd5e1;
    }
    .quick-creds code {
      color: #38bdf8;
      background: #1e293b;
      padding: 2px 6px;
      border-radius: 4px;
      font-weight: bold;
    }
    /* Tối ưu nền Swagger */
    #swagger-ui {
      max-width: 1300px;
      margin: 0 auto;
      padding: 20px;
      background: #ffffff;
      border-radius: 12px;
      box-shadow: 0 10px 25px rgba(0,0,0,0.3);
      margin-top: 20px;
      margin-bottom: 40px;
    }
  </style>
</head>
<body>
  <div class="custom-topbar">
    <div class="custom-title">
      <span>🚀 PRIME Student Attendance System</span>
      <span class="author-badge">SV: Bùi Nguyễn Chí Hậu</span>
    </div>
    <div class="quick-creds">
      👤 <b>Admin:</b> <code>admin</code> / <code>Admin@123</code> &nbsp;|&nbsp;
      🎓 <b>GV:</b> <code>giangvien.hau</code> / <code>Gv@123456</code> &nbsp;|&nbsp;
      📱 <b>SV:</b> <code>sinhvien.hau</code> / <code>Sv@123456</code>
    </div>
  </div>

  <div id="swagger-ui"></div>

  <script src="https://unpkg.com/swagger-ui-dist@5.18.2/swagger-ui-bundle.js"></script>
  <script src="https://unpkg.com/swagger-ui-dist@5.18.2/swagger-ui-standalone-preset.js"></script>
  <script>
    window.onload = function() {
      window.ui = SwaggerUIBundle({
        spec: ${JSON.stringify(openapiSpec)},
        dom_id: '#swagger-ui',
        deepLinking: true,
        presets: [
          SwaggerUIBundle.presets.apis,
          SwaggerUIStandalonePreset
        ],
        layout: "BaseLayout",
        defaultModelsExpandDepth: -1,
        docExpansion: "list"
      });
    };
  </script>
</body>
</html>`;
}

module.exports = {
  openapiSpec,
  renderSwaggerHtml,
};
