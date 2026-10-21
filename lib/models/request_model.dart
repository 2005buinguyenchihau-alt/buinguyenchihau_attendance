class AbsenceRequestModel {
  final int id;
  final int classId;
  final int studentId;
  final String reason;
  final String? proofImage;
  final String status; // 'pending', 'approved', 'rejected'
  final String createdAt;
  final String? classCode;
  final String? className;
  final String? studentName;
  final String? studentCode;
  final String? studentEmail;
  final String? lecturerName;

  AbsenceRequestModel({
    required this.id,
    required this.classId,
    required this.studentId,
    required this.reason,
    this.proofImage,
    required this.status,
    required this.createdAt,
    this.classCode,
    this.className,
    this.studentName,
    this.studentCode,
    this.studentEmail,
    this.lecturerName,
  });

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Chờ phê duyệt';
      case 'approved':
        return 'Đã chấp thuận';
      case 'rejected':
        return 'Từ chối';
      default:
        return status;
    }
  }

  factory AbsenceRequestModel.fromJson(Map<String, dynamic> json) {
    return AbsenceRequestModel(
      id: json['id'] is int ? json['id'] : int.parse(json['id'].toString()),
      classId: json['class_id'] is int ? json['class_id'] : int.parse((json['class_id'] ?? 0).toString()),
      studentId: json['student_id'] is int ? json['student_id'] : int.parse((json['student_id'] ?? 0).toString()),
      reason: json['reason'] ?? '',
      proofImage: json['proof_image'],
      status: json['status'] ?? 'pending',
      createdAt: json['created_at'] ?? '',
      classCode: json['class_code'],
      className: json['class_name'],
      studentName: json['student_name'],
      studentCode: json['student_code'],
      studentEmail: json['student_email'],
      lecturerName: json['lecturer_name'],
    );
  }
}
