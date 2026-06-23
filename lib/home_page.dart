import 'package:flutter/material.dart';
import 'home.dart';

/// Compatibility wrapper.
///
/// The codebase references `HomePage()` in several places, but the actual
/// implementation lives in `home.dart` as `MainShell`.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const MainShell();
  }
}


