import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import '../../core/app_theme.dart';
import '../../services/exam_service.dart';
import '../../services/lock_service.dart';
import 'exam_results_screen.dart';

class TakeExamScreen extends StatefulWidget {
  final String examId;
  const TakeExamScreen({super.key, required this.examId});

  @override
  State<TakeExamScreen> createState() => _TakeExamScreenState();
}

class _TakeExamScreenState extends State<TakeExamScreen> with WidgetsBindingObserver {
  final _examService = ExamService();
  final _lockService = LockService();
  
  Map<String, dynamic>? _exam;
  List<Map<String, dynamic>> _questions = [];
  Map<String, dynamic> _answers = {};
  
  int _currentQuestionIndex = 0;
  bool _loading = true;
  bool _submitting = false;
  
  Timer? _timer;
  Timer? _lockCheckTimer;
  StreamSubscription? _overlaySubscription;
  int _remainingSeconds = 0;
  bool _isLocked = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _enableLockMode();
    _startLockCheck();
    _setupOverlayListener();
    _loadExam();
  }

  void _setupOverlayListener() {
    _overlaySubscription = _lockService.onOverlayDetected.listen((_) {
      if (mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF2D2D44),
            title: const Text('Security Alert', style: TextStyle(color: Colors.red)),
            content: const Text(
              'Floating app or smart panel detected! Please close all overlays and floating apps immediately to continue the exam.',
              style: TextStyle(color: Colors.white),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('I have closed it'),
              ),
            ],
          ),
        );
      }
    });
  }

  void _startLockCheck() {
    _lockCheckTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
      final isLocked = await _lockService.isLockModeActive();
      if (mounted && isLocked != _isLocked) {
        setState(() => _isLocked = isLocked);
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disableLockMode();
    _timer?.cancel();
    _lockCheckTimer?.cancel();
    _overlaySubscription?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Re-enforce lock mode if app comes to foreground
      _enableLockMode();
    }
  }

  Future<void> _enableLockMode() async {
    await _lockService.startLockTask();
    await _lockService.disableGestureNavigation();
    await _lockService.setSecureFlag();
  }

  Future<void> _disableLockMode() async {
    await _lockService.stopLockTask();
    await _lockService.enableGestureNavigation();
    await _lockService.clearSecureFlag();
  }

  Future<void> _loadExam() async {
    try {
      print('Loading exam detail for: ${widget.examId}');
      final exam = await _examService.getExamById(widget.examId);
      final questions = await _examService.getExamQuestions(widget.examId);
      
      print('Exam loaded: ${exam != null}');
      print('Questions loaded: ${questions.length}');

      setState(() {
        _exam = exam;
        _questions = questions;
        _remainingSeconds = ((exam?['duration_minutes'] as int?) ?? 60) * 60;
        _loading = false;
      });
      
      _startTimer();
    } catch (e) {
      print('Error in _loadExam: $e');
      setState(() => _loading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds > 0) {
        setState(() => _remainingSeconds--);
      } else {
        _timer?.cancel();
        _submitExam();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _saveAnswer(String questionId, dynamic answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  Future<void> _submitExam() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF2D2D44),
        title: const Text('Submit Exam?', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to submit? You cannot change your answers after submission.',
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF7C7CFF)),
            child: const Text('Submit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _submitting = true);

    try {
      print('Submitting exam: ${widget.examId} with ${_answers.length} answers');
      final String? submissionId = await _examService.submitExam(widget.examId, _answers);
      print('Submission result ID: $submissionId');
      
      if (submissionId != null && mounted) {
        print('Navigating to results screen...');
        _timer?.cancel();
        
        // Disable lock mode before navigating away
        await _disableLockMode();
        
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultsScreen(
              examId: widget.examId,
              submissionId: submissionId,
            ),
          ),
        );
      } else {
        print('Submission failed: ID is null');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Submission failed. Please try again.'), backgroundColor: Colors.red),
          );
        }
      }
    } catch (e) {
      print('Error in _submitExam: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (!_isLocked) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_person, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'Exam Locked',
                  style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const Text(
                  'You must enable "Screen Pinning" to take this exam. Please accept the permission request.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: _enableLockMode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C7CFF),
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  ),
                  child: const Text('Enable Lock Mode'),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Exit Exam', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : AppTheme.textDark),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('No questions available'),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final questionId = currentQuestion['id'];
    final questionType = currentQuestion['question_type'];

    return WillPopScope(
      onWillPop: () async {
        // Prevent back button
        return false;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          automaticallyImplyLeading: false, // Hide default back button
          backgroundColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
          elevation: 0,
          title: Text(
            _exam?['title'] ?? 'Exam',
            style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
          ),
          actions: [
            // Submit Button (Replaces Cakra/Exit)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
              child: ElevatedButton(
                onPressed: (_answers.length == _questions.length && !_submitting)
                    ? () => _submitExam()
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: (_answers.length == _questions.length)
                      ? const Color(0xFF7C7CFF)
                      : Colors.grey.withOpacity(0.3),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.withOpacity(0.3),
                  disabledForegroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Submit'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(right: 16, left: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _remainingSeconds < 300 ? Colors.red.withOpacity(0.2) : const Color(0xFF7C7CFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: _remainingSeconds < 300 ? Colors.red : const Color(0xFF7C7CFF),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_remainingSeconds),
                    style: TextStyle(
                      color: _remainingSeconds < 300 ? Colors.red : const Color(0xFF7C7CFF),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Progress Bar
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey[300],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF7C7CFF)),
            ),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Question Number
                    Text(
                      'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Question Text
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF2D2D44) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Text(
                        currentQuestion['question_text'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppTheme.textDark,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Answer Options
                    if (questionType == 'multiple_choice')
                      _buildMultipleChoiceOptions(questionId, currentQuestion, isDark)
                    else
                      _buildEssayInput(questionId, isDark),
                  ],
                ),
              ),
            ),
            
            // Navigation Buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2D2D44) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  if (_currentQuestionIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() => _currentQuestionIndex--);
                        },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF7C7CFF),
                          side: const BorderSide(color: Color(0xFF7C7CFF)),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                  if (_currentQuestionIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _submitting
                          ? null
                          : () {
                              if (_currentQuestionIndex < _questions.length - 1) {
                                setState(() => _currentQuestionIndex++);
                              } else {
                                _submitExam();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF7C7CFF),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _currentQuestionIndex < _questions.length - 1 ? 'Next' : 'Submit',
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMultipleChoiceOptions(String questionId, Map<String, dynamic> question, bool isDark) {
    final optionsJson = question['options'];
    List<String> options = [];
    
    if (optionsJson != null) {
      if (optionsJson is String) {
        try {
          final decoded = jsonDecode(optionsJson);
          options = List<String>.from(decoded);
        } catch (e) {
          options = [];
        }
      } else if (optionsJson is List) {
        options = List<String>.from(optionsJson);
      }
    }

    final currentAnswer = _answers[questionId];

    return Column(
      children: options.map((option) {
        final isSelected = currentAnswer == option;
        return GestureDetector(
          onTap: () => _saveAnswer(questionId, option),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF7C7CFF).withOpacity(0.2)
                  : (isDark ? const Color(0xFF2D2D44) : Colors.white),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? const Color(0xFF7C7CFF) : Colors.grey.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? const Color(0xFF7C7CFF) : Colors.grey,
                      width: 2,
                    ),
                    color: isSelected ? const Color(0xFF7C7CFF) : Colors.transparent,
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    option,
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark ? Colors.white : AppTheme.textDark,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEssayInput(String questionId, bool isDark) {
    final controller = TextEditingController(text: _answers[questionId] ?? '');
    
    // Use a unique key to prevent controller recreation issues if widget rebuilds
    // But for now, simple controller creation in build is okay if state is managed elsewhere
    // Ideally we should manage controllers in state, but for this quick fix:
    controller.selection = TextSelection.fromPosition(TextPosition(offset: controller.text.length));

    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : AppTheme.textDark),
      maxLines: 10,
      decoration: InputDecoration(
        hintText: 'Type your answer here...',
        hintStyle: const TextStyle(color: Colors.grey),
        filled: true,
        fillColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
      onChanged: (value) => _saveAnswer(questionId, value),
    );
  }
}
