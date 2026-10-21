const express = require('express');
const cors = require('cors');
const path = require('path');
const { initDatabase } = require('./config/database');

const authRoutes = require('./routes/authRoutes');
const apiRoutes = require('./routes/apiRoutes');

const app = express();
const PORT = process.env.PORT || 5000;

// Initialize database schema and seeds
initDatabase();

// Middlewares
app.use(cors());
// Hỗ trợ body json dung lượng lớn để gửi ảnh selfie / ảnh minh chứng đơn xin nghỉ
app.use(express.json({ limit: '15mb' }));
app.use(express.urlencoded({ extended: true, limit: '15mb' }));

// Logging middleware
app.use((req, res, next) => {
  console.log(`[${new Date().toLocaleTimeString()}] ${req.method} ${req.url}`);
  next();
});

// Root & Health check endpoints
app.get('/', (req, res) => {
  res.json({
    status: 'ONLINE',
    project: 'PRIME Student Attendance System',
    author: 'Bùi Nguyễn Chí Hậu',
    api_name: 'buinguyenchihau_api',
    database_name: 'buinguyenchihau_db',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
  });
});

app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    uptime: process.uptime(),
    database: 'buinguyenchihau_db.sqlite CONNECTED',
  });
});

// Routes
app.use('/api/auth', authRoutes);
app.use('/api', apiRoutes);

// Error handling middleware
app.use((err, req, res, next) => {
  console.error('[Error]', err);
  res.status(500).json({
    success: false,
    message: 'Lỗi máy chủ nội bộ',
    error: err.message,
  });
});

// Start listening
app.listen(PORT, '0.0.0.0', () => {
  console.log('================================================================');
  console.log(`🚀 [buinguyenchihau_api] Server is running on http://localhost:${PORT}`);
  console.log(`📂 [buinguyenchihau_db] Connected to SQLite database`);
  console.log(`🎓 Sinh viên: Bùi Nguyễn Chí Hậu - Nhóm PRIME`);
  console.log('================================================================');
});
