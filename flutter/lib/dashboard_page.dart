import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';
import 'absences_page.dart';
import 'plus_nombreuse_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.getMap('/stats/overview');
  }

  void _reload() {
    setState(() {
      _future = Api.getMap('/stats/overview');
    });
  }

  Widget _top(String title, dynamic m, String nameKey, String valueKey, String unit) {
    if (m == null) {
      return HighlightCard(title: title, name: '—', detail: 'Aucune donnée');
    }
    return HighlightCard(
      title: title,
      name: '${m[nameKey]}',
      detail: '${m[valueKey]} $unit',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: AsyncBody<Map<String, dynamic>>(
          future: _future,
          onRetry: _reload,
          builder: (d) => RefreshIndicator(
            onRefresh: () async {
              _reload();
              try {
                await _future;
              } catch (_) {}
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  'Scolarité',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text('Tableau de bord', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.5,
                  children: [
                    StatCard(label: 'Étudiants', value: '${d['nbEtudiants']}'),
                    StatCard(label: 'Classes', value: '${d['nbClasses']}'),
                    StatCard(label: 'Matières', value: '${d['nbMatieres']}'),
                    StatCard(label: "Heures d'absence", value: '${d['totalAbsences']}'),
                  ],
                ),
                const SectionTitle('Classements'),
                _top('Classe la plus nombreuse', d['classePlusNombreuse'], 'nomClass', 'effectif', 'étudiants'),
                _top('Classe avec le plus d\'absences', d['classePlusAbsente'], 'nomClass', 'totalNha', 'h d\'absence'),
                _top('Matière avec le plus d\'absences', d['matierePlusAbsente'], 'intMat', 'totalNha', 'h d\'absence'),
                const SectionTitle('Examen'),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AbsencesPage()),
                  ),
                  child: const Text("Absences d'une classe"),
                ),
                const SizedBox(height: 8),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PlusNombreusePage()),
                  ),
                  child: const Text('Classe la plus nombreuse'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
