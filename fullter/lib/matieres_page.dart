import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';
import 'form_dialog.dart';

class MatieresPage extends StatefulWidget {
  const MatieresPage({super.key});

  @override
  State<MatieresPage> createState() => _MatieresPageState();
}

class _MatieresPageState extends State<MatieresPage> {
  late Future<List<dynamic>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = Api.getList('/matieres');
  }

  void _reload() {
    setState(() {
      _future = Api.getList('/matieres');
    });
  }

  Future<void> _form([Map<String, dynamic>? m]) async {
    final r = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => FormDialog(
        title: m == null ? 'Nouvelle matière' : 'Modifier la matière',
        fields: [
          FieldSpec('intMat', 'Intitulé', initial: m == null ? '' : '${m['intMat']}'),
          FieldSpec(
            'description',
            'Description',
            required: false,
            initial: m == null || m['description'] == null ? '' : '${m['description']}',
          ),
        ],
      ),
    );
    if (r == null) return;
    try {
      if (m == null) {
        await Api.post('/matieres', r);
      } else {
        await Api.put('/matieres/${m['codMat']}', r);
      }
      if (!mounted) return;
      showMsg(context, m == null ? 'Matière ajoutée' : 'Matière modifiée');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  Future<void> _delete(Map<String, dynamic> m) async {
    final yes = await confirmDelete(
      context,
      'Supprimer la matière ${m['intMat']} ? Ses absences et ses affectations seront aussi supprimées.',
    );
    if (!yes) return;
    try {
      await Api.delete('/matieres/${m['codMat']}');
      if (!mounted) return;
      showMsg(context, 'Matière supprimée');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Matières')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          SearchField(
            hint: 'Rechercher une matière',
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Touchez une matière pour gérer ses classes (CHSM, coefficient).',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
          ),
          Expanded(
            child: AsyncBody<List<dynamic>>(
              future: _future,
              onRetry: _reload,
              builder: (items) {
                final shown = items.where((m) {
                  final s = '${m['intMat']} ${m['description'] ?? ''}'.toLowerCase();
                  return s.contains(_q);
                }).toList();
                if (shown.isEmpty) {
                  return const Center(child: Text('Aucune matière'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final m = shown[i] as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text(initial('${m['intMat']}'))),
                      title: Text('${m['intMat']}'),
                      subtitle: Text('${m['description'] ?? '—'}'),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MatiereClassesPage(matiere: m)),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') {
                            _form(m);
                          } else {
                            _delete(m);
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

/// Classes auxquelles une matière est affectée (CHSM + coefficient).
class MatiereClassesPage extends StatefulWidget {
  final Map<String, dynamic> matiere;
  const MatiereClassesPage({super.key, required this.matiere});

  @override
  State<MatiereClassesPage> createState() => _MatiereClassesPageState();
}

class _MatiereClassesPageState extends State<MatiereClassesPage> {
  late Future<List<dynamic>> _future;

  String get _path => '/matieres/${widget.matiere['codMat']}/classes';

  @override
  void initState() {
    super.initState();
    _future = Api.getList(_path);
  }

  void _reload() {
    setState(() {
      _future = Api.getList(_path);
    });
  }

  Future<void> _affecter() async {
    try {
      final classes = await Api.getList('/classes');
      if (!mounted) return;
      final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => FormDialog(
          title: 'Affecter à une classe',
          fields: const [
            FieldSpec('chsm', 'CHSM (heures par semestre)', keyboard: TextInputType.number),
            FieldSpec(
              'coef',
              'Coefficient',
              initial: '1',
              required: false,
              keyboard: TextInputType.numberWithOptions(decimal: true),
            ),
          ],
          dropdownKey: 'codClass',
          dropdownLabel: 'Classe',
          dropdownItems: classes,
          dropdownIdKey: 'codClass',
          dropdownNameKey: 'nomClass',
        ),
      );
      if (r == null) return;
      await Api.post(_path, r);
      if (!mounted) return;
      showMsg(context, 'Matière affectée');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  Future<void> _retirer(Map<String, dynamic> c) async {
    final yes = await confirmDelete(
      context,
      'Retirer ${widget.matiere['intMat']} de la classe ${c['nomClass']} ?',
    );
    if (!yes) return;
    try {
      await Api.delete('$_path/${c['codClass']}');
      if (!mounted) return;
      showMsg(context, 'Affectation retirée');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.matiere['intMat']}')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _affecter,
        icon: const Icon(Icons.add),
        label: const Text('Affecter à une classe'),
      ),
      body: AsyncBody<List<dynamic>>(
        future: _future,
        onRetry: _reload,
        builder: (items) {
          if (items.isEmpty) {
            return const Center(child: Text("Cette matière n'est affectée à aucune classe"));
          }
          return ListView.builder(
            padding: const EdgeInsets.only(bottom: 88),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final c = items[i] as Map<String, dynamic>;
              return ListTile(
                leading: CircleAvatar(child: Text(initial('${c['nomClass']}'))),
                title: Text('${c['nomClass']}'),
                subtitle: Text('CHSM : ${c['chsm']} h  •  Coefficient : ${c['coef']}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _retirer(c),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
