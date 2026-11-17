import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/app_state.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _p = TextEditingController();
  final _c = TextEditingController();
  String? _err;

  Future<void> _submit() async {
    final s = context.read<AppState>();
    if (!s.hasPassword) {
      if (_p.text.length < 6) return setState(() => _err = s.tr('pw_short'));
      if (_p.text != _c.text) return setState(() => _err = s.tr('pw_mismatch'));
      await s.setupPassword(_p.text);
    } else {
      if (!await s.login(_p.text)) setState(() => _err = s.tr('pw_wrong'));
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    final setup = !s.hasPassword;
    final cs = Theme.of(context).colorScheme;
    return Directionality(
      textDirection: s.lang == 'ur' ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(children: [
                Icon(Icons.family_restroom, size: 88, color: cs.primary),
                const SizedBox(height: 8),
                Text(s.tr('app'),
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 24),
                if (setup)
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(s.tr('setup_title'),
                          style: Theme.of(context).textTheme.titleMedium)),
                TextField(
                    controller: _p,
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: s.tr('password'),
                        prefixIcon: const Icon(Icons.lock))),
                if (setup) ...[
                  const SizedBox(height: 12),
                  TextField(
                      controller: _c,
                      obscureText: true,
                      decoration: InputDecoration(
                          labelText: s.tr('confirm'),
                          prefixIcon: const Icon(Icons.lock_outline))),
                ],
                if (_err != null)
                  Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_err!, style: TextStyle(color: cs.error))),
                const SizedBox(height: 20),
                SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                        onPressed: _submit,
                        child:
                            Text(setup ? s.tr('set_pw') : s.tr('enter')))),
                const SizedBox(height: 12),
                TextButton(
                    onPressed: () => s.setLang(s.lang == 'ur' ? 'en' : 'ur'),
                    child: Text(s.lang == 'ur' ? 'English' : 'اردو')),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
