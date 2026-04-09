import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduguide/features/professors/screens/professors_profile.dart';
import 'package:eduguide/features/professors/services/professor_service.dart';
import 'package:eduguide/features/professors/models/professor.dart';
import 'package:eduguide/core/utils/image_utils.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:eduguide/features/professors/widgets/fast_network_image.dart';

// --- Constants ---
Color primaryBlue = const Color(0xFF407BFF);
Color lightBackground = const Color(0xFFF7F7FD);
Color cardBackground = Colors.white;
Color textSubtle = const Color(0xFF6E6E73);
Color textBody = const Color(0xFF1D1D1F);

class HomePage extends StatefulWidget {
  final Function(int) onNavigate;
  const HomePage({super.key, required this.onNavigate});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ProfessorsService _professorsService = ProfessorsService();

  final Map<String, double> _ratingMap = {};

  @override
  void initState() {
    super.initState();
    _professorsService.loadProfessorsFromJson();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "EduGuide",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('rating_summary')
            .snapshots(),
        builder: (context, ratingSnap) {
          if (ratingSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (ratingSnap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading ratings',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your connection and try again',
                    style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  ),
                ],
              ),
            );
          }

          _ratingMap.clear();
          if (ratingSnap.hasData) {
            for (var doc in ratingSnap.data!.docs) {
              _ratingMap[doc.id] = (doc['avgRating'] ?? 0).toDouble();
            }
          }

          return AnimatedBuilder(
            animation: _professorsService,
            builder: (context, child) {
              if (_professorsService.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              if (_professorsService.error != null) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading professors',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please check your connection and try again',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              if (_professorsService.professors.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No professors available',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Professors will appear here once added',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final professors = _professorsService.professors;
              final Map<String, List<Professor>> categoryMap = {};

              for (var professor in professors) {
                if (!_ratingMap.containsKey(professor.facultyId)) continue;

                final category = professor.cleanExpertise;
                if (category.isEmpty) continue;

                categoryMap.putIfAbsent(category, () => []);
                categoryMap[category]!.add(professor);
              }

              final visibleCategories = categoryMap.entries.take(3);

              if (visibleCategories.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.star_outline,
                        size: 48,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No rated professors yet',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Professors with ratings will appear here',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          icon: FontAwesomeIcons.graduationCap,
                          label: "Teachers",
                          onTap: () => widget.onNavigate(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickAction(
                          icon: FontAwesomeIcons.magnifyingGlass,
                          label: "Search",
                          onTap: () => widget.onNavigate(2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  ...visibleCategories.map((entry) {
                    final profs = entry.value.take(3).toList();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle("Top Rated in ${entry.key}"),
                        ...profs.map(
                          (p) => _teacherCard(
                            context,
                            p,
                            _ratingMap[p.facultyId] ?? 0.0,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    );
                  }),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // --------------------------------------------------
  Widget _teacherCard(
    BuildContext context,
    Professor professor,
    double rating,
  ) {
    final name = professor.fullName;
    final specs = professor.cleanExpertise;
    final imageUrl = professor.image;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfessorDetailPage(
              data: {
                'id': professor.facultyId,
                'name': professor.fullName,
                'email': professor.email,
                'department': professor.cleanDepartment,
                'specializations': professor.cleanExpertise,
                'Image': professor.image,
                'is_guide': professor.cleanIsGuide,
                'rating': rating,
                'availability': professor.availability,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: imageUrl != null && isValidImageUrl(imageUrl)
                  ? FastNetworkImage(
                      imageUrl: imageUrl,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    )
                  : ClipOval(
                      child: Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.person, color: primaryBlue),
                      ),
                    ),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),

                  Text(
                    specs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textSubtle),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "⭐ ${rating.toStringAsFixed(1)}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  Widget _quickAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryBlue),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: textBody,
        ),
      ),
    );
  }
}
