class Course {
  final String courseId;
  final String departmentId;
  final String courseCode;
  final String courseName;
  final String? semester;
  final String? courseType;
  final String? lectures;
  final String? tutorials;
  final String? practicals;
  final double? credits;

  Course({
    required this.courseId,
    required this.departmentId,
    required this.courseCode,
    required this.courseName,
    this.semester,
    this.courseType,
    this.lectures,
    this.tutorials,
    this.practicals,
    this.credits,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      courseId: json['course_id'].toString(),
      departmentId: json['department_id']?.toString() ?? '',
      courseCode: json['course_code'] ?? '',
      courseName: json['course_name'] ?? '',
      semester: json['semester']?.toString(),
      courseType: json['course_type'],
      lectures: json['lectures']?.toString(),
      tutorials: json['tutorials']?.toString(),
      practicals: json['practicals']?.toString(),
      credits: json['credits'] != null
          ? double.tryParse(json['credits'].toString())
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'course_id': courseId,
      'department_id': departmentId,
      'course_code': courseCode,
      'course_name': courseName,
      'semester': semester,
      'course_type': courseType,
      'lectures': lectures,
      'tutorials': tutorials,
      'practicals': practicals,
      'credits': credits,
    };
  }

  bool get hasValidData => courseName.isNotEmpty && courseCode.isNotEmpty;

  String get creditsDisplay => credits?.toString() ?? 'N/A';

  String get semesterDisplay => semester ?? 'N/A';

  String get courseTypeDisplay => courseType ?? 'N/A';

  @override
  String toString() {
    return '$courseCode - $courseName';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Course && other.courseId == courseId;
  }

  @override
  int get hashCode => courseId.hashCode;
}
