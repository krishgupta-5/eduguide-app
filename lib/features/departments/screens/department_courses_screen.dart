import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import '../models/department.dart';
import '../models/course.dart';
import '../services/departments_service.dart';

// --- Constants (Synced with app theme) ---
const Color primaryBlue = Color(0xFF407BFF);
const Color lightBackground = Color(0xFFF7F7FD);
const Color cardBackground = Colors.white;
const Color textSubtle = Color(0xFF6E6E73);
const Color textBody = Color(0xFF1D1D1F);

class DepartmentCoursesScreen extends StatefulWidget {
  final Department department;

  const DepartmentCoursesScreen({super.key, required this.department});

  @override
  State<DepartmentCoursesScreen> createState() =>
      _DepartmentCoursesScreenState();
}

class _DepartmentCoursesScreenState extends State<DepartmentCoursesScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Course> _courses = [];
  List<Course> _filteredCourses = [];
  bool _isLoading = true;
  final Set<String> _expandedSemesters = <String>{}; // Track expanded semesters

  @override
  void initState() {
    super.initState();
    _loadCourses();
    _searchController.addListener(_filterCourses);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadCourses() {
    setState(() {
      _courses = DepartmentsService.getCoursesByDepartment(
        widget.department.departmentId,
      );
      _filteredCourses = _courses;
      _isLoading = false;
    });
  }

  void _filterCourses() {
    final query = _searchController.text;
    setState(() {
      _filteredCourses = DepartmentsService.searchCoursesInDepartment(
        widget.department.departmentId,
        query,
      );
    });
  }

  // Group courses by semester
  Map<String, List<Course>> _groupCoursesBySemester(List<Course> courses) {
    final Map<String, List<Course>> groupedCourses = {};

    for (final course in courses) {
      final semester = course.semesterDisplay;
      if (semester != 'N/A') {
        if (!groupedCourses.containsKey(semester)) {
          groupedCourses[semester] = [];
        }
        groupedCourses[semester]!.add(course);
      }
    }

    // Sort semesters in order (I, II, III, IV, V, VI, VII, VIII)
    final sortedKeys = groupedCourses.keys.toList()
      ..sort((a, b) => _getSemesterOrder(a).compareTo(_getSemesterOrder(b)));

    final Map<String, List<Course>> sortedGroupedCourses = {};
    for (final key in sortedKeys) {
      sortedGroupedCourses[key] = groupedCourses[key]!;
    }

    return sortedGroupedCourses;
  }

  int _getSemesterOrder(String semester) {
    switch (semester) {
      case 'I':
        return 1;
      case 'II':
        return 2;
      case 'III':
        return 3;
      case 'IV':
        return 4;
      case 'V':
        return 5;
      case 'VI':
        return 6;
      case 'VII':
        return 7;
      case 'VIII':
        return 8;
      default:
        return 999;
    }
  }

  // Toggle semester expansion
  void _toggleSemesterExpansion(String semester) {
    setState(() {
      if (_expandedSemesters.contains(semester)) {
        _expandedSemesters.remove(semester);
      } else {
        _expandedSemesters.add(semester);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lightBackground,
      appBar: AppBar(
        backgroundColor: primaryBlue,
        elevation: 0,
        centerTitle: true,
        title: Text(
          widget.department.departmentName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Search Bar
                Container(
                  margin: const EdgeInsets.all(16),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search courses...',
                      prefixIcon: const Icon(Icons.search, color: textSubtle),
                      filled: true,
                      fillColor: cardBackground,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),

                // Courses Count
                if (_filteredCourses.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${_filteredCourses.length} courses found',
                      style: const TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),

                const SizedBox(height: 8),

                // Courses List
                Expanded(
                  child: _filteredCourses.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _groupCoursesBySemester(
                            _filteredCourses,
                          ).length,
                          itemBuilder: (context, index) {
                            final groupedCourses = _groupCoursesBySemester(
                              _filteredCourses,
                            );
                            final semester = groupedCourses.keys.elementAt(
                              index,
                            );
                            final coursesInSemester = groupedCourses[semester]!;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Semester Header (Clickable)
                                GestureDetector(
                                  onTap: () =>
                                      _toggleSemesterExpansion(semester),
                                  child: Container(
                                    width: double.infinity,
                                    margin: const EdgeInsets.only(bottom: 16),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: _getSemesterColor(semester),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          FontAwesomeIcons.calendar,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(
                                            'Semester $semester',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.2,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                          ),
                                          child: Text(
                                            '${coursesInSemester.length} courses',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(
                                          _expandedSemesters.contains(semester)
                                              ? FontAwesomeIcons.chevronUp
                                              : FontAwesomeIcons.chevronDown,
                                          color: Colors.white,
                                          size: 20,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // Courses in this semester (only show if expanded)
                                if (_expandedSemesters.contains(semester))
                                  Column(
                                    children: [
                                      ...coursesInSemester.map(
                                        (course) => _courseCard(course),
                                      ),
                                      const SizedBox(height: 16),
                                    ],
                                  ),

                                // Add spacing between semesters
                                if (index < groupedCourses.length - 1)
                                  const SizedBox(height: 24),
                              ],
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _courseCard(Course course) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Code and Name
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.courseCode,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.courseName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: textBody,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _getCourseTypeColor(
                    course.courseType,
                  ).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  course.courseTypeDisplay,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _getCourseTypeColor(course.courseType),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Course Details
          Row(
            children: [
              _buildDetailItem(
                icon: FontAwesomeIcons.star,
                label: 'Credits',
                value: course.creditsDisplay,
              ),
              const SizedBox(width: 16),
              if (course.lectures != null ||
                  course.tutorials != null ||
                  course.practicals != null)
                Expanded(
                  child: Row(
                    children: [
                      if (course.lectures != null)
                        Expanded(
                          child: _buildScheduleItem(
                            icon: FontAwesomeUsers.userGraduate,
                            label: 'Lectures',
                            value: '${course.lectures}',
                          ),
                        ),
                      if (course.tutorials != null)
                        Expanded(
                          child: _buildScheduleItem(
                            icon: FontAwesomeIcons.chalkboardUser,
                            label: 'Tutorials',
                            value: '${course.tutorials}',
                          ),
                        ),
                      if (course.practicals != null)
                        Expanded(
                          child: _buildScheduleItem(
                            icon: FontAwesomeIcons.flask,
                            label: 'Practicals',
                            value: '${course.practicals}',
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 16, color: textSubtle),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: textSubtle),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textBody,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildScheduleItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Icon(icon, size: 16, color: textSubtle),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: textSubtle)),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: textBody,
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(FontAwesomeIcons.book, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchController.text.isEmpty
                ? 'No courses available'
                : 'No courses found',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _searchController.text.isEmpty
                ? 'Courses will appear here once available'
                : 'Try adjusting your search terms',
            style: TextStyle(color: Colors.grey[500], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Color _getSemesterColor(String? semester) {
    // Use consistent primary blue color for all semesters
    return primaryBlue;
  }

  Color _getCourseTypeColor(String? courseType) {
    switch (courseType) {
      case 'BSC':
        return Colors.purple;
      case 'ESC':
        return Colors.green;
      case 'PCC':
      case 'CP':
        return primaryBlue;
      case 'HSS':
        return Colors.orange;
      case 'PE':
        return Colors.teal;
      case 'GE':
        return Colors.red;
      case 'PR':
        return Colors.indigo;
      case 'CF':
        return Colors.amber;
      case 'OTH':
        return Colors.grey;
      default:
        return textSubtle;
    }
  }
}

// Extension for FontAwesome icons that might not be available
class FontAwesomeUsers {
  static const IconData userGraduate = FontAwesomeIcons.userGraduate;
}
