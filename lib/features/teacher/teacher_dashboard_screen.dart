import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:go_router/go_router.dart';
import '../../core/app_theme.dart';
import '../../services/course_service.dart';
import '../../services/exam_service.dart';
import '../../core/widgets/neon_background_painter.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> {
  final _courseService = CourseService();
  final _examService = ExamService();
  
  int _totalCourses = 0;
  int _totalExams = 0;
  bool _loading = true;
  final List<NeonDot> _neonDots = [];

  @override
  void initState() {
    super.initState();
    _generateNeonDots();
    _loadStats();
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

  Future<void> _loadStats() async {
    try {
      final courses = await _courseService.getTeacherCourses();
      final exams = await _examService.getTeacherExams();
      
      setState(() {
        _totalCourses = courses.length;
        _totalExams = exams.length;
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
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
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Teacher Dashboard',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Manage your classes',
                            style: TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        onPressed: _loadStats,
                        icon: const Icon(Icons.refresh, color: Colors.white),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF2D2D44),
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Stats Cards
                  _loading
                      ? const Center(child: CircularProgressIndicator())
                      : Row(
                          children: [
                            Expanded(
                              child: _buildStatCard(
                                'Courses',
                                _totalCourses.toString(),
                                Icons.book_outlined,
                                const Color(0xFF7C7CFF),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _buildStatCard(
                                'Exams',
                                _totalExams.toString(),
                                Icons.quiz_outlined,
                                Colors.blue,
                              ),
                            ),
                          ],
                        ),
                  const SizedBox(height: 24),

                  // Quick Actions
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _buildActionButton(
                          'CBT Settings',
                          Icons.settings_ethernet,
                          const Color(0xFF7C7CFF),
                          () => context.push('/teacher/cbt-settings'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildActionButton(
                          'Create Exam',
                          Icons.add_circle_outline,
                          Colors.green,
                          () {
                            // Navigate to create exam or switch tab
                            // For now just a placeholder action or navigation
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Recent Activity
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildActivityItem(
                    'Mathematics Final Exam',
                    '45 students completed',
                    Icons.check_circle_outline,
                    Colors.green,
                  ),
                  _buildActivityItem(
                    'Physics Chapter 5 Material',
                    'Uploaded 2 hours ago',
                    Icons.upload_file,
                    AppTheme.primaryPurple,
                  ),
                  _buildActivityItem(
                    'English Literature Quiz',
                    'Scheduled for tomorrow',
                    Icons.schedule,
                    const Color(0xFFFFB84D),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D44),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
