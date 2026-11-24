import 'package:flutter/material.dart';
import 'absences_page.dart';
import 'stats_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Scolarité')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.event_busy),
              label: const Text('1. Absences d\'une classe'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AbsencesPage()),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.groups),
              label: const Text('2. Classe la plus nombreuse'),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const StatsPage()),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
