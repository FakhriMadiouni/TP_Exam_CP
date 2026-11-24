import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';

class StatistiquesPage extends StatelessWidget {
  const StatistiquesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Statistiques'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Effectifs'),
              Tab(text: 'Classes'),
              Tab(text: 'Matières'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TableTab(
              title: "Nombre d'étudiants par classe",
              path: '/stats/classes-effectif',
              headers: const ['Classe', 'Étudiants'],
              cells: (r) => ['${r['nomClass']}', '${r['effectif']}'],
            ),
            _TableTab(
              title: "Absences par classe (de la plus absente à la moins absente)",
              path: '/stats/absences-classes',
              headers: const ['Classe', 'Absents', 'Heures'],
              cells: (r) => [
                '${r['nomClass']}',
                '${r['nbAbsents']}',
                '${r['totalNha']}',
              ],
            ),
            _TableTab(
              title: "Absences par matière (de la plus absente à la moins absente)",
              path: '/stats/absences-matieres',
              headers: const ['Matière', 'Absents', 'Heures'],
              cells: (r) => [
                '${r['intMat']}',
                '${r['nbAbsents']}',
                '${r['totalNha']}',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TableTab extends StatefulWidget {
  final String title;
  final String path;
  final List<String> headers;
  final List<String> Function(Map<String, dynamic> row) cells;
  const _TableTab({
    required this.title,
    required this.path,
    required this.headers,
    required this.cells,
  });

  @override
  State<_TableTab> createState() => _TableTabState();
}

class _TableTabState extends State<_TableTab> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.getList(widget.path);
  }

  void _reload() {
    setState(() {
      _future = Api.getList(widget.path);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AsyncBody<List<dynamic>>(
      future: _future,
      onRetry: _reload,
      builder: (rows) {
        if (rows.isEmpty) {
          return const Center(child: Text('Aucune donnée'));
        }
        const bold = TextStyle(fontWeight: FontWeight.bold);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.title, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 28,
                  horizontalMargin: 12,
                  columns: [
                    for (var i = 0; i < widget.headers.length; i++)
                      DataColumn(
                        label: Text(widget.headers[i], style: bold),
                        numeric: i > 0,
                      ),
                  ],
                  rows: [
                    for (final r in rows)
                      DataRow(
                        cells: [
                          for (final c in widget.cells(r as Map<String, dynamic>))
                            DataCell(Text(c)),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}