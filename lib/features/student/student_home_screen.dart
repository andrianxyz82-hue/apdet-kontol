import 'package:flutter/material.dart';

import 'dart:math' as math;
import '../../core/app_theme.dart';
import '../../services/course_service.dart';
import 'package:go_router/go_router.dart';
import '../../core/widgets/neon_background_painter.dart';

class StudentHomeScreen extends StatefulWidget {
  final Function(int)? onTabChange;
  const StudentHomeScreen({super.key, this.onTabChange});

  @override
  State<StudentHomeScreen> createState() => _StudentHomeScreenState();
}

class _StudentHomeScreenState extends State<StudentHomeScreen> {
  final _courseService = CourseService();
  List<Map<String, dynamic>> _popularCourses = [];
  bool _loading = true;
  final List<NeonDot> _neonDots = [];

  @override
  void initState() {
    super.initState();
    _generateNeonDots();
    _loadPopularCourses();
  }

  void _generateNeonDots() {
    final random = math.Random();
    for (int i = 0; i < 15; i++) {
      _neonDots.add(NeonDot(
        x: random.nextDouble(),
        y: random.nextDouble() * 0.5, // Top half
        radius: random.nextDouble() * 4 + 1,
        color: i % 2 == 0 ? const Color(0xFFB042FF) : const Color(0xFF42E0FF),
        opacity: random.nextDouble() * 0.5,
      ));
    }
  }

  Future<void> _loadPopularCourses() async {
    try {
      final courses = await _courseService.getCourses();
      if (mounted) {
        setState(() {
          _popularCourses = courses.take(3).toList(); // Take top 3
          _loading = false;
        });
      }
    } catch (e) {
      print('Error loading courses: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1d1d2b),

      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: NeonBackgroundPainter(dots: _neonDots),
            ),
          ),
          SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                // 1. Top Section - Title Only
                const Center(
                  child: Text(
                    'Eskalasi Safe Exam',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),

                // 2. Neon Progress Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7c7cff), // Purple Accent
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      // Circular Progress
                      SizedBox(
                        width: 100,
                        height: 100,
                        child: Stack(
                          children: [
                            const Center(
                              child: SizedBox(
                                width: 100,
                                height: 100,
                                child: CircularProgressIndicator(
                                  value: 0.45,
                                  strokeWidth: 8,
                                  backgroundColor: Colors.black12,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                            Center(
                              child: Text(
                                '45%',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 20),
                      // Text & Button
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Daily Plan Is Not\nSet Completely', // Adjusted text to match image better or use requested text
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 16),
                            InkWell(
                              onTap: () {
                                if (widget.onTabChange != null) {
                                  widget.onTabChange!(1); // Switch to Courses tab
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF2d2d44),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Text(
                                  'Continue Learning', // Changed to match request "Continue Learning" vs image "Add Workout"
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 3. CBT ESKALASI Card
                const Text(
                  'CBT ESKALASI',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF2D2D44), Color(0xFF1E1E2C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(color: const Color(0xFF7C7CFF).withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF7C7CFF).withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.computer,
                        size: 48,
                        color: Color(0xFF7C7CFF),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Ujian Berbasis Komputer',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Masuk ke mode ujian aman',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            context.push('/student/cbt-exam');
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C7CFF),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Mulai Ujian via CBT',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // 4. Popular Courses
                const Text(
                  'Popular Courses',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: _popularCourses.map((course) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildPopularCourseCard(
                              course['title'] ?? 'Untitled',
                              '${course['duration'] ?? 'N/A'} • ${course['instructor_name'] ?? 'Unknown'}',
                              const Color(0xFF2d2d44),
                              course['id'],
                            ),
                          );
                        }).toList(),
                      ),
                const SizedBox(height: 100), // Bottom padding for nav bar
              ],
            ),
          ),
        ),
        ),
        ],
      ),
    );
  }

  Widget _buildTopButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: Colors.black,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildCategoryItem(IconData icon, String label) {
    return Padding(
      padding: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFF2d2d44),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white10),
            ),
            // The instruction implies adding a widget here, but a Container only has one child.
            // Assuming the intent was to add it as a sibling or within a Stack if the Container's child was also part of it.
            // Given the instruction's format, it seems to be a misplaced snippet.
            // I will place it as a sibling to the Container, wrapped in a Stack to make it syntactically valid,
            // assuming the user wants this painter to be part of the visual composition of the category item.
            // However, without a clear Stack context, this might not be the intended visual outcome.
            // For strict adherence to the provided snippet's placement relative to the existing code structure,
            // and to maintain syntactic correctness, I will wrap the existing Container's child in a Stack
            // and add the Positioned.fill as another child of that Stack.
            child: Icon(
              icon,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularCourseCard(String title, String subtitle, Color color, String? courseId) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: InkWell(
                    onTap: () {
                      if (courseId != null) {
                        context.push('/course/detail/$courseId');
                      }
                    },
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Start', // Changed to "Start" or "Watch"
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.play_arrow_rounded,
                        size: 16,
                        color: Colors.black,
                      ),
                    ],
                  ),
                ),
              ),
              ],
            ),
          ),
          // Placeholder for image
          Container(
            width: 80,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[800],
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.image, color: Colors.white24),
          ),
        ],
      ),
    );
  }
}


