const { DatabaseSync } = require('node:sqlite');
const path = require('path');
const fs = require('fs');
const bcrypt = require('bcryptjs');

const dbPath = path.join(__dirname, '..', '..', 'buinguyenchihau_db.sqlite');
const db = new DatabaseSync(dbPath);

// Enable WAL mode for high concurrency
db.exec('PRAGMA journal_mode = WAL;');
db.exec('PRAGMA foreign_keys = ON;');

function initDatabase() {
  console.log(`[buinguyenchihau_db] Initializing database at ${dbPath}...`);

  // 1. Users table
  db.exec(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      email TEXT UNIQUE NOT NULL,
      password_hash TEXT NOT NULL,
      full_name TEXT NOT NULL,
      code TEXT NOT NULL,
      role TEXT NOT NULL CHECK(role IN ('admin', 'lecturer', 'student')),
      avatar TEXT,
      face_data TEXT,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // 2. OTP Codes table (hỗ trợ register, login, reset_password)
  try {
    const tableInfo = db.prepare("SELECT sql FROM sqlite_master WHERE type='table' AND name='otp_codes'").get();
    if (tableInfo && !tableInfo.sql.includes('reset_password')) {
      db.exec("DROP TABLE IF EXISTS otp_codes");
    }
  } catch (e) {}

  db.exec(`
    CREATE TABLE IF NOT EXISTS otp_codes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT NOT NULL,
      otp_code TEXT NOT NULL,
      type TEXT NOT NULL CHECK(type IN ('register', 'login', 'reset_password')),
      expires_at TEXT NOT NULL,
      is_used INTEGER DEFAULT 0,
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // 3. Classes table
  db.exec(`
    CREATE TABLE IF NOT EXISTS classes (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      class_code TEXT UNIQUE NOT NULL,
      class_name TEXT NOT NULL,
      lecturer_id INTEGER NOT NULL REFERENCES users(id),
      room_name TEXT NOT NULL,
      latitude REAL NOT NULL,
      longitude REAL NOT NULL,
      allowed_radius REAL DEFAULT 50.0,
      semester TEXT DEFAULT 'Học kỳ 1 - 2026',
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // 4. Class Students junction table
  db.exec(`
    CREATE TABLE IF NOT EXISTS class_students (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
      student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      enrolled_at TEXT DEFAULT CURRENT_TIMESTAMP,
      UNIQUE(class_id, student_id)
    );
  `);

  // 5. Attendance Sessions table
  db.exec(`
    CREATE TABLE IF NOT EXISTS attendance_sessions (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
      session_name TEXT NOT NULL,
      totp_secret TEXT NOT NULL,
      start_time TEXT NOT NULL,
      end_time TEXT,
      status TEXT DEFAULT 'active' CHECK(status IN ('active', 'closed')),
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
  `);

  // 6. Attendances table
  db.exec(`
    CREATE TABLE IF NOT EXISTS attendances (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      session_id INTEGER NOT NULL REFERENCES attendance_sessions(id) ON DELETE CASCADE,
      student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      check_in_time TEXT DEFAULT CURRENT_TIMESTAMP,
      latitude REAL,
      longitude REAL,
      distance_meters REAL,
      face_image TEXT,
      face_match_confidence REAL DEFAULT 1.0,
      status TEXT DEFAULT 'present' CHECK(status IN ('present', 'late', 'fraud_suspect', 'absent')),
      UNIQUE(session_id, student_id)
    );
  `);

  // 7. Absence Requests table
  db.exec(`
    CREATE TABLE IF NOT EXISTS absence_requests (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      class_id INTEGER NOT NULL REFERENCES classes(id) ON DELETE CASCADE,
      student_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
      reason TEXT NOT NULL,
      proof_image TEXT,
      status TEXT DEFAULT 'pending' CHECK(status IN ('pending', 'approved', 'rejected')),
      reviewed_by INTEGER REFERENCES users(id),
      created_at TEXT DEFAULT CURRENT_TIMESTAMP
    );
  `);

  seedInitialData();
  console.log('[buinguyenchihau_db] Database schema and initial seed ready.');
}

function seedInitialData() {
  const userCount = db.prepare('SELECT COUNT(*) as count FROM users').get().count;
  if (userCount > 0) return;

  console.log('[buinguyenchihau_db] Seeding initial users and classes...');

  const salt = bcrypt.genSaltSync(10);
  const adminPass = bcrypt.hashSync('Admin@123', salt);
  const gvPass = bcrypt.hashSync('Gv@123456', salt);
  const svPass = bcrypt.hashSync('Sv@123456', salt);

  const insertUser = db.prepare(`
    INSERT INTO users (username, email, password_hash, full_name, code, role)
    VALUES (?, ?, ?, ?, ?, ?)
  `);

  insertUser.run('admin', 'admin@prime.edu.vn', adminPass, 'Bùi Nguyễn Chí Hậu (Admin)', 'ADMIN01', 'admin');
  insertUser.run('giangvien.hau', 'gv.hau@prime.edu.vn', gvPass, 'ThS. Bùi Nguyễn Chí Hậu', 'GV200501', 'lecturer');
  insertUser.run('sinhvien.hau', '2005buinguyenchihau@gmail.com', svPass, 'Bùi Nguyễn Chí Hậu (SV)', '2005BUI01', 'student');
  insertUser.run('sinhvien.nghia', 'nghia@prime.edu.vn', svPass, 'Trần Minh Nghĩa', '2005BUI02', 'student');
  insertUser.run('sinhvien.vy', 'vy@prime.edu.vn', svPass, 'Nguyễn Tường Vy', '2005BUI03', 'student');

  const gv = db.prepare("SELECT id FROM users WHERE role = 'lecturer'").get();
  const svHau = db.prepare("SELECT id FROM users WHERE username = 'sinhvien.hau'").get();
  const svNghia = db.prepare("SELECT id FROM users WHERE username = 'sinhvien.nghia'").get();
  const svVy = db.prepare("SELECT id FROM users WHERE username = 'sinhvien.vy'").get();

  // Create sample classes
  const insertClass = db.prepare(`
    INSERT INTO classes (class_code, class_name, lecturer_id, room_name, latitude, longitude, allowed_radius)
    VALUES (?, ?, ?, ?, ?, ?, ?)
  `);

  insertClass.run('PRIME101', 'Lập trình Thiết bị Di động (Flutter)', gv.id, 'Phòng Lab A302', 10.8415, 106.8099, 50.0);
  insertClass.run('PRIME102', 'Trí Tuệ Nhân Tạo & Thị Giác Máy Tính', gv.id, 'Phòng Lý Thuyết B204', 10.8415, 106.8099, 50.0);

  const class1 = db.prepare("SELECT id FROM classes WHERE class_code = 'PRIME101'").get();
  const class2 = db.prepare("SELECT id FROM classes WHERE class_code = 'PRIME102'").get();

  // Enroll students in class
  const insertEnrollment = db.prepare(`
    INSERT OR IGNORE INTO class_students (class_id, student_id)
    VALUES (?, ?)
  `);

  insertEnrollment.run(class1.id, svHau.id);
  insertEnrollment.run(class1.id, svNghia.id);
  insertEnrollment.run(class1.id, svVy.id);

  insertEnrollment.run(class2.id, svHau.id);
  insertEnrollment.run(class2.id, svNghia.id);

  console.log('[buinguyenchihau_db] Seed data created successfully.');
}

module.exports = {
  db,
  initDatabase,
};
