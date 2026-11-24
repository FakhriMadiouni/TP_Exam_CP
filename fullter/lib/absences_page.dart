import 'package:flutter/material.dart';
import 'api.dart';
import 'ui.dart';

class AbsencesPage extends StatefulWidget {
  const AbsencesPage({super.key});

  @override
  State<AbsencesPage> createState() => _AbsencesPageState();
}

class _AbsencesPageState extends State<AbsencesPage> {
  List<dynamic> classes = [];
  List<dynamic> matieres = [];
  int? codClass;
  int? codMat;
  DateTime date = DateTime.now();
  Map<String, dynamic>? data;
  final Map<int, TextEditingController> ctrls = {};

  @override
  void initState() {
    super.initState();
    _run(() async {
      final r = await Api.getList('/classes');
      if (!mounted) return;
      setState(() => classes = r);
    });
  }

  @override
  void dispose() {
    for (final c in ctrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _run(Future<void> Function() f) async {
    try {
      await f();
    } catch (e) {
      showMsg(context, Api.errorText(e));
    }
  }

  Future<void> _onClass(int? v) async {
    setState(() {
      codClass = v;
      codMat = null;
      matieres = [];
      data = null;
    });
    if (v == null) return;
    await _run(() async {
      final r = await Api.getList('/classes/$v/matieres');
      if (!mounted) return;
      setState(() => matieres = r);
    });
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (d != null) {
      setState(() {
        date = d;
        data = null;
      });
    }
  }

  Future<void> _load() async {
    if (codClass == null || codMat == null) {
      showMsg(context, 'Choisissez une classe et une matière');
      return;
    }
    await _run(() async {
      final d = await Api.getMap(
        '/absences?codClass=$codClass&codMat=$codMat&date=${fmtDate(date)}',
      );
      for (final c in ctrls.values) {
        c.dispose();
      }
      ctrls.clear();
      for (final e in (d['etudiants'] as List)) {
        ctrls[e['nce'] as int] = TextEditingController(text: '${e['nha']}');
      }
      if (!mounted) return;
      setState(() => data = d);
    });
  }

  Future<void> _save() async {
    final chsm = data!['chsm'] as int;
    final items = <Map<String, dynamic>>[];
    for (final e in (data!['etudiants'] as List)) {
      final nha = int.tryParse(ctrls[e['nce'] as int]!.text.trim()) ?? 0;
      if (nha < 0 || nha > chsm) {
        showMsg(context, 'NHA invalide pour ${e['nom']} (entre 0 et $chsm)');
        return;
      }
      items.add({'nce': e['nce'], 'nha': nha});
    }
    await _run(() async {
      await Api.post('/absences', {
        'codClass': codClass,
        'codMat': codMat,
        'date': fmtDate(date),
        'items': items,
      });
      showMsg(context, 'Absences enregistrées');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Absences d'une classe")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            DropdownButton<int>(
              isExpanded: true,
              hint: const Text('Classe'),
              value: codClass,
              items: [
                for (final c in classes)
                  DropdownMenuItem<int>(
                    value: c['codClass'] as int,
                    child: Text('${c['nomClass']}'),
                  ),
              ],
              onChanged: _onClass,
            ),
            DropdownButton<int>(
              isExpanded: true,
              hint: const Text('Matière'),
              value: codMat,
              items: [
                for (final m in matieres)
                  DropdownMenuItem<int>(
                    value: m['codMat'] as int,
                    child: Text('${m['intMat']}'),
                  ),
              ],
              onChanged: (v) => setState(() {
                codMat = v;
                data = null;
              }),
            ),
            Row(
              children: [
                Expanded(child: Text('Date : ${fmtDate(date)}')),
                TextButton(onPressed: _pickDate, child: const Text('Changer')),
                FilledButton(onPressed: _load, child: const Text('Afficher')),
              ],
            ),
            const Divider(),
            Expanded(
              child: data == null
                  ? const Center(child: Text('Choisissez classe, matière et date'))
                  : _table(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _table() {
    final etu = data!['etudiants'] as List;
    const bold = TextStyle(fontWeight: FontWeight.bold);
    if (etu.isEmpty) {
      return const Center(child: Text('Aucun étudiant dans cette classe'));
    }
    return Column(
      children: [
        Card(
          child: ListTile(
            isThreeLine: true,
            title: Text(
              'Classe : ${data!['classe']}   Département : ${data!['departement']}',
            ),
            subtitle: Text(
              'Matière : ${data!['matiere']}\nCHSM : ${data!['chsm']} heures   Date : ${data!['date']}',
            ),
          ),
        ),
        const Row(
          children: [
            Expanded(child: Text('Nom', style: bold)),
            Expanded(child: Text('Prénom', style: bold)),
            SizedBox(width: 70, child: Text('NHA', style: bold)),
          ],
        ),
        const Divider(),
        Expanded(
          child: ListView(
            children: [
              for (final e in etu)
                Row(
                  children: [
                    Expanded(child: Text('${e['nom']}')),
                    Expanded(child: Text('${e['prenom']}')),
                    SizedBox(
                      width: 70,
                      child: TextField(
                        controller: ctrls[e['nce'] as int],
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }
}
