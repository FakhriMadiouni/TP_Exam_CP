import 'package:flutter/material.dart';
import 'api.dart';

class StatsPage extends StatefulWidget {
  const StatsPage({super.key});

  @override
  State<StatsPage> createState() => _StatsPageState();
}

class _StatsPageState extends State<StatsPage> {
  Map<String, dynamic>? d;
  String? error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final r = await Api.getMap('/classes/plus-etudiants');
      if (!mounted) return;
      setState(() {
        d = r;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => error = '$e');
    }
  }

  Future<void> _update() async {
    try {
      await Api.put('/classes/${d!['codClass']}/nbr-etud');
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('NbrEtud mis à jour')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Classe la plus nombreuse')),
      body: Center(
        child: error != null
            ? Text('Erreur : $error')
            : d == null
                ? const CircularProgressIndicator()
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${d!['nomClass']}',
                          style: Theme.of(context).textTheme.headlineMedium),
                      Text('Département : ${d!['departement']}'),
                      const SizedBox(height: 12),
                      Text(
                          'Étudiants comptés dans Etudiant : ${d!['nbEtudiantsReel']}'),
                      Text('NbrEtud actuellement dans Classe : ${d!['nbrEtud']}'),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _update,
                        child: const Text('Mettre à jour NbrEtud'),
                      ),
                    ],
                  ),
      ),
    );
  }
}
