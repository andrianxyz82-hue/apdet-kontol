import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../services/cbt_service.dart';
import '../../services/lock_service.dart';
import 'dart:async';

class CbtExamScreen extends StatefulWidget {
  const CbtExamScreen({super.key});

  @override
  State<CbtExamScreen> createState() => _CbtExamScreenState();
}

class _CbtExamScreenState extends State<CbtExamScreen> with WidgetsBindingObserver {
  late final WebViewController _controller;
  final _cbtService = CbtService();
  final _lockService = LockService();
  bool _isLoading = true;
  bool _isLockActive = false;
  StreamSubscription? _overlaySubscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeExam();
  }

  Future<void> _initializeExam() async {
    // 1. Check Security First
    final isSafe = await _checkSecurity();
    if (!isSafe) {
      if (mounted) context.pop();
      return;
    }

    // 2. Enable Lock Mode
    await _enableLockMode();

    // 3. Load URL
    final url = await _cbtService.getCbtUrl();
    
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {},
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {},
        ),
      )
      ..loadRequest(Uri.parse(url));

    // 4. Listen for Overlays
    _overlaySubscription = _lockService.onOverlayDetected.listen((_) {
      _showSecurityAlert();
    });
  }

  Future<bool> _checkSecurity() async {
    final hasFocus = await _lockService.hasWindowFocus();
    if (!hasFocus) {
      if (mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Text('Security Check Failed'),
            content: const Text('Please close all floating apps and overlays before starting.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return false;
    }
    return true;
  }

  Future<void> _enableLockMode() async {
    await _lockService.startLockTask();
    await _lockService.setSecureFlag();
    await _lockService.disableGestureNavigation();
    setState(() => _isLockActive = true);
  }

  Future<void> _disableLockMode() async {
    await _lockService.stopLockTask();
    await _lockService.clearSecureFlag();
    await _lockService.enableGestureNavigation();
    setState(() => _isLockActive = false);
  }

  void _showSecurityAlert() {
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.red,
          title: const Text('Security Alert', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Overlay detected! Please close it immediately.',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _handleExit() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finish Exam?'),
        content: const Text('Are you sure you want to finish and exit?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Finish & Exit'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _disableLockMode();
      if (mounted) context.pop();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isLockActive) {
      _enableLockMode(); // Re-enforce
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _overlaySubscription?.cancel();
    _disableLockMode();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              // WebView
              if (!_isLoading) WebViewWidget(controller: _controller),
              
              if (_isLoading)
                const Center(child: CircularProgressIndicator()),

              // Native Exit Button (Always Visible)
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton.extended(
                  onPressed: _handleExit,
                  backgroundColor: Colors.red,
                  icon: const Icon(Icons.exit_to_app, color: Colors.white),
                  label: const Text('Selesai Ujian', style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
