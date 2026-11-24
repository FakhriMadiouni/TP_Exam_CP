import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';
import 'form_dialog.dart';

class EtudiantsPage extends StatefulWidget {
  const EtudiantsPage({super.key});

  @override
  State<EtudiantsPage> createState() => _EtudiantsPageState();
}

class _EtudiantsPageState extends State<EtudiantsPage> {
  late Future<List<dynamic>> _future;
  String _q = '';

  @override
  void initState() {
    super.initState();
    _future = Api.getList('/etudiants');
  }

  void _reload() {
    setState(() {
      _future = Api.getList('/etudiants');
    });
  }

  Future<void> _form([Map<String, dynamic>? e]) async {
    try {
      final classes = await Api.getList('/classes');
      if (!mounted) return;
      final r = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => FormDialog(
          title: e == null ? 'Nouvel étudiant' : "Modifier l'étudiant",
          fields: [
            FieldSpec('nom', 'Nom', initial: e == null ? '' : '${e['nom']}'),
            FieldSpec('prenom', 'Prénom', initial: e == null ? '' : '${e['prenom']}'),
            FieldSpec(
              'lieuNais',
              'Lieu de naissance',
              required: false,
              initial: e == null || e['lieuNais'] == null ? '' : '${e['lieuNais']}',
            ),
          ],
          dropdownKey: 'codClass',
          dropdownLabel: 'Classe',
          dropdownItems: classes,
          dropdownIdKey: 'codClass',
          dropdownNameKey: 'nomClass',
          dropdownInitial: e == null ? null : e['codClass'] as int?,
          dateKey: 'dateNais',
          dateLabel: 'Date de naissance',
          dateInitial: e == null || e['dateNais'] == null ? null : '${e['dateNais']}',
        ),
      );
      if (r == null) return;
      if (e == null) {
        await Api.post('/etudiants', r);
      } else {
        await Api.put('/etudiants/${e['nce']}', r);
      }
      if (!mounted) return;
      showMsg(context, e == null ? 'Étudiant ajouté' : 'Étudiant modifié');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  Future<void> _delete(Map<String, dynamic> e) async {
    final yes = await confirmDelete(
      context,
      'Supprimer ${e['nom']} ${e['prenom']} ? Ses absences seront aussi supprimées.',
    );
    if (!yes) return;
    try {
      await Api.delete('/etudiants/${e['nce']}');
      if (!mounted) return;
      showMsg(context, 'Étudiant supprimé');
      _reload();
    } catch (err) {
      showMsg(context, Api.errorText(err));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Étudiants')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _form(),
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
      body: Column(
        children: [
          SearchField(
            hint: 'Rechercher (nom, prénom, classe, lieu)',
            onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
          ),
          Expanded(
            child: AsyncBody<List<dynamic>>(
              future: _future,
              onRetry: _reload,
              builder: (items) {
                final shown = items.where((e) {
                  final s = '${e['nom']} ${e['prenom']} ${e['nomClass']} ${e['lieuNais'] ?? ''}'
                      .toLowerCase();
                  return s.contains(_q);
                }).toList();
                if (shown.isEmpty) {
                  return const Center(child: Text('Aucun étudiant'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 88),
                  itemCount: shown.length,
                  itemBuilder: (context, i) {
                    final e = shown[i] as Map<String, dynamic>;
                    return ListTile(
                      leading: CircleAvatar(child: Text(initial('${e['nom']}'))),
                      title: Text('${e['nom']} ${e['prenom']}'),
                      subtitle: Text(
                        '${e['nomClass']}  •  ${e['dateNais'] ?? '—'}  •  ${e['lieuNais'] ?? '—'}',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (v) {
                          if (v == 'edit') {
                            _form(e);
                          } else {
                            _delete(e);
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
