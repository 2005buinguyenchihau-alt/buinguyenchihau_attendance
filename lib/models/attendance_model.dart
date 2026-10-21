class AttendanceRecordModel {
  final int id;
  final int sessionId;
  final int studentId;
  final String checkInTime;
  final double? distanceMeters;
  final String? faceImage;
  final double? faceMatchConfidence;
  final String status; // 'present', 'late', 'fraud_suspect', 'absent'
  final String? studentName;
  final String? studentCode;
  final String? studentAvatar;
  final String? sessionName;
  final String? classCode;
  final String? className;
  final String? roomName;
  final String? lecturerName;

  AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.checkInTime,
    this.distanceMeters,
    this.faceImage,
    this.faceMatchConfidence,
    required this.status,
    this.studentName,
    this.studentCode,
    this.studentAvatar,
    this.sessionName,
    this.classCode,
    this.className,
    this.roomName,
    this.lecturerName,
  });

  String get statusDisplay {
    switch (status) {
      case 'present':
        return 'Có mặt';
      case 'late':
        return 'Đi muộn';
      case 'fraud_suspect':
        return 'Nghi vấn gian lận';
      case 'absent':
        return 'Vắng mặt';
      default:
        return status;
    }
  }

  factory AttendanceRecordModel.fromJson(Map<String, dynamic> json) {
    return AttendanceRecordModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      sessionId: json['session_id'] is int ? json['session_id'] : int.parse((json['session_id'] ?? 0).toString()),
      studentId: json['student_id'] is int ? json['student_id'] : int.parse((json['student_id'] ?? 0).toString()),
      checkInTime: json['check_in_time'] ?? '',
      distanceMeters: (json['distance_meters'] as num?)?.toDouble(),
      faceImage: json['face_image'],
      faceMatchConfidence: (json['face_match_confidence'] as num?)?.toDouble(),
      status: json['status'] ?? 'present',
      studentName: json['student_name'],
      studentCode: json['student_code'],
      studentAvatar: json['student_avatar'],
      sessionName: json['session_name'],
      classCode: json['class_code'],
      className: json['class_name'],
      roomName: json['room_name'],
      lecturerName: json['lecturer_name'],
    );
  }
}

class AttendanceSessionModel {
  final int id;
  final int classId;
  final String sessionName;
  final String startTime;
  final String? endTime;
  final String status; // 'active', 'closed'
  final String? roomName;
  final double? latitude;
  final double? longitude;
  final double? allowedRadius;
  final int? attendedCount;

  AttendanceSessionModel({
    required this.id,
    required this.classId,
    required this.sessionName,
    required this.startTime,
    this.endTime,
    required this.status,
    this.roomName,
    this.latitude,
    this.longitude,
    this.allowedRadius,
    this.attendedCount,
  });

  bool get isActive => status == 'active';

  factory AttendanceSessionModel.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      classId: json['class_id'] is int ? json['class_id'] : int.parse((json['class_id'] ?? 0).toString()),
      sessionName: json['session_name'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'],
      status: json['status'] ?? 'active',
      roomName: json['room_name'],
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      allowedRadius: (json['allowed_radius'] as num?)?.toDouble(),
      attendedCount: json['attended_count'] as int?,
    );
  }
}
