import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';
import 'home_screen.dart';
import 'person_form.dart';

class PersonDetail extends StatelessWidget {
  final String id;
  const PersonDetail({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final idx = s.people.indexWhere((p) => p.id == id);
    if (idx < 0) return const Scaffold();
    final p = s.people[idx];
    final rows = <List<String>>[
      ['relation', s.tr('rel_${p.relation}')],
      ['gender', s.tr(p.gender == 'M' ? 'male' : 'female')],
      ['father', p.father],
      ['mother', p.mother],
      ['mobile', p.mobile],
      ['cnic', p.cnic],
      ['dob', fmtDate(p.dob)],
      ['age', p.age == null ? '' : '${p.age} ${s.tr('years')}'],
      ['birthplace', p.birthPlace],
      ['address', p.address],
      ['permaddr', p.permAddress],
      ['marital', s.tr(p.marital)],
      ['spouse', p.spouse],
      ['children_info', p.children.join('، ')],
      ['dod', p.deceased ? fmtDate(p.dod) : ''],
      ['notes', p.notes],
    ].where((r) => r[1].isNotEmpty).toList();
    return Directionality(
      textDirection: s.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(p.name), actions: [
          IconButton(
              icon: const Icon(Icons.edit),
              tooltip: s.tr('edit'),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => PersonForm(existing: p)))),
          IconButton(
              icon: const Icon(Icons.delete),
              tooltip: s.tr('delete'),
              onPressed: () async {
                final nav = Navigator.of(context);
                final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                          title: Text(s.tr('delete_q')),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(s.tr('cancel'))),
                            FilledButton(
                                onPressed: () => Navigator.pop(context, true),
                                child: Text(s.tr('delete'))),
                          ],
                        ));
                if (ok == true) {
                  await s.remove(p.id);
                  nav.pop();
                }
              }),
        ]),
        body: ListView(padding: const EdgeInsets.all(16), children: [
          Center(child: PersonAvatar(p, radius: 56)),
          const SizedBox(height: 8),
          Center(
              child: Text(p.name,
                  style: Theme.of(context).textTheme.headlineSmall)),
          if (p.deceased)
            Center(child: Text(s.tr('dec_is'))),
          const SizedBox(height: 16),
          Card(
            child: Column(children: [
              for (final r in rows)
                ListTile(
                    dense: true,
                    title: Text(s.tr(r[0]),
                        style: Theme.of(context).textTheme.bodySmall),
                    subtitle: Text(r[1],
                        style: Theme.of(context).textTheme.bodyLarge)),
            ]),
          ),
        ]),
      ),
    );
  }
}
