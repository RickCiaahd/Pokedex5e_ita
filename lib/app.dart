import 'package:flutter/material.dart';

import 'screens/home/home_screen.dart';

class Pokedex5EApp extends StatelessWidget {
  const Pokedex5EApp({super.key});

  static const Color _brandOrange = Color(0xFFF26A21);
  static const Color _appBackground = Color(0xFFF4F1EC);

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandOrange,
      brightness: Brightness.light,
    );

    return MaterialApp(
      title: 'Pokédex 5e ITA',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _appBackground,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
          iconTheme: IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 1.5,
          margin: const EdgeInsets.symmetric(vertical: 6),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _brandOrange,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: _brandOrange,
          unselectedLabelColor: Colors.black54,
          indicatorColor: _brandOrange,
          labelStyle: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
