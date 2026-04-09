class Professor {
  final String facultyId;
  final String firstName;
  final String lastName;
  final String departmentId;
  final String department;
  final String email;
  final String expertise;
  final String isGuide;
  final String? image;
  final Map<String, dynamic> availability;

  Professor({
    required this.facultyId,
    required this.firstName,
    required this.lastName,
    required this.departmentId,
    required this.department,
    required this.email,
    required this.expertise,
    required this.isGuide,
    this.image,
    this.availability = const {},
  });

  factory Professor.fromJson(Map<String, dynamic> json) {
    // Image URL can be in either 'Image' or 'CT' field due to
    // inconsistent column alignment in the faculty data export.
    String? imageUrl = _extractImageUrl(json['Image']?.toString());
    imageUrl ??= _extractImageUrl(json['CT']?.toString());

    // Extract SVH (Student Visiting Hours) from misaligned columns
    String? svhStart;
    String? svhEnd;
    final timeRegex = RegExp(r'^\d{2}:\d{2}:\d{2}$');
    
    final t1 = json['svh_start_time']?.toString().trim();
    final t2 = json['svh_end_time']?.toString().trim();
    final t3 = json['Image']?.toString().trim();
    final t4 = json['CT']?.toString().trim();
    
    if (t1 != null && timeRegex.hasMatch(t1) && t2 != null && timeRegex.hasMatch(t2)) {
      svhStart = t1;
      svhEnd = t2;
    } else if (t2 != null && timeRegex.hasMatch(t2) && t3 != null && timeRegex.hasMatch(t3)) {
      svhStart = t2;
      svhEnd = t3;
    } else if (t3 != null && timeRegex.hasMatch(t3) && t4 != null && timeRegex.hasMatch(t4)) {
      svhStart = t3;
      svhEnd = t4;
    }

    // Format times like "09:00:00" to "09:00 AM" for better UI if needed,
    // but the status helper already works with 09:00:00 - 11:00:00.
    final availability = <String, dynamic>{};
    if (svhStart != null && svhEnd != null) {
      final hours = '$svhStart - $svhEnd';
      availability['Monday'] = hours;
      availability['Tuesday'] = hours;
      availability['Wednesday'] = hours;
      availability['Thursday'] = hours;
      availability['Friday'] = hours;
    }

    return Professor(
      facultyId: json['faculty_id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      departmentId: json['department_id']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      expertise: json['expertise']?.toString() ?? '',
      isGuide: json['is_guide']?.toString() ?? '',
      image: imageUrl,
      availability: availability,
    );
  }

  /// Returns the URL if it looks like a valid image URL, otherwise null.
  static String? _extractImageUrl(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) return null;
    // Check if it's an HTTP(S) URL pointing to an image
    final lower = value.toLowerCase();
    if (lower.startsWith('http') &&
        (lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.png') ||
            lower.endsWith('.gif') ||
            lower.endsWith('.webp'))) {
      return value;
    }
    return null;
  }

  Map<String, dynamic> toJson() {
    return {
      'faculty_id': facultyId,
      'first_name': firstName,
      'last_name': lastName,
      'department_id': departmentId,
      'department': department,
      'email': email,
      'expertise': expertise,
      'is_guide': isGuide,
      'Image': image,
      'availability': availability,
    };
  }

  String get fullName => '$firstName $lastName';

  String get cleanDepartment {
    return department.replaceAll('\\r\\n', ' ').trim();
  }

  String get cleanExpertise {
    return expertise.replaceAll('\\r\\n', ' ').trim();
  }

  String get cleanIsGuide {
    return isGuide.replaceAll('\\r\\n', ' ').trim();
  }
}
