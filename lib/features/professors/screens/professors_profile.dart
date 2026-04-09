import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:eduguide/features/rating_professors/rating_service.dart';
import 'package:eduguide/features/widgets/professor_status_helper.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:eduguide/features/professors/widgets/fast_network_image.dart';
import 'package:eduguide/core/utils/image_utils.dart';

// --- Constants ---
const Color primaryBlue = Color(0xFF407BFF);
const Color lightBackground = Color(0xFFF7F7FD);
const Color cardBackground = Colors.white;
const Color iconGray = Color(0xFF8A8A8E);
const Color textSubtle = Color(0xFF6E6E73);
const Color textBody = Color(0xFF1D1D1F);

class ProfessorDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;

  const ProfessorDetailPage({required this.data, super.key});

  @override
  State<ProfessorDetailPage> createState() => _ProfessorDetailPageState();
}

class _ProfessorDetailPageState extends State<ProfessorDetailPage> {
  int selectedDay = 0;
  int selectedRating = 0;
  final RatingService _ratingService = RatingService();
  late Future<bool> _hasRatedFuture;

  static const List<String> weekDays = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
  ];

  String get currentUserId => FirebaseAuth.instance.currentUser?.uid ?? '';

  @override
  void initState() {
    super.initState();
    _hasRatedFuture = _ratingService.hasUserRated(
      widget.data['id'],
      FirebaseAuth.instance.currentUser?.uid ?? '',
    );
  }

  // ---------------- URL LAUNCH ----------------
  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  }


  // ---------------- SUBMIT RATING ----------------
  Future<void> _submitRating(int rating) async {
    try {
      final professorId = widget.data['id'];
      final studentId = currentUserId;

      // Check if user already rated
      final hasRated = await _ratingService.hasUserRated(
        professorId,
        studentId,
      );
      if (hasRated) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("You have already rated this professor"),
          ),
        );
        return;
      }

      await _ratingService.submitRating(
        professorId: professorId,
        studentId: studentId,
        rating: rating,
      );

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Rating submitted")));

      setState(() => selectedRating = 0);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error submitting rating: $e")));
    }
  }

  // ---------------- BUILD ----------------
  @override
  Widget build(BuildContext context) {
    final rawAvailability = widget.data['availability'];
    final availabilityMap = rawAvailability is Map
        ? Map<String, dynamic>.from(rawAvailability)
        : <String, dynamic>{};

    final availableDays = weekDays
        .where((d) => availabilityMap.containsKey(d))
        .toList();

    if (selectedDay >= availableDays.length && availableDays.isNotEmpty) {
      selectedDay = 0;
    }

    // Build expertise/specialization list from available data
    final specializations = _parseStringToList(
      widget.data['specializations']?.toString(),
    );

    // Build qualifications from available data
    final qualifications = _parseStringToList(
      widget.data['qualifications']?.toString(),
    );

    // is_guide info
    final isGuide = widget.data['is_guide']?.toString() ?? '';
    final guideAreas = _parseStringToList(isGuide);

    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        title: Text(
          widget.data['name'] ?? 'Professor',
          style: const TextStyle(color: Colors.white),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildProfileHeader(),
          const SizedBox(height: 16),

          _buildRatingSection(),
          const SizedBox(height: 24),

          // Department
          if (widget.data['department'] != null &&
              widget.data['department'].toString().isNotEmpty)
            ...[
              _buildInfoCard(
                title: "Department",
                icon: Icons.apartment_rounded,
                children: [
                  _buildListItem(widget.data['department'].toString()),
                ],
              ),
              const SizedBox(height: 16),
            ],

          // Specializations / Research Areas
          if (specializations.isNotEmpty)
            ...[
              _buildInfoCard(
                title: "Specializations",
                icon: Icons.science_rounded,
                children: specializations.map((e) => _buildListItem(e)).toList(),
              ),
              const SizedBox(height: 16),
            ],

          // Guide Areas (from is_guide field)
          if (guideAreas.isNotEmpty &&
              isGuide != '0' &&
              isGuide != '1' &&
              isGuide.isNotEmpty)
            ...[
              _buildInfoCard(
                title: "Guide Areas",
                icon: Icons.school_rounded,
                children: guideAreas.map((e) => _buildListItem(e)).toList(),
              ),
              const SizedBox(height: 16),
            ],

          // Qualifications (from Firestore if available)
          if (qualifications.isNotEmpty)
            ...[
              _buildInfoCard(
                title: "Qualifications",
                icon: Icons.workspace_premium_rounded,
                children: qualifications.map((e) => _buildListItem(e)).toList(),
              ),
              const SizedBox(height: 16),
            ],

          // Research Papers (from Firestore if available)
          if (widget.data['research_papers'] != null)
            ...[
              _buildInfoCard(
                title: "Research Papers",
                icon: Icons.article_rounded,
                children: _parseResearchPapers(widget.data['research_papers']).map((
                  paper,
                ) {
                  final String title = paper['title'] ?? 'Untitled';
                  final String? link = paper['link'];
                  return _buildListItem(
                    title,
                    isLink: link != null,
                    onTap: link != null ? () => _launchURL(link) : null,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

          // Contact
          _buildInfoCard(
            title: "Contact",
            icon: Icons.contact_mail_rounded,
            children: [
              _contactRow(
                Icons.email_outlined,
                widget.data['email']?.toString() ??
                    widget.data['contact']?['email'] ??
                    'N/A',
              ),
              if (widget.data['contact']?['phone'] != null)
                _contactRow(
                  Icons.phone_outlined,
                  widget.data['contact']['phone'],
                ),
              if (widget.data['office'] != null)
                _contactRow(
                  Icons.location_on_outlined,
                  widget.data['office'],
                ),
            ],
          ),

          // Weekly Availability (only show if data exists)
          if (availableDays.isNotEmpty)
            ...[
              const SizedBox(height: 16),
              _buildInfoCard(
                title: "Weekly Availability",
                icon: Icons.calendar_today_rounded,
                children: [
                  // Day selector buttons - show only available days
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: availableDays.asMap().entries.map((entry) {
                        final index = entry.key;
                        final day = entry.value;
                        final isSelected = selectedDay == index;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () => setState(() => selectedDay = index),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected ? primaryBlue : lightBackground,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected
                                      ? primaryBlue
                                      : primaryBlue.withOpacity(0.3),
                                ),
                              ),
                              child: Text(
                                day,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : textBody,
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Selected day's availability
                  Builder(
                    builder: (context) {
                      final selectedDayName = availableDays[selectedDay];
                      final availability =
                          availabilityMap[selectedDayName] ?? 'Not Available';

                      return Text(
                        "$selectedDayName: $availability",
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: textBody,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
        ],
      ),
    );
  }

  // ---------------- STATUS BADGE (UPDATED) ----------------
  Widget _statusBadge() {
    final rawAvailability = widget.data['availability'];
    final availability = rawAvailability is Map
        ? Map<String, dynamic>.from(rawAvailability)
        : <String, dynamic>{};

    final result = ProfessorStatusHelper.calculate(availability);

    // Don't show any badge outside college hours (before 9AM or after 5PM)
    if (result.status == ProfessorStatus.outsideCollegeHours) {
      return const SizedBox.shrink();
    }

    Color color;
    String text;

    switch (result.status) {
      case ProfessorStatus.inCabin:
        color = Colors.green;
        text = "IN CABIN";
        break;
      case ProfessorStatus.busy:
        color = Colors.orange;
        text = result.nextAvailableIn != null
            ? "BUSY • Available in ${result.nextAvailableIn!.inMinutes} min"
            : "BUSY";
        break;
      default:
        color = Colors.red;
        text = "ABSENT";
    }

    return _badge(text, color);
  }

  Widget _badge(String text, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  // ---------------- RATING SECTION ----------------
  Widget _buildRatingSection() {
    final professorId = widget.data['id'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Rate this Professor",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textBody,
            ),
          ),
          const SizedBox(height: 12),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('rating_summary')
                .doc(professorId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData || !snapshot.data!.exists) {
                return const Text("No ratings yet");
              }

              final data = snapshot.data!.data() as Map<String, dynamic>;
              final avg = (data['avgRating'] ?? 0).toDouble();
              final count = data['ratingCount'] ?? 0;

              return Text(
                "⭐ ${avg.toStringAsFixed(1)} ($count reviews)",
                style: const TextStyle(fontSize: 16, color: textSubtle),
              );
            },
          ),

          const SizedBox(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              return IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                icon: Icon(
                  i < selectedRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 28,
                ),
                onPressed: () => setState(() => selectedRating = i + 1),
              );
            }),
          ),

          const SizedBox(height: 16),

          FutureBuilder<bool>(
            future: _hasRatedFuture,
            builder: (context, snapshot) {
              final hasRated = snapshot.data ?? false;

              return SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (selectedRating == 0 || hasRated)
                      ? null
                      : () => _submitRating(selectedRating),
                  child: Text(hasRated ? "Already Rated" : "Submit Rating"),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ---------------- PROFILE HEADER (UNCHANGED + BADGE) ----------------
  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primaryBlue.withOpacity(0.1),
            ),
            child: isValidImageUrl(widget.data['Image']?.toString())
                ? FastNetworkImage(
                    imageUrl: widget.data['Image']!,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    placeholder: Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: primaryBlue.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person,
                        color: primaryBlue,
                        size: 36,
                      ),
                    ),
                    errorWidget: const Icon(
                      Icons.person,
                      size: 36,
                      color: primaryBlue,
                    ),
                  )
                : const Icon(Icons.person, size: 36, color: primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data['name'] ?? '',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.data['specializations'] != null)
                  Text(
                    _parseStringToList(
                      widget.data['specializations']?.toString(),
                    ).join(', '),
                    style: const TextStyle(color: textSubtle),
                  ),

                // ✅ STATUS BADGE (TOP, NO SCROLL)
                _statusBadge(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------
  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    // Always show the card, even if children is empty
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBackground,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(),
          ...children,
        ],
      ),
    );
  }

  Widget _buildListItem(
    String text, {
    bool isLink = false,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: TextStyle(
            color: isLink ? primaryBlue : textSubtle,
            decoration: isLink ? TextDecoration.underline : null,
          ),
        ),
      ),
    );
  }

  Widget _contactRow(IconData icon, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: iconGray),
          const SizedBox(width: 12),
          Expanded(
            child: Text(value, style: const TextStyle(color: textSubtle)),
          ),
        ],
      ),
    );
  }

  /// Helper method to safely parse string to list
  List<String> _parseStringToList(String? data) {
    if (data == null || data.isEmpty) return [];

    // Try to split by common delimiters
    final delimiters = [',', ';', '\\n', '|'];
    for (final delimiter in delimiters) {
      if (data.contains(delimiter)) {
        return data
            .split(delimiter)
            .map((item) => item.trim())
            .where((item) => item.isNotEmpty)
            .toList();
      }
    }

    // If no delimiters found, return as single item
    return [data.trim()];
  }

  /// Helper method to safely parse research papers
  List<Map<String, dynamic>> _parseResearchPapers(dynamic data) {
    if (data == null) return [];

    if (data is List) {
      return data.map((item) => item as Map<String, dynamic>? ?? {}).toList();
    }

    if (data is String) {
      // If it's a string, try to parse as JSON or return empty
      try {
        final parsed = json.decode(data);
        if (parsed is List) {
          return parsed
              .map((item) => item as Map<String, dynamic>? ?? {})
              .toList();
        }
      } catch (e) {
        // If parsing fails, return empty list
      }
    }

    return [];
  }
}
