import 'package:flutter/material.dart';

/// Stand-in for tabs that are not built yet.
class PlaceholderTab extends StatelessWidget {
  const PlaceholderTab({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          '$title — coming soon',
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
