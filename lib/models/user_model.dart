class UserModel {
  final int id;
  final String username;
  final String email;
  final String fullName;
  final String code;
  final String role; // 'admin', 'lecturer', 'student'
  final String? avatar;
  final String? faceData;
  final String? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.fullName,
    required this.code,
    required this.role,
    this.avatar,
    this.faceData,
    this.createdAt,
  });

  bool get isAdmin => role == 'admin';
  bool get isLecturer => role == 'lecturer';
  bool get isStudent => role == 'student';

  String get roleDisplayName {
    switch (role) {
      case 'admin':
        return 'Quản trị viên (Admin)';
      case 'lecturer':
        return 'Giảng viên';
      case 'student':
        return 'Sinh viên';
      default:
        return role;
    }
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: json['full_name'] ?? '',
      code: json['code'] ?? '',
      role: json['role'] ?? 'student',
      avatar: json['avatar'],
      faceData: json['face_data'],
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'full_name': fullName,
      'code': code,
      'role': role,
      'avatar': avatar,
      'face_data': faceData,
      'created_at': createdAt,
    };
  }
}
