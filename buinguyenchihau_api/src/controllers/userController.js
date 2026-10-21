const bcrypt = require('bcryptjs');
const { db } = require('../config/database');

/**
 * 1. Admin lấy danh sách người dùng (kèm phân trang/lọc theo vai trò)
 */
function getAllUsers(req, res) {
  try {
    const { role } = req.query;
    let query = 'SELECT id, username, email, full_name, code, role, avatar, created_at FROM users';
    const params = [];

    if (role) {
      query += ' WHERE role = ?';
      params.push(role);
    }
    query += ' ORDER BY id DESC';

    const users = db.prepare(query).all(...params);
    return res.status(200).json({ success: true, data: users });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 2. Admin tạo người dùng mới
 */
function createUser(req, res) {
  try {
    const { username, email, password, full_name, code, role } = req.body;

    if (!username || !email || !password || !full_name || !code || !role) {
      return res.status(400).json({ success: false, message: 'Vui lòng điền đầy đủ các thông tin.' });
    }

    const existing = db.prepare('SELECT id FROM users WHERE username = ? OR email = ?').get(username, email);
    if (existing) {
      return res.status(400).json({ success: false, message: 'Username hoặc email đã tồn tại.' });
    }

    const salt = bcrypt.genSaltSync(10);
    const password_hash = bcrypt.hashSync(password, salt);

    const result = db.prepare(`
      INSERT INTO users (username, email, password_hash, full_name, code, role)
      VALUES (?, ?, ?, ?, ?, ?)
    `).run(username, email, password_hash, full_name, code, role);

    const newUser = db.prepare('SELECT id, username, email, full_name, code, role, created_at FROM users WHERE id = ?').get(result.lastInsertRowid);
    return res.status(201).json({ success: true, message: 'Tạo tài khoản người dùng thành công!', data: newUser });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 3. Admin cập nhật thông tin người dùng
 */
function updateUser(req, res) {
  try {
    const { id } = req.params;
    const { full_name, code, role, password } = req.body;

    let password_hash = null;
    if (password) {
      const salt = bcrypt.genSaltSync(10);
      password_hash = bcrypt.hashSync(password, salt);
    }

    const stmt = db.prepare(`
      UPDATE users
      SET full_name = COALESCE(?, full_name),
          code = COALESCE(?, code),
          role = COALESCE(?, role),
          password_hash = COALESCE(?, password_hash)
      WHERE id = ?
    `);

    stmt.run(full_name, code, role, password_hash, id);
    const updated = db.prepare('SELECT id, username, email, full_name, code, role, created_at FROM users WHERE id = ?').get(id);

    return res.status(200).json({ success: true, message: 'Cập nhật tài khoản thành công!', data: updated });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 4. Admin xóa người dùng
 */
function deleteUser(req, res) {
  try {
    const { id } = req.params;
    if (parseInt(id, 10) === req.user.id) {
      return res.status(400).json({ success: false, message: 'Không thể xóa chính tài khoản Admin đang đăng nhập!' });
    }

    db.prepare('DELETE FROM users WHERE id = ?').run(id);
    return res.status(200).json({ success: true, message: 'Đã xóa người dùng thành công!' });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

/**
 * 5. Thống kê tổng quan cho Admin Dashboard
 */
function getAdminStats(req, res) {
  try {
    const totalUsers = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
    const totalLecturers = db.prepare("SELECT COUNT(*) as count FROM users WHERE role = 'lecturer'").get().count;
    const totalStudents = db.prepare("SELECT COUNT(*) as count FROM users WHERE role = 'student'").get().count;
    const totalClasses = db.prepare('SELECT COUNT(*) as count FROM classes').get().count;
    const totalSessions = db.prepare('SELECT COUNT(*) as count FROM attendance_sessions').get().count;
    const totalAttendances = db.prepare('SELECT COUNT(*) as count FROM attendances').get().count;

    return res.status(200).json({
      success: true,
      data: {
        totalUsers,
        totalLecturers,
        totalStudents,
        totalClasses,
        totalSessions,
        totalAttendances,
      },
    });
  } catch (error) {
    return res.status(500).json({ success: false, message: error.message });
  }
}

module.exports = {
  getAllUsers,
  createUser,
  updateUser,
  deleteUser,
  getAdminStats,
};
