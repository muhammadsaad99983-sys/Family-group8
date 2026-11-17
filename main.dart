import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'state/app_state.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final s = AppState();
  await s.init();
  runApp(ChangeNotifierProvider.value(value: s, child: const FamilyApp()));
}

ThemeData _theme(Brightness b) => ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1B6B5A), brightness: b),
      cardTheme: CardThemeData(
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
      inputDecorationTheme: InputDecorationTheme(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
    );

class FamilyApp extends StatelessWidget {
  const FamilyApp({super.key});
  @override
  Widget build(BuildContext context) {
    final s = context.watch<AppState>();
    return MaterialApp(
      title: 'Family Group',
      debugShowCheckedModeBanner: false,
      themeMode: s.themeMode,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      locale: Locale(s.lang),
      supportedLocales: const [Locale('ur'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: s.loggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
