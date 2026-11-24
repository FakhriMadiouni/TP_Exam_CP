import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';
import 'form_dialog.dart';

class ClassesPage extends StatefulWidget {
  const ClassesPage({super.key});

  @override
  State<ClassesPage> createState() => _ClassesPageState();
}

class _ClassesPageState extends State<ClassesPage> {
  late Future<List<dynamic>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = Api.getList('/classes');
  }

  void _reload() {
    setState(() {
      _future = Api.getList('/classes');
    });
  }

  Future<void> _form([Map<String, dynamic>? c]) async {
    try {
      final deps = await Api.getList('/departements');
      if (!mounted) return;
      final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => FormDialog(
          title: c == null ? 'Nouvelle classe' : 'Modifier la classe',
          fields: [
            FieldSpec('nomClass', 'Nom de la classe', initial: c == null ? '' : '${c['nomClass']}'),
          ],
          dropdownKey: 'codDept',
          dropdownLabel: 'Département',
          dropdownItems: deps,
          dropdownIdKey: 'codDept',
          dropdownNameKey: 'nomDept',
          dropdownInitial: c == null ? null : c['codDept'] as int?,
        ),
      );
      if (r == null) return;
      if (c == null) {
        await Api.post('/classes', r);
      } else {
        await Api.put('/classes/${c['codClass']}', r);
      }
      if (!mounted) return;
      showMsg(context, c == null ? 'Classe ajoutée' : 'Classe modifiée');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  Future<void> _delete(Map<String, dynamic> c) async {
    final yes = await confirmDelete(context, 'Supprimer la classe ${c['nomClass']} ?');
    if (!yes) return;
    try {
      await Api.delete('/classes/${c['codClass']}');
      if (!mounted) return;
      showMsg(context, 'Classe supprimée');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          SearchField(
            hint: 'Rechercher (classe, département)',
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
          Expanded(
            child: AsyncBody<List<dynamic>>(
              future: _future,
              onRetry: _reload,
              builder: (items) {
                final shown = items.where((c) {
                  final s = '${c['nomClass']} ${c['departement'] ?? ''}'.toLowerCase();
                  return s.contains(_q);
                }).toList();
                if (shown.isEmpty) {
                  return const Center(child: Text('Aucune classe'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final c = shown[i] as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text(initial('${c['nomClass']}'))),
                      title: Text('${c['nomClass']}'),
                      subtitle: Text(
                        '${c['departement'] ?? '—'}  •  ${c['nbEtudiantsReel']} étudiant(s)',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') {
                            _form(c);
                          } else {
                            _delete(c);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('Modifier')),
                          PopupMenuItem(value: 'del', child: Text('Supprimer')),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
