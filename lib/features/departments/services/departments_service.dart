import 'dart:convert';
import 'package:flutter/services.dart';
import '../models/department.dart';
import '../models/course.dart';

class DepartmentsService {
  static List<Department> _departments = [];
  static List<Course> _courses = [];
  static bool _isLoaded = false;

  static Future<void> loadData() async {
    if (_isLoaded) return;

    try {
      // Load departments
      final departmentsJson = await rootBundle.loadString('assets/jsons/department.json');
      final departmentsList = json.decode(departmentsJson) as List;
      _departments = departmentsList
          .map((json) => Department.fromJson(json))
          .where((dept) => dept.departmentName.isNotEmpty)
          .toList();

      // Load courses
      final coursesJson = await rootBundle.loadString('assets/jsons/courses.json');
      final coursesList = json.decode(coursesJson) as List;
      _courses = coursesList
          .map((json) => Course.fromJson(json))
          .where((course) => course.hasValidData)
          .toList();

      _isLoaded = true;
    } catch (e) {
      print('Error loading department/course data: $e');
      _departments = [];
      _courses = [];
      _isLoaded = true;
    }
  }

  static List<Department> getDepartments() {
    return List.unmodifiable(_departments);
  }

  static List<Course> getAllCourses() {
    return List.unmodifiable(_courses);
  }

  static List<Course> getCoursesByDepartment(String departmentId) {
    return _courses
        .where((course) => course.departmentId == departmentId)
        .toList();
  }

  static Department? getDepartmentById(String departmentId) {
    try {
      return _departments.firstWhere((dept) => dept.departmentId == departmentId);
    } catch (e) {
      return null;
    }
  }

  static List<Course> searchCourses(String query) {
    if (query.isEmpty) return _courses;
    
    final lowerQuery = query.toLowerCase();
    return _courses.where((course) {
      return course.courseName.toLowerCase().contains(lowerQuery) ||
          course.courseCode.toLowerCase().contains(lowerQuery) ||
          (course.courseType?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  static List<Course> searchCoursesInDepartment(String departmentId, String query) {
    if (query.isEmpty) return getCoursesByDepartment(departmentId);
    
    final lowerQuery = query.toLowerCase();
    return getCoursesByDepartment(departmentId).where((course) {
      return course.courseName.toLowerCase().contains(lowerQuery) ||
          course.courseCode.toLowerCase().contains(lowerQuery) ||
          (course.courseType?.toLowerCase().contains(lowerQuery) ?? false);
    }).toList();
  }

  static List<Department> searchDepartments(String query) {
    if (query.isEmpty) return _departments;
    
    final lowerQuery = query.toLowerCase();
    return _departments.where((dept) {
      return dept.departmentName.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}
