import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../services/vault.dart';
import '../state/app_state.dart';
import '../state/strings.dart';
import 'home_screen.dart';

class PersonForm extends StatefulWidget {
  final Person? existing;
  const PersonForm({super.key, this.existing});
  @override
  State<PersonForm> createState() => _PersonFormState();
}

class _PersonFormState extends State<PersonForm> {
  final _key = GlobalKey<FormState>();
  late final Map<String, TextEditingController> _c;
  late String _gender, _marital, _relation, _photo;
  DateTime? _dob, _dod;
  late bool _deceased;
  static const _fields = [
    'name', 'father', 'mother', 'mobile', 'cnic', 'birthPlace', 'address',
    'permAddress', 'spouse', 'children', 'notes'
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existing;
    final init = <String, String>{
      'name': p?.name ?? '',
      'father': p?.father ?? '',
      'mother': p?.mother ?? '',
      'mobile': p?.mobile ?? '',
      'cnic': p?.cnic ?? '',
      'birthPlace': p?.birthPlace ?? '',
      'address': p?.address ?? '',
      'permAddress': p?.permAddress ?? '',
      'spouse': p?.spouse ?? '',
      'children': (p?.children ?? []).join(', '),
      'notes': p?.notes ?? '',
    };
    _c = {for (final f in _fields) f: TextEditingController(text: init[f])};
    _gender = p?.gender ?? 'M';
    _marital = p?.marital ?? 'ms_single';
    _relation = p?.relation ?? 'other';
    _photo = p?.photo ?? '';
    _dob = p?.dob;
    _dod = p?.dod;
    _deceased = p?.deceased ?? false;
  }

  Future<void> _pickPhoto() async {
    final x = await ImagePicker()
        .pickImage(source: ImageSource.gallery, maxWidth: 800, imageQuality: 80);
    if (x == null) return;
    final d = Directory('${(await Vault.dir()).path}/photos');
    await d.create(recursive: true);
    final path = '${d.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(x.path).copy(path);
    setState(() => _photo = path);
  }

  Future<void> _pickDate(bool birth) async {
    final d = await showDatePicker(
      context: context,
      initialDate: (birth ? _dob : _dod) ?? DateTime(1990),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => birth ? _dob = d : _dod = d);
  }

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final s = context.read<AppState>();
    final nav = Navigator.of(context);
    String v(String k) => _c[k]!.text.trim();
    final p = Person(
      id: widget.existing?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      name: v('name'),
      father: v('father'),
      mother: v('mother'),
      photo: _photo,
      mobile: v('mobile'),
      cnic: v('cnic'),
      birthPlace: v('birthPlace'),
      address: v('address'),
      permAddress: v('permAddress'),
      gender: _gender,
      marital: _marital,
      spouse: v('spouse'),
      relation: _relation,
      notes: v('notes'),
      dob: _dob,
      dod: _deceased ? _dod : null,
      deceased: _deceased,
      children: v('children')
          .split(RegExp(r'[,،\n]'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
    );
    await s.upsert(p);
    nav.pop();
  }

  Widget _tf(AppState s, String k, String label,
      {TextInputType? type, bool req = false, int lines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: _c[k],
        keyboardType: type,
        maxLines: lines,
        decoration: InputDecoration(labelText: s.tr(label)),
        validator: req
            ? (x) => (x == null || x.trim().isEmpty) ? s.tr('required') : null
            : null,
      ),
    );
  }

  Widget _dateTile(AppState s, String label, DateTime? d, bool birth) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: OutlinedButton.icon(
          icon: const Icon(Icons.calendar_today),
          label: Text('${s.tr(label)}: ${d == null ? s.tr('pick') : fmtDate(d)}'),
          onPressed: () => _pickDate(birth),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final preview = Person(id: 'x', name: _c['name']!.text, photo: _photo);
    return Directionality(
      textDirection: s.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(
          title: Text(s.tr(widget.existing == null ? 'add_person' : 'edit')),
          actions: [
            TextButton(onPressed: _save, child: Text(s.tr('save'))),
          ],
        ),
        body: Form(
          key: _key,
          child: ListView(padding: const EdgeInsets.all(16), children: [
            Center(
                child: GestureDetector(
                    onTap: _pickPhoto,
                    child: PersonAvatar(preview, radius: 52))),
            TextButton.icon(
                onPressed: _pickPhoto,
                icon: const Icon(Icons.photo),
                label: Text(s.tr('photo'))),
            const SizedBox(height: 8),
            _tf(s, 'name', 'name', req: true),
            DropdownButtonFormField<String>(
              initialValue: _relation,
              decoration: InputDecoration(labelText: s.tr('relation')),
              items: [
                for (final r in relations)
                  DropdownMenuItem(value: r, child: Text(s.tr('rel_$r')))
              ],
              onChanged: (v) => setState(() => _relation = v!),
            ),
            const SizedBox(height: 12),
            SegmentedButton<String>(
              segments: [
                ButtonSegment(value: 'M', label: Text(s.tr('male'))),
                ButtonSegment(value: 'F', label: Text(s.tr('female'))),
              ],
              selected: {_gender},
              onSelectionChanged: (v) => setState(() => _gender = v.first),
            ),
            const SizedBox(height: 12),
            _tf(s, 'father', 'father'),
            _tf(s, 'mother', 'mother'),
            _tf(s, 'mobile', 'mobile', type: TextInputType.phone),
            _tf(s, 'cnic', 'cnic', type: TextInputType.number),
            _dateTile(s, 'dob', _dob, true),
            _tf(s, 'birthPlace', 'birthplace'),
            _tf(s, 'address', 'address', lines: 2),
            _tf(s, 'permAddress', 'permaddr', lines: 2),
            DropdownButtonFormField<String>(
              initialValue: _marital,
              decoration: InputDecoration(labelText: s.tr('marital')),
              items: [
                for (final m in maritals)
                  DropdownMenuItem(value: m, child: Text(s.tr(m)))
              ],
              onChanged: (v) => setState(() => _marital = v!),
            ),
            const SizedBox(height: 12),
            _tf(s, 'spouse', 'spouse'),
            _tf(s, 'children', 'children_names', lines: 2),
            SwitchListTile(
                title: Text(s.tr('dec_is')),
                value: _deceased,
                onChanged: (v) => setState(() => _deceased = v)),
            if (_deceased) _dateTile(s, 'dod', _dod, false),
            _tf(s, 'notes', 'notes', lines: 3),
            const SizedBox(height: 12),
            FilledButton(onPressed: _save, child: Text(s.tr('save'))),
            const SizedBox(height: 24),
          ]),
        ),
      ),
    );
  }
}
