import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/person.dart';
import '../state/app_state.dart';
import 'person_detail.dart';
import 'person_form.dart';

String fmtDate(DateTime? d) => d == null ? '' : '${d.day}/${d.month}/${d.year}';

class PersonAvatar extends StatelessWidget {
  final Person p;
  final double radius;
  const PersonAvatar(this.p, {super.key, this.radius = 24});
  @override
  Widget build(BuildContext context) {
    final has = p.photo.isNotEmpty && File(p.photo).existsSync();
    return CircleAvatar(
      radius: radius,
      backgroundImage: has ? FileImage(File(p.photo)) : null,
      child: has
          ? null
          : Text(p.name.isNotEmpty ? p.name.characters.first : '?',
              style: TextStyle(fontSize: radius * 0.8)),
    );
  }
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _i = 0;
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final pages = [const _Dashboard(), const _People(), const _Settings()];
    final titles = ['dashboard', 'people', 'settings'];
    return Directionality(
      textDirection: s.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        appBar: AppBar(title: Text(s.tr(titles[_i]))),
        body: pages[_i],
        floatingActionButton: _i == 2
            ? null
            : FloatingActionButton.extended(
                icon: const Icon(Icons.person_add),
                label: Text(s.tr('add_person')),
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const PersonForm())),
              ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          onDestinationSelected: (v) => setState(() => _i = v),
          destinations: [
            NavigationDestination(
                icon: const Icon(Icons.dashboard), label: s.tr('dashboard')),
            NavigationDestination(
                icon: const Icon(Icons.groups), label: s.tr('people')),
            NavigationDestination(
                icon: const Icon(Icons.settings), label: s.tr('settings')),
          ],
        ),
      ),
    );
  }
}

int daysToBirthday(DateTime dob) {
  final n = DateTime.now();
  final today = DateTime(n.year, n.month, n.day);
  DateTime occ(int y) =>
      DateTime(y, dob.month, (dob.month == 2 && dob.day == 29) ? 28 : dob.day);
  var next = occ(n.year);
  if (next.isBefore(today)) next = occ(n.year + 1);
  return next.difference(today).inDays;
}

class _Dashboard extends StatelessWidget {
  const _Dashboard();
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final live = s.people.where((p) => !p.deceased).toList();
    int cnt(bool Function(Person) f) => live.where(f).length;
    final stats = <List<Object>>[
      ['total', live.length, Icons.groups],
      ['males', cnt((p) => p.gender == 'M'), Icons.male],
      ['females', cnt((p) => p.gender == 'F'), Icons.female],
      ['children_c', cnt((p) => (p.age ?? 99) < 18), Icons.child_care],
      ['adults', cnt((p) => (p.age ?? 99) >= 18), Icons.person],
      ['deceased_c', s.people.length - live.length, Icons.favorite_border],
    ];
    final bdays = live.where((p) => p.dob != null).toList()
      ..sort((a, b) => daysToBirthday(a.dob!).compareTo(daysToBirthday(b.dob!)));
    final upcoming = bdays.where((p) => daysToBirthday(p.dob!) <= 30).toList();
    final cs = Theme.of(context).colorScheme;
    return ListView(padding: const EdgeInsets.all(16), children: [
      GridView.count(
        crossAxisCount: MediaQuery.of(context).size.width > 600 ? 6 : 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: [
          for (final st in stats)
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(children: [
                  Icon(st[2] as IconData, color: cs.onPrimaryContainer),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text('${st[1]}',
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(s.tr(st[0] as String),
                            style: Theme.of(context).textTheme.bodySmall,
                            overflow: TextOverflow.ellipsis),
                      ])),
                ]),
              ),
            ),
        ],
      ),
      const SizedBox(height: 20),
      Text(s.tr('bday_title'), style: Theme.of(context).textTheme.titleMedium),
      const SizedBox(height: 8),
      if (upcoming.isEmpty)
        Padding(
            padding: const EdgeInsets.all(16), child: Text(s.tr('no_bday'))),
      for (final p in upcoming)
        Card(
          color: daysToBirthday(p.dob!) == 0 ? cs.tertiaryContainer : null,
          child: ListTile(
            leading: PersonAvatar(p),
            title: Text(p.name),
            subtitle: Text(fmtDate(p.dob)),
            trailing: daysToBirthday(p.dob!) == 0
                ? Text('🎂 ${s.tr('bday_today')}')
                : Text('${daysToBirthday(p.dob!)} ${s.tr('days_left')}'),
            onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => PersonDetail(id: p.id))),
          ),
        ),
      const SizedBox(height: 80),
    ]);
  }
}

class _People extends StatefulWidget {
  const _People();
  @override
  State<_People> createState() => _PeopleState();
}

class _PeopleState extends State<_People> {
  String _q = '';
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final q = _q.trim().toLowerCase();
    final list = s.people
        .where((p) =>
            q.isEmpty ||
            p.name.toLowerCase().contains(q) ||
            p.father.toLowerCase().contains(q) ||
            p.mobile.contains(q) ||
            p.cnic.replaceAll('-', '').contains(q.replaceAll('-', '')))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: (v) => setState(() => _q = v),
          decoration: InputDecoration(
              hintText: s.tr('search'), prefixIcon: const Icon(Icons.search)),
        ),
      ),
      Expanded(
        child: list.isEmpty
            ? Center(child: Text(s.tr('empty')))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 90),
                itemCount: list.length,
                itemBuilder: (_, i) {
                  final p = list[i];
                  return Card(
                    child: ListTile(
                      leading: PersonAvatar(p),
                      title: Text(p.name),
                      subtitle: Text(
                          '${s.tr('rel_${p.relation}')}${p.father.isNotEmpty ? ' • ${p.father}' : ''}${p.deceased ? ' • ${s.tr('deceased_c')}' : ''}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PersonDetail(id: p.id))),
                    ),
                  );
                },
              ),
      ),
    ]);
  }
}

class _Settings extends StatelessWidget {
  const _Settings();
  Future<void> _changePw(BuildContext context, AppState s) async {
    final o = TextEditingController(), n = TextEditingController();
    await showDialog(
        context: context,
        builder: (_) => AlertDialog(
              title: Text(s.tr('change_pw')),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: o,
                    obscureText: true,
                    decoration: InputDecoration(labelText: s.tr('old_pw'))),
                const SizedBox(height: 10),
                TextField(
                    controller: n,
                    obscureText: true,
                    decoration: InputDecoration(labelText: s.tr('new_pw'))),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(s.tr('cancel'))),
                FilledButton(
                    onPressed: () async {
                      final nav = Navigator.of(context);
                      final msg = ScaffoldMessenger.of(context);
                      if (n.text.length < 6) {
                        msg.showSnackBar(
                            SnackBar(content: Text(s.tr('pw_short'))));
                        return;
                      }
                      final ok = await s.changePassword(o.text, n.text);
                      nav.pop();
                      msg.showSnackBar(SnackBar(
                          content: Text(
                              ok ? s.tr('done') : s.tr('pw_wrong'))));
                    },
                    child: Text(s.tr('save'))),
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text(s.tr('theme'), style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      SegmentedButton<ThemeMode>(
        segments: [
          ButtonSegment(value: ThemeMode.system, label: Text(s.tr('system'))),
          ButtonSegment(value: ThemeMode.light, label: Text(s.tr('light'))),
          ButtonSegment(value: ThemeMode.dark, label: Text(s.tr('dark'))),
        ],
        selected: {s.themeMode},
        onSelectionChanged: (v) => s.setTheme(v.first),
      ),
      const SizedBox(height: 20),
      Text(s.tr('language'), style: Theme.of(context).textTheme.titleSmall),
      const SizedBox(height: 8),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'ur', label: Text('اردو')),
          ButtonSegment(value: 'en', label: Text('English')),
        ],
        selected: {s.lang},
        onSelectionChanged: (v) => s.setLang(v.first),
      ),
      const SizedBox(height: 20),
      ListTile(
          leading: const Icon(Icons.password),
          title: Text(s.tr('change_pw')),
          onTap: () => _changePw(context, s)),
      ListTile(
          leading: const Icon(Icons.logout),
          title: Text(s.tr('logout')),
          onTap: s.logout),
    ]);
  }
}
