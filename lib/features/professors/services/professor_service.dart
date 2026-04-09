import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/professor.dart';
import '../services/image_cache_manager.dart';
import '../../../core/utils/image_utils.dart';

class ProfessorsService extends ChangeNotifier {
  List<Professor> _professors = [];
  bool _isLoading = false;
  String? _error;

  List<Professor> get professors => _professors;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> loadProfessorsFromJson() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final String jsonString = await rootBundle.loadString(
        'assets/jsons/faculty.json',
      );
      final List<dynamic> jsonData = json.decode(jsonString);

      _professors = jsonData
          .map((json) => Professor.fromJson(json as Map<String, dynamic>))
          .toList();

      // Preload images in background
      _preloadProfessorImages();

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load professors: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  void _preloadProfessorImages() {
    // Extract all valid image URLs and preload them
    final imageUrls = _professors
        .map((professor) => professor.image)
        .where((url) => url != null && isValidImageUrl(url))
        .cast<String>()
        .toList();

    if (imageUrls.isNotEmpty) {
      CustomImageLoader.preloadImages(imageUrls);
    }
  }

  List<Professor> getProfessorsByDepartment(String departmentId) {
    return _professors
        .where((professor) => professor.departmentId == departmentId)
        .toList();
  }

  Professor? getProfessorById(String facultyId) {
    try {
      return _professors.firstWhere(
        (professor) => professor.facultyId == facultyId,
      );
    } catch (e) {
      return null;
    }
  }

  List<Professor> searchProfessors(String query) {
    if (query.isEmpty) return _professors;

    final lowerQuery = query.toLowerCase();
    return _professors
        .where(
          (professor) =>
              professor.fullName.toLowerCase().contains(lowerQuery) ||
              professor.email.toLowerCase().contains(lowerQuery) ||
              professor.cleanDepartment.toLowerCase().contains(lowerQuery) ||
              professor.cleanExpertise.toLowerCase().contains(lowerQuery),
        )
        .toList();
  }

  Stream<QuerySnapshot> getProfessorsStream() {
    return FirebaseFirestore.instance.collection('professors').snapshots();
  }

}
