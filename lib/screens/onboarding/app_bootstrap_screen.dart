import 'package:flutter/material.dart';

import '../../services/app_launch_service.dart';
import '../home/home_screen.dart';
import 'first_launch_onboarding_screen.dart';
import '../../localization/ui_text.dart';

class AppBootstrapScreen extends StatefulWidget {
  const AppBootstrapScreen({super.key});

  @override
  State<AppBootstrapScreen> createState() => _AppBootstrapScreenState();
}

class _AppBootstrapScreenState extends State<AppBootstrapScreen> {
  final AppLaunchService _appLaunchService = AppLaunchService();

  bool _isLoading = true;
  bool _showOnboarding = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _resolveLaunchDestination();
  }

  Future<void> _resolveLaunchDestination() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final showOnboarding = await _appLaunchService.shouldShowOnboarding();
      if (!mounted) return;
      setState(() {
        _showOnboarding = showOnboarding;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 12),
                Text(_errorMessage!, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _resolveLaunchDestination,
                  child: Text(uiTextForLanguage('RIPROVA', """RETRY""")),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_showOnboarding) {
      return FirstLaunchOnboardingScreen(
        onCompleted: () {
          if (!mounted) return;
          setState(() => _showOnboarding = false);
        },
      );
    }

    return const HomeScreen();
  }
}
