import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:eduguide/features/professors/screens/professors_profile.dart';
import 'package:eduguide/features/professors/services/professor_service.dart';
import 'package:eduguide/features/professors/models/professor.dart';
import 'package:eduguide/features/professors/widgets/fast_network_image.dart';
import 'package:eduguide/features/widgets/professor_status_helper.dart';
import 'package:eduguide/core/utils/image_utils.dart';
import 'package:flutter/material.dart';

// --- Constants ---
const Color primaryBlue = Color(0xFF407BFF);
const Color lightBackground = Color(0xFFF7F7FD);
const Color cardBackground = Colors.white;
const Color textSubtle = Color(0xFF6E6E73);
const Color textBody = Color(0xFF1D1D1F);

class SearchPage extends StatefulWidget {
  final ProfessorsService professorsService;

  const SearchPage({required this.professorsService, super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _searchController = TextEditingController();

  String _searchQuery = '';
  String _selectedSpecialization = 'All';
  String _selectedDay = 'All Days';

  final Set<String> _specializations = {'All'};
  final List<String> _days = [
    'All Days',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];

  /// ⭐ rating cache
  final Map<String, double> _ratingMap = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
    // Load professors data from JSON
    widget.professorsService.loadProfessorsFromJson();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        centerTitle: true,
        title: const Text(
          'Find a Professor',
          style: TextStyle(
            color: lightBackground,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          _buildControls(),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('rating_summary')
                  .snapshots(),
              builder: (context, ratingSnap) {
                _ratingMap.clear();
                if (ratingSnap.hasData) {
                  for (var doc in ratingSnap.data!.docs) {
                    _ratingMap[doc.id] = (doc['avgRating'] ?? 0).toDouble();
                  }
                }

                return AnimatedBuilder(
                  animation: widget.professorsService,
                  builder: (context, child) {
                    if (widget.professorsService.isLoading) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final professors = widget.professorsService.professors;

                    if (_specializations.length == 1) {
                      for (var professor in professors) {
                        final specs = professor.cleanExpertise.split(', ');
                        for (var s in specs) {
                          if (s.isNotEmpty) {
                            _specializations.add(s);
                          }
                        }
                      }
                    }

                    final filtered = professors.where((professor) {
                      final matchesSearch =
                          _searchQuery.isEmpty ||
                          professor.fullName.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          professor.email.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          professor.cleanDepartment.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          ) ||
                          professor.cleanExpertise.toLowerCase().contains(
                            _searchQuery.toLowerCase(),
                          );

                      final matchesSpec =
                          _selectedSpecialization == 'All' ||
                          professor.cleanExpertise.toLowerCase().contains(
                            _selectedSpecialization.toLowerCase(),
                          );

                      return matchesSearch && matchesSpec;
                    }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                        child: Text(
                          'No professors found',
                          style: TextStyle(fontSize: 16, color: textSubtle),
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final professor = filtered[index];
                        return _buildProfessorCardFromModel(context, professor);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: cardBackground,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search by name...',
              prefixIcon: Icon(Icons.search, color: textSubtle),
              filled: true,
              fillColor: lightBackground,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Filter buttons
          Row(
            children: [
              Expanded(
                child: _buildFilterButton(
                  label: _selectedSpecialization,
                  icon: Icons.subject,
                  onTap: () => _showSpecializationFilter(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildFilterButton(
                  label: _selectedDay,
                  icon: Icons.calendar_today,
                  onTap: () => _showDayFilter(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: lightBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: primaryBlue.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: primaryBlue, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: textBody, fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.keyboard_arrow_down, color: primaryBlue, size: 18),
          ],
        ),
      ),
    );
  }

  void _showSpecializationFilter() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        title: 'Filter by Specialization',
        options: _specializations.toList(),
        selected: _selectedSpecialization,
        onSelected: (value) {
          setState(() => _selectedSpecialization = value);
          Navigator.pop(context);
        },
      ),
    );
  }

  void _showDayFilter() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _buildFilterSheet(
        title: 'Filter by Day',
        options: _days,
        selected: _selectedDay,
        onSelected: (value) {
          setState(() {
            _selectedDay = value;
            print('Day filter changed to: $value'); // Debug log
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _buildFilterSheet({
    required String title,
    required List<String> options,
    required String selected,
    required Function(String) onSelected,
  }) {
    return Container(
      width: double.infinity,
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.7,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textBody,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: options.map((option) {
                  final isSelected = option == selected;
                  return GestureDetector(
                    onTap: () => onSelected(option),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? primaryBlue : lightBackground,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? primaryBlue
                              : primaryBlue.withOpacity(0.3),
                        ),
                      ),
                      child: Text(
                        option,
                        style: TextStyle(
                          color: isSelected ? Colors.white : textBody,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------
  // PROFESSOR CARD FROM MODEL
  Widget _buildProfessorCardFromModel(
    BuildContext context,
    Professor professor,
  ) {
    final rating = _ratingMap[professor.facultyId];

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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBackground,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(13),
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
                color: primaryBlue.withAlpha(26),
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
                          color: primaryBlue.withAlpha(26),
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
                  /// NAME + STATUS
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          professor.fullName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: textBody,
                          ),
                        ),
                      ),
                      _statusBadge({
                        'availability': professor.availability,
                        'is_guide': professor.cleanIsGuide,
                      }),
                    ],
                  ),
                  const SizedBox(height: 4),

                  /// DEPARTMENT
                  Text(
                    professor.cleanDepartment,
                    style: const TextStyle(fontSize: 14, color: textSubtle),
                  ),
                  const SizedBox(height: 4),

                  /// EXPERTISE
                  Text(
                    professor.cleanExpertise,
                    style: const TextStyle(fontSize: 13, color: textSubtle),
                  ),
                  const SizedBox(height: 8),

                  /// RATING
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        rating?.toStringAsFixed(1) ?? 'No rating',
                        style: const TextStyle(fontSize: 13, color: textSubtle),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------------
  // STATUS LOGIC
  Widget _statusBadge(Map<String, dynamic> data) {
    final rawAvailability = data['availability'];
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
            ? "BUSY • ${result.nextAvailableIn!.inMinutes} min"
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }


}
