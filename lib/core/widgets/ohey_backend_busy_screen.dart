import 'package:flutter/material.dart';

import 'ohey_startup_splash.dart';

/// Keeps stored-session restoration on the same launch splash instead of
/// introducing a separate backend-loading screen.
class OheyBackendBusyScreen extends StatelessWidget {
  const OheyBackendBusyScreen({super.key});

  @override
  Widget build(BuildContext context) => const OheyStartupSplash();
}
