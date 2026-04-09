import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduguide/features/professors/screens/professors_profile.dart';
import 'package:eduguide/features/professors/services/professor_service.dart';
import 'package:eduguide/features/professors/models/professor.dart';
import 'package:eduguide/features/professors/widgets/fast_network_image.dart';
import 'package:eduguide/core/utils/image_utils.dart';
import 'package:flutter/material.dart';

// --- Constants ---
const Color primaryBlue = Color(0xFF407BFF);
const Color lightBackground = Color(0xFFF7F7FD);
const Color cardBackground = Colors.white;
const Color textSubtle = Color(0xFF6E6E73);
const Color textBody = Color(0xFF1D1D1F);

class ProfessorsListPage extends StatefulWidget {
  const ProfessorsListPage({super.key});

  @override
  State<ProfessorsListPage> createState() => _ProfessorsListPageState();
}

class _ProfessorsListPageState extends State<ProfessorsListPage> {
  late ProfessorsService _professorsService;

  @override
  void initState() {
    super.initState();
    _professorsService = ProfessorsService();
    _professorsService.loadProfessorsFromJson();
  }

  @override
  void dispose() {
    _professorsService.dispose();
    super.dispose();
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
          'All Professors',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          /// ⚡ QUICK STATS STRIP
          _quickStatsStrip(),

          /// PROFESSORS LIST
          Expanded(
            child: AnimatedBuilder(
              animation: _professorsService,
              builder: (context, child) {
                if (_professorsService.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  );
                }
                if (_professorsService.error != null) {
                  return Center(
                    child: Text(
                      "Error: ${_professorsService.error}",
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                if (_professorsService.professors.isEmpty) {
                  return const Center(child: Text("No professors found."));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _professorsService.professors.length,
                  itemBuilder: (context, idx) {
                    final professor = _professorsService.professors[idx];
                    return _buildProfessorCard(context, professor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // ⚡ QUICK STATS STRIP
  Widget _quickStatsStrip() {
    return AnimatedBuilder(
      animation: _professorsService,
      builder: (context, child) {
        final professors = _professorsService.professors;
        final totalTeachers = professors.length;
        final Set<String> departments = {};

        for (var professor in professors) {
          departments.add(professor.cleanDepartment);
        }

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: cardBackground,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem("👨‍🏫 Teachers", totalTeachers.toString()),
              _statItem("📚 Departments", departments.length.toString()),
              _statItem("⭐ Avg Rating", "4.2"),
            ],
          ),
        );
      },
    );
  }

  Widget _statItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textBody,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: textSubtle,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // PROFESSOR CARD
  Widget _buildProfessorCard(BuildContext context, Professor professor) {
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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryBlue.withOpacity(0.1),
              ),
              child: isValidImageUrl(professor.image)
                  ? FastNetworkImage(
                      imageUrl: professor.image!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      placeholder: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: primaryBlue.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person,
                          color: primaryBlue,
                          size: 30,
                        ),
                      ),
                      errorWidget: const Icon(
                        Icons.person,
                        color: primaryBlue,
                        size: 30,
                      ),
                    )
                  : const Icon(Icons.person, color: primaryBlue, size: 30),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// NAME
                  Text(
                    professor.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                      color: textBody,
                    ),
                  ),

                  const SizedBox(height: 4),

                  /// DEPARTMENT
                  Text(
                    professor.cleanDepartment,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),

                  const SizedBox(height: 2),

                  /// EXPERTISE
                  if (professor.cleanExpertise.isNotEmpty)
                    Text(
                      professor.cleanExpertise,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: textSubtle),
                    ),

                  const SizedBox(height: 6),
                  _ratingWidget(professor.facultyId),
                ],
              ),
            ),

            const Icon(
              Icons.arrow_forward_ios_rounded,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // ⭐ RATING WIDGET
  Widget _ratingWidget(String professorId) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('rating_summary')
          .doc(professorId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Text(
            "⭐ New",
            style: TextStyle(color: textSubtle, fontWeight: FontWeight.w600),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final avg = (data['avgRating'] ?? 0).toDouble();
        final count = data['ratingCount'] ?? 0;

        return Text(
          "⭐ ${avg.toStringAsFixed(1)} ($count)",
          style: const TextStyle(color: textBody, fontWeight: FontWeight.w600),
        );
      },
    );
  }
}
