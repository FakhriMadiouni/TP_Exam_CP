import 'package:flutter/material.dart';
import 'ui.dart';

class FieldSpec {
  final String key;
  final String label;
  final String initial;
  final bool required;
  final TextInputType keyboard;
  const FieldSpec(
    this.key,
    this.label, {
    this.initial = '',
    this.required = true,
    this.keyboard = TextInputType.text,
  });
}

/// Boîte de dialogue de saisie générique : champs texte, liste déroulante
/// optionnelle et date optionnelle. Retourne une Map (ou null si annulé).
class FormDialog extends StatefulWidget {
  final String title;
  final List<FieldSpec> fields;
  final String? dropdownKey;
  final String dropdownLabel;
  final List<dynamic> dropdownItems;
  final String dropdownIdKey;
  final String dropdownNameKey;
  final int? dropdownInitial;
  final String? dateKey;
  final String dateLabel;
  final String? dateInitial;

  const FormDialog({
    super.key,
    required this.title,
    required this.fields,
    this.dropdownKey,
    this.dropdownLabel = '',
    this.dropdownItems = const [],
    this.dropdownIdKey = '',
    this.dropdownNameKey = '',
    this.dropdownInitial,
    this.dateKey,
    this.dateLabel = '',
    this.dateInitial,
  });

  @override
  State<FormDialog> createState() => _FormDialogState();
}

class _FormDialogState extends State<FormDialog> {
  late final List<TextEditingController> _ctrls;
  int? _dropdown;
  DateTime? _date;
  String? _error;

  @override
  void initState() {
    super.initState();
    _ctrls = [
      for (final f in widget.fields) TextEditingController(text: f.initial),
    ];
    final init = widget.dropdownInitial;
    final exists = widget.dropdownItems.any((i) => i[widget.dropdownIdKey] == init);
    _dropdown = exists ? init : null;
    final d = widget.dateInitial;
    if (d != null) _date = DateTime.tryParse(d);
  }

  @override
  void dispose() {
    for (final c in _ctrls) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _date ?? DateTime(2004, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime(2100),
    );
    if (d != null) setState(() => _date = d);
  }

  void _save() {
    final out = <String, dynamic>{};
    for (var i = 0; i < widget.fields.length; i++) {
      final f = widget.fields[i];
      final v = _ctrls[i].text.trim();
      if (f.required && v.isEmpty) {
        setState(() => _error = '${f.label} obligatoire');
        return;
      }
      out[f.key] = v;
    }
    if (widget.dropdownKey != null) {
      if (_dropdown == null) {
        setState(() => _error = '${widget.dropdownLabel} obligatoire');
        return;
      }
      out[widget.dropdownKey!] = _dropdown;
    }
    if (widget.dateKey != null) {
      out[widget.dateKey!] = _date == null ? null : fmtDate(_date!);
    }
    Navigator.pop(context, out);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < widget.fields.length; i++)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TextField(
                  controller: _ctrls[i],
                  keyboardType: widget.fields[i].keyboard,
                  decoration: InputDecoration(labelText: widget.fields[i].label),
                ),
              ),
            if (widget.dropdownKey != null) ...[
              Text(widget.dropdownLabel, style: Theme.of(context).textTheme.bodySmall),
              DropdownButton<int>(
                isExpanded: true,
                value: _dropdown,
                hint: const Text('Choisir'),
                items: [
                  for (final i in widget.dropdownItems)
                    DropdownMenuItem<int>(
                      value: i[widget.dropdownIdKey] as int,
                      child: Text('${i[widget.dropdownNameKey]}'),
                    ),
                ],
                onChanged: (v) => setState(() => _dropdown = v),
              ),
            ],
            if (widget.dateKey != null) ...[
              const SizedBox(height: 8),
              OutlinedButton(
                onPressed: _pickDate,
                child: Text(
                  _date == null
                      ? widget.dateLabel
                      : '${widget.dateLabel} : ${fmtDate(_date!)}',
                ),
              ),
            ],
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        FilledButton(onPressed: _save, child: const Text('Enregistrer')),
      ],
    );
  }
}
