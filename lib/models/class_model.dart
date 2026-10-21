class CourseClassModel {
  final int id;
  final String classCode;
  final String className;
  final int lecturerId;
  final String roomName;
  final double latitude;
  final double longitude;
  final double allowedRadius;
  final String semester;
  final String? lecturerName;
  final String? lecturerEmail;
  final int? studentCount;
  final int? totalSessions;
  final int? attendedSessions;

  CourseClassModel({
    required this.id,
    required this.classCode,
    required this.className,
    required this.lecturerId,
    required this.roomName,
    required this.latitude,
    required this.longitude,
    required this.allowedRadius,
    required this.semester,
    this.lecturerName,
    this.lecturerEmail,
    this.studentCount,
    this.totalSessions,
    this.attendedSessions,
  });

  double get attendanceRate {
    if (totalSessions == null || totalSessions == 0) return 100.0;
    return ((attendedSessions ?? 0) / totalSessions!) * 100.0;
  }

  factory CourseClassModel.fromJson(Map<String, dynamic> json) {
    return CourseClassModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      classCode: json['class_code'] ?? '',
      className: json['class_name'] ?? '',
      lecturerId: json['lecturer_id'] is int ? json['lecturer_id'] : int.parse((json['lecturer_id'] ?? 0).toString()),
      roomName: json['room_name'] ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 10.8415,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 106.8099,
      allowedRadius: (json['allowed_radius'] as num?)?.toDouble() ?? 50.0,
      semester: json['semester'] ?? '',
      lecturerName: json['lecturer_name'],
      lecturerEmail: json['lecturer_email'],
      studentCount: json['student_count'] as int?,
      totalSessions: json['total_sessions'] as int?,
      attendedSessions: json['attended_sessions'] as int?,
    );
  }
}
