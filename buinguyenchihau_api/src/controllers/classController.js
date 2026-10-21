const { db } = require('../config/database');

/**
 * Lấy danh sách tất cả các lớp học phần (Có kèm tên Giảng viên và sĩ số)
 */
function getAllClasses(req, res) {
  try {
    const query = `
      SELECT 
        c.*, 
        u.full_name as lecturer_name,
        u.email as lecturer_email,
        (SELECT COUNT(*) FROM class_students cs WHERE cs.class_id = c.id) as student_count
      FROM classes c
      JOIN users u ON c.lecturer_id = u.id
      ORDER BY c.id DESC
    `;
    const classes = db.prepare(query).all();
    return res.status(200).json({ success: true, data: classes });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * Lấy chi tiết lớp học
 */
function getClassById(req, res) {
  try {
    const { id } = req.params;
    const courseClass = db.prepare(`
      SELECT c.*, u.full_name as lecturer_name 
      FROM classes c
      JOIN users u ON c.lecturer_id = u.id
      WHERE c.id = ?
    `).get(id);

    if (!courseClass) {
      return res.status(404).json({ success: false, message: 'Không tìm thấy lớp học phần.' });
    }

    // Danh sách sinh viên trong lớp
    const students = db.prepare(`
      SELECT u.id, u.full_name, u.code, u.email, u.avatar, cs.enrolled_at
      FROM class_students cs
      JOIN users u ON cs.student_id = u.id
      WHERE cs.class_id = ?
      ORDER BY u.code ASC
    `).all(id);

    // Danh sách các phiên điểm danh gần đây
    const sessions = db.prepare(`
      SELECT s.*, 
        (SELECT COUNT(*) FROM attendances a WHERE a.session_id = s.id) as attended_count
      FROM attendance_sessions s
      WHERE s.class_id = ?
      ORDER BY s.id DESC LIMIT 10
    `).all(id);

    return res.status(200).json({
      success: true,
      data: {
        ...courseClass,
        students,
        sessions,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * Tạo mới lớp học (Admin hoặc Giảng viên)
 */
function createClass(req, res) {
  try {
    const { class_code, class_name, lecturer_id, room_name, latitude, longitude, allowed_radius, semester } = req.body;

    if (!class_code || !class_name || !room_name) {
      return res.status(400).json({ success: false, message: 'Mã lớp, tên lớp và phòng học không được để trống.' });
    }

    const assignedLecturer = lecturer_id || req.user.id;

    const existing = db.prepare('SELECT id FROM classes WHERE class_code = ?').get(class_code);
    if (existing) {
      return res.status(400).json({ success: false, message: 'Mã lớp học phần này đã tồn tại.' });
    }

    const stmt = db.prepare(`
      INSERT INTO classes (class_code, class_name, lecturer_id, room_name, latitude, longitude, allowed_radius, semester)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?)
    `);

    const result = stmt.run(
      class_code,
      class_name,
      assignedLecturer,
      room_name,
      latitude || 10.8415,
      longitude || 106.8099,
      allowed_radius || 50.0,
      semester || 'Học kỳ 1 - 2026'
    );

    const created = db.prepare('SELECT * FROM classes WHERE id = ?').get(result.lastInsertRowid);
    return res.status(201).json({ success: true, message: 'Tạo lớp học phần thành công!', data: created });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * Cập nhật lớp học
 */
function updateClass(req, res) {
  try {
    const { id } = req.params;
    const { class_name, room_name, latitude, longitude, allowed_radius, semester } = req.body;

    const stmt = db.prepare(`
      UPDATE classes 
      SET class_name = COALESCE(?, class_name),
          room_name = COALESCE(?, room_name),
          latitude = COALESCE(?, latitude),
          longitude = COALESCE(?, longitude),
          allowed_radius = COALESCE(?, allowed_radius),
          semester = COALESCE(?, semester)
      WHERE id = ?
    `);

    stmt.run(class_name, room_name, latitude, longitude, allowed_radius, semester, id);
    const updated = db.prepare('SELECT * FROM classes WHERE id = ?').get(id);

    return res.status(200).json({ success: true, message: 'Cập nhật thông tin lớp thành công!', data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * Xóa lớp học
 */
function deleteClass(req, res) {
  try {
    const { id } = req.params;
    db.prepare('DELETE FROM classes WHERE id = ?').run(id);
    return res.status(200).json({ success: true, message: 'Đã xóa lớp học phần thành công!' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * Lấy danh sách lớp dành cho sinh viên hiện tại
 */
function getStudentClasses(req, res) {
  try {
    const studentId = req.user.id;
    const query = `
      SELECT 
        c.*, 
        u.full_name as lecturer_name,
        (SELECT COUNT(*) FROM attendance_sessions s WHERE s.class_id = c.id) as total_sessions,
        (SELECT COUNT(*) FROM attendances a 
         JOIN attendance_sessions s ON a.session_id = s.id 
         WHERE s.class_id = c.id AND a.student_id = ? AND a.status = 'present') as attended_sessions
      FROM class_students cs
      JOIN classes c ON cs.class_id = c.id
      JOIN users u ON c.lecturer_id = u.id
      WHERE cs.student_id = ?
      ORDER BY c.id DESC
    `;
    const classes = db.prepare(query).all(studentId, studentId);
    return res.status(200).json({ success: true, data: classes });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * Lấy danh sách lớp dành cho giảng viên hiện tại
 */
function getLecturerClasses(req, res) {
  try {
    const lecturerId = req.user.id;
    const query = `
      SELECT 
        c.*,
        (SELECT COUNT(*) FROM class_students cs WHERE cs.class_id = c.id) as student_count,
        (SELECT COUNT(*) FROM attendance_sessions s WHERE s.class_id = c.id) as session_count
      FROM classes c
      WHERE c.lecturer_id = ?
      ORDER BY c.id DESC
    `;
    const classes = db.prepare(query).all(lecturerId);
    return res.status(200).json({ success: true, data: classes });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * Thêm sinh viên vào lớp
 */
function enrollStudent(req, res) {
  try {
    const { class_id, student_id, student_code } = req.body;
    let targetStudentId = student_id;

    if (!targetStudentId && student_code) {
      const student = db.prepare('SELECT id FROM users WHERE code = ? AND role = "student"').get(student_code);
      if (!student) {
        return res.status(404).json({ success: false, message: `Không tìm thấy sinh viên có mã ${student_code}` });
      }
      targetStudentId = student.id;
    }

    if (!class_id || !targetStudentId) {
      return res.status(400).json({ success: false, message: 'Thiếu class_id hoặc thông tin sinh viên.' });
    }

    db.prepare('INSERT OR IGNORE INTO class_students (class_id, student_id) VALUES (?, ?)').run(class_id, targetStudentId);
    return res.status(200).json({ success: true, message: 'Đã thêm sinh viên vào danh sách lớp thành công!' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  getAllClasses,
  getClassById,
  createClass,
  updateClass,
  deleteClass,
  getStudentClasses,
  getLecturerClasses,
  enrollStudent,
};
