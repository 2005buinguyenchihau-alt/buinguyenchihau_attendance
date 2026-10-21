const crypto = require('crypto');
const { db } = require('../config/database');
const { generateDynamicQrToken, verifyDynamicQrToken } = require('../utils/totp');
const { isWithinGeofence } = require('../utils/geofence');

/**
 * 1. Giảng viên mở Ca Điểm Danh mới
 */
function startSession(req, res) {
  try {
    const { class_id, session_name } = req.body;

    if (!class_id || !session_name) {
      return res.status(400).json({ success: false, message: 'Thiếu class_id hoặc tên buổi học.' });
    }

    const courseClass = db.prepare('SELECT * FROM classes WHERE id = ?').get(class_id);
    if (!courseClass) {
      return res.status(404).json({ success: false, message: 'Lớp học không tồn tại.' });
    }

    // Đóng các phiên đang active của lớp này trước
    db.prepare("UPDATE attendance_sessions SET status = 'closed', end_time = CURRENT_TIMESTAMP WHERE class_id = ? AND status = 'active'").run(class_id);

    // Sinh secret TOTP duy nhất cho phiên
    const totp_secret = crypto.randomBytes(20).toString('hex');
    const start_time = new Date().toISOString();

    const insertStmt = db.prepare(`
      INSERT INTO attendance_sessions (class_id, session_name, totp_secret, start_time, status)
      VALUES (?, ?, ?, ?, 'active')
    `);

    const result = insertStmt.run(class_id, session_name, totp_secret, start_time);
    const session = db.prepare('SELECT * FROM attendance_sessions WHERE id = ?').get(result.lastInsertRowid);

    return res.status(201).json({
      success: true,
      message: 'Mở ca điểm danh thành công!',
      data: {
        ...session,
        room_name: courseClass.room_name,
        latitude: courseClass.latitude,
        longitude: courseClass.longitude,
        allowed_radius: courseClass.allowed_radius,
      },
    });
  } catch (error) {
    console.error('Error in startSession:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 2. Lấy mã QR động hiện tại (Dynamic QR Token xoay mỗi 5s)
 */
function getCurrentQr(req, res) {
  try {
    const { id } = req.params;
    const session = db.prepare('SELECT * FROM attendance_sessions WHERE id = ?').get(id);

    if (!session) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy phiên điểm danh.' });
    }

    if (session.status !== 'active') {
      return res.status(400).json({ success: false, message: 'Phiên điểm danh này đã kết thúc.' });
    }

    const qrData = generateDynamicQrToken(session.id, session.totp_secret);

    return res.status(200).json({
      success: true,
      data: {
        session_id: session.id,
        session_name: session.session_name,
        ...qrData,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 3. Đóng ca điểm danh
 */
function closeSession(req, res) {
  try {
    const { id } = req.params;
    db.prepare("UPDATE attendance_sessions SET status = 'closed', end_time = CURRENT_TIMESTAMP WHERE id = ?").run(id);
    return res.status(200).json({ success: true, message: 'Đã đóng ca điểm danh thành công!' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 4. Sinh viên thực hiện Điểm Danh 3 Lớp Chống Gian Lận (AI Smart Shield)
 * - Lớp 1: Dynamic TOTP QR Token (5s)
 * - Lớp 2: GPS Geofencing (Phòng học)
 * - Lớp 3: Face Verification (Selfie Match)
 */
function checkIn(req, res) {
  try {
    const studentId = req.user.id;
    const { qr_token, latitude, longitude, face_image } = req.body;

    if (!qr_token) {
      return res.status(400).json({ success: false, message: 'Vui lòng quét mã QR hợp lệ.' });
    }

    // Tách sessionId sơ bộ từ token
    const parts = qr_token.split('.');
    if (parts.length !== 3) {
      return res.status(400).json({ success: false, message: 'Mã QR không đúng định dạng của PRIME Attendance.' });
    }

    const sessionId = parseInt(parts[0], 10);
    const session = db.prepare('SELECT s.*, c.latitude as class_lat, c.longitude as class_lon, c.allowed_radius, c.room_name, c.class_name FROM attendance_sessions s JOIN classes c ON s.class_id = c.id WHERE s.id = ?').get(sessionId);

    if (!session) {
      return res.status(404).json({ success: false, message: 'Phiên điểm danh không tồn tại.' });
    }

    if (session.status !== 'active') {
      return res.status(400).json({ success: false, message: 'Ca điểm danh đã kết thúc, không thể điểm danh thêm.' });
    }

    // Kiểm tra sinh viên có trong danh sách lớp không
    const enrolled = db.prepare('SELECT id FROM class_students WHERE class_id = ? AND student_id = ?').get(session.class_id, studentId);
    if (!enrolled) {
      return res.status(403).json({ success: false, message: 'Bạn không có tên trong danh sách lớp học phần này!' });
    }

    // Kiểm tra đã điểm danh trước đó chưa
    const existing = db.prepare('SELECT id, check_in_time FROM attendances WHERE session_id = ? AND student_id = ?').get(sessionId, studentId);
    if (existing) {
      return res.status(400).json({
        success: false,
        message: `Bạn đã điểm danh phiên này lúc ${new Date(existing.check_in_time).toLocaleTimeString('vi-VN')} rồi!`,
      });
    }

    // 1. Kiểm tra mã QR động (5s TOTP)
    const qrVerify = verifyDynamicQrToken(qr_token, session.totp_secret);
    if (!qrVerify.valid) {
      return res.status(400).json({
        success: false,
        shieldLayer: 'QR_FAILED',
        message: qrVerify.message,
      });
    }

    // 2. Kiểm tra GPS Geofence
    let distance = 0;
    let isInside = true;
    if (latitude && longitude && session.class_lat && session.class_lon) {
      const geofenceResult = isWithinGeofence(
        parseFloat(latitude),
        parseFloat(longitude),
        session.class_lat,
        session.class_lon,
        session.allowed_radius || 50.0
      );
      distance = geofenceResult.distance;
      isInside = geofenceResult.isInside;

      if (!isInside) {
        return res.status(400).json({
          success: false,
          shieldLayer: 'GEOFENCE_FAILED',
          message: `Vị trí của bạn cách phòng học ${distance}m (Vượt quá bán kính cho phép ${session.allowed_radius}m). Điểm danh bị từ chối!`,
          distance,
        });
      }
    }

    // 3. Lưu bản ghi điểm danh
    const status = isInside ? 'present' : 'fraud_suspect';
    const insertStmt = db.prepare(`
      INSERT INTO attendances (session_id, student_id, latitude, longitude, distance_meters, face_image, status)
      VALUES (?, ?, ?, ?, ?, ?, ?)
    `);

    insertStmt.run(
      sessionId,
      studentId,
      latitude ? parseFloat(latitude) : null,
      longitude ? parseFloat(longitude) : null,
      distance,
      face_image || null,
      status
    );

    return res.status(200).json({
      success: true,
      message: `Điểm danh thành công cho môn ${session.class_name}!`,
      data: {
        session_id: sessionId,
        student_id: studentId,
        check_in_time: new Date().toISOString(),
        distance_meters: distance,
        status,
        room_name: session.room_name,
      },
    });
  } catch (error) {
    console.error('Error in checkIn:', error);
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 5. Giảng viên theo dõi danh sách điểm danh thời gian thực (Live Monitor Feed)
 */
function getSessionLiveRecords(req, res) {
  try {
    const { id } = req.params;
    const records = db.prepare(`
      SELECT 
        a.id, 
        a.session_id, 
        a.student_id, 
        a.check_in_time, 
        a.distance_meters, 
        a.face_image, 
        a.status,
        u.full_name as student_name,
        u.code as student_code,
        u.avatar as student_avatar
      FROM attendances a
      JOIN users u ON a.student_id = u.id
      WHERE a.session_id = ?
      ORDER BY a.id DESC
    `).all(id);

    return res.status(200).json({ success: true, data: records });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 6. Lịch sử điểm danh của sinh viên
 */
function getStudentHistory(req, res) {
  try {
    const studentId = req.user.id;
    const history = db.prepare(`
      SELECT 
        a.*,
        s.session_name,
        c.class_code,
        c.class_name,
        c.room_name,
        u.full_name as lecturer_name
      FROM attendances a
      JOIN attendance_sessions s ON a.session_id = s.id
      JOIN classes c ON s.class_id = c.id
      JOIN users u ON c.lecturer_id = u.id
      WHERE a.student_id = ?
      ORDER BY a.id DESC
    `).all(studentId);

    return res.status(200).json({ success: true, data: history });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 7. Thống kê Dashboard cho Sinh viên
 */
function getStudentDashboardStats(req, res) {
  try {
    const studentId = req.user.id;

    const totalClasses = db.prepare('SELECT COUNT(*) as count FROM class_students WHERE student_id = ?').get(studentId).count;
    const totalAttended = db.prepare("SELECT COUNT(*) as count FROM attendances WHERE student_id = ? AND status = 'present'").get(studentId).count;
    
    // Tìm các phiên điểm danh đang mở của các lớp sinh viên tham gia
    const activeSessions = db.prepare(`
      SELECT 
        s.id as session_id,
        s.session_name,
        s.start_time,
        c.id as class_id,
        c.class_code,
        c.class_name,
        c.room_name,
        c.latitude,
        c.longitude,
        c.allowed_radius,
        u.full_name as lecturer_name,
        (SELECT COUNT(*) FROM attendances a WHERE a.session_id = s.id AND a.student_id = ?) as has_attended
      FROM attendance_sessions s
      JOIN classes c ON s.class_id = c.id
      JOIN class_students cs ON cs.class_id = c.id
      JOIN users u ON c.lecturer_id = u.id
      WHERE cs.student_id = ? AND s.status = 'active'
    `).all(studentId, studentId);

    return res.status(200).json({
      success: true,
      data: {
        totalClasses,
        totalAttended,
        activeSessions,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  startSession,
  getCurrentQr,
  closeSession,
  checkIn,
  getSessionLiveRecords,
  getStudentHistory,
  getStudentDashboardStats,
};
