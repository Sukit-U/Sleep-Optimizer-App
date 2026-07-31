import 'package:flutter/material.dart';

/// A reusable AppBar widget that follows the project's design system.
/// It uses the primary color from the current theme and displays the app title.
class AppBarWidget extends StatelessWidget implements PreferredSizeWidget {
  const AppBarWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const Text('Snoozefriend'),
      backgroundColor: Theme.of(context).primaryColor,
      elevation: 0,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
