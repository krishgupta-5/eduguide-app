class Department {
  final String departmentId;
  final String departmentName;

  Department({
    required this.departmentId,
    required this.departmentName,
  });

  factory Department.fromJson(Map<String, dynamic> json) {
    return Department(
      departmentId: json['department_id'].toString(),
      departmentName: json['department_name'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'department_id': departmentId,
      'department_name': departmentName,
    };
  }

  @override
  String toString() {
    return departmentName;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Department && other.departmentId == departmentId;
  }

  @override
  int get hashCode => departmentId.hashCode;
}
