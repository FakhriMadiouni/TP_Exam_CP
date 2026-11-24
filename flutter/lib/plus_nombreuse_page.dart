import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';

class PlusNombreusePage extends StatefulWidget {
  const PlusNombreusePage({super.key});

  @override
  State<PlusNombreusePage> createState() => _PlusNombreusePageState();
}

class _PlusNombreusePageState extends State<PlusNombreusePage> {
  late Future<Map<String, dynamic>> _future;

  @override
  void initState() {
    super.initState();
    _future = Api.getMap('/classes/plus-etudiants');
  }

  void _reload() {
    setState(() {
      _future = Api.getMap('/classes/plus-etudiants');
    });
  }

  Future<void> _update(Map<String, dynamic> d) async {
    try {
      await Api.put('/classes/${d['codClass']}/nbr-etud');
      if (!mounted) return;
      showMsg(context, 'NbrEtud mis à jour');
      _reload();
    } catch (e) {
      showMsg(context, Api.errorText(e));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classe la plus nombreuse')),
      body: AsyncBody<Map<String, dynamic>>(
        future: _future,
        onRetry: _reload,
        builder: (d) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HighlightCard(
                title: 'Classe ayant le plus d\'étudiants',
                name: '${d['nomClass']}',
                detail: 'Département : ${d['departement']}',
              ),
              const SizedBox(height: 8),
              Text('Étudiants comptés dans la table Etudiant : ${d['nbEtudiantsReel']}'),
              const SizedBox(height: 4),
              Text('NbrEtud actuellement dans la table Classe : ${d['nbrEtud']}'),
              const SizedBox(height: 24),
              FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                onPressed: () => _update(d),
                child: const Text('Mettre à jour NbrEtud'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
