import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/tournament_store.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const PetanqueApp());
}

class PetanqueApp extends StatelessWidget {
  const PetanqueApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => TournamentStore()..init(),
      child: MaterialApp(
        title: 'Tournois Pétanque Cap Fun',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
