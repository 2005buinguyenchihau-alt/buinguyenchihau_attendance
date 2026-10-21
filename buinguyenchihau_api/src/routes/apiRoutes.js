const express = require('express');
const router = express.Router();

const { authenticateToken, requireRole } = require('../middlewares/auth');
const classController = require('../controllers/classController');
const attendanceController = require('../controllers/attendanceController');
const requestController = require('../controllers/requestController');
const userController = require('../controllers/userController');

// Tất cả các route bên dưới đều cần xác thực JWT
router.use(authenticateToken);

// =================== 1. LỚP HỌC (CLASSES) ===================
router.get('/classes', classController.getAllClasses);
router.get('/classes/:id', classController.getClassById);
router.post('/classes', requireRole('admin', 'lecturer'), classController.createClass);
router.put('/classes/:id', requireRole('admin', 'lecturer'), classController.updateClass);
router.delete('/classes/:id', requireRole('admin'), classController.deleteClass);

// Lớp theo vai trò
router.get('/student/classes', requireRole('student'), classController.getStudentClasses);
router.get('/lecturer/classes', requireRole('lecturer'), classController.getLecturerClasses);
router.post('/classes/enroll', requireRole('admin', 'lecturer'), classController.enrollStudent);

// =================== 2. ĐIỂM DANH (ATTENDANCE) ===================
// Dành cho Giảng viên
router.post('/attendance/session/start', requireRole('lecturer', 'admin'), attendanceController.startSession);
router.get('/attendance/session/:id/current-qr', requireRole('lecturer', 'admin'), attendanceController.getCurrentQr);
router.post('/attendance/session/:id/close', requireRole('lecturer', 'admin'), attendanceController.closeSession);
router.get('/attendance/session/:id/live-records', requireRole('lecturer', 'admin'), attendanceController.getSessionLiveRecords);

// Dành cho Sinh viên
router.post('/attendance/check-in', requireRole('student'), attendanceController.checkIn);
router.get('/student/attendance-history', requireRole('student'), attendanceController.getStudentHistory);
router.get('/student/dashboard-stats', requireRole('student'), attendanceController.getStudentDashboardStats);

// =================== 3. ĐƠN XIN NGHỈ / BỔ SUNG (ABSENCE REQUESTS) ===================
router.post('/requests', requireRole('student'), requestController.submitRequest);
router.get('/student/requests', requireRole('student'), requestController.getStudentRequests);
router.get('/lecturer/requests', requireRole('lecturer', 'admin'), requestController.getLecturerRequests);
router.put('/requests/:id/review', requireRole('lecturer', 'admin'), requestController.reviewRequest);

// =================== 4. QUẢN TRỊ ADMIN (USERS & STATS) ===================
router.get('/admin/stats', requireRole('admin'), userController.getAdminStats);
router.get('/admin/users', requireRole('admin'), userController.getAllUsers);
router.post('/admin/users', requireRole('admin'), userController.createUser);
router.put('/admin/users/:id', requireRole('admin'), userController.updateUser);
router.delete('/admin/users/:id', requireRole('admin'), userController.deleteUser);

module.exports = router;
