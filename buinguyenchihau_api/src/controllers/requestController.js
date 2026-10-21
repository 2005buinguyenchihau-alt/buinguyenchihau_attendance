const { db } = require('../config/database');

/**
 * 1. Sinh viên gửi đơn xin phép vắng / điểm danh bổ sung
 */
function submitRequest(req, res) {
  try {
    const studentId = req.user.id;
    const { class_id, reason, proof_image } = req.body;

    if (!class_id || !reason) {
      return res.status(400).json({ success: false, message: 'Vui lòng chọn lớp học và nhập lý do xin phép.' });
    }

    const stmt = db.prepare(`
      INSERT INTO absence_requests (class_id, student_id, reason, proof_image, status)
      VALUES (?, ?, ?, ?, 'pending')
    `);

    const result = stmt.run(class_id, studentId, reason, proof_image || null);
    const created = db.prepare('SELECT * FROM absence_requests WHERE id = ?').get(result.lastInsertRowid);

    return res.status(201).json({
      success: true,
      message: 'Nộp đơn xin phép thành công! Vui lòng chờ Giảng viên phê duyệt.',
      data: created,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 2. Giảng viên xem danh sách đơn xin phép của các lớp mình dạy
 */
function getLecturerRequests(req, res) {
  try {
    const lecturerId = req.user.id;
    const requests = db.prepare(`
      SELECT 
        ar.*,
        c.class_code,
        c.class_name,
        u.full_name as student_name,
        u.code as student_code,
        u.email as student_email
      FROM absence_requests ar
      JOIN classes c ON ar.class_id = c.id
      JOIN users u ON ar.student_id = u.id
      WHERE c.lecturer_id = ?
      ORDER BY ar.id DESC
    `).all(lecturerId);

    return res.status(200).json({ success: true, data: requests });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 3. Sinh viên xem danh sách các đơn đã gửi của mình
 */
function getStudentRequests(req, res) {
  try {
    const studentId = req.user.id;
    const requests = db.prepare(`
      SELECT 
        ar.*,
        c.class_code,
        c.class_name,
        u.full_name as lecturer_name
      FROM absence_requests ar
      JOIN classes c ON ar.class_id = c.id
      JOIN users u ON c.lecturer_id = u.id
      WHERE ar.student_id = ?
      ORDER BY ar.id DESC
    `).all(studentId);

    return res.status(200).json({ success: true, data: requests });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 4. Giảng viên phê duyệt hoặc từ chối đơn
 */
function reviewRequest(req, res) {
  try {
    const reviewerId = req.user.id;
    const { id } = req.params;
    const { status } = req.body; // 'approved' | 'rejected'

    if (!['approved', 'rejected'].includes(status)) {
      return res.status(400).json({ success: false, message: "Trạng thái phê duyệt phải là 'approved' hoặc 'rejected'." });
    }

    db.prepare('UPDATE absence_requests SET status = ?, reviewed_by = ? WHERE id = ?').run(status, reviewerId, id);
    const updated = db.prepare('SELECT * FROM absence_requests WHERE id = ?').get(id);

    return res.status(200).json({
      success: true,
      message: status === 'approved' ? 'Đã duyệt đơn xin phép!' : 'Đã từ chối đơn xin phép.',
      data: updated,
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  submitRequest,
  getLecturerRequests,
  getStudentRequests,
  reviewRequest,
};
