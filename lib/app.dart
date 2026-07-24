import 'package:flutter/material.dart';

import 'screens/onboarding/app_bootstrap_screen.dart';

class Pokedex5EApp extends StatelessWidget {
  const Pokedex5EApp({super.key});

  static const Color _brandOrange = Color(0xFFF26A21);
  static const Color _appBackground = Color(0xFFF4F1EC);
  static const VisualDensity _compactDensity = VisualDensity(
    horizontal: -1,
    vertical: -1.5,
  );

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _brandOrange,
      brightness: Brightness.light,
    );

    final compactButtonStyle = ButtonStyle(
      minimumSize: const WidgetStatePropertyAll(Size(0, 42)),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      visualDensity: _compactDensity,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );

    return MaterialApp(
      title: 'Trainer Atlas',
      debugShowCheckedModeBanner: false,
      scrollBehavior: const MaterialScrollBehavior().copyWith(
        scrollbars: false,
      ),
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: _appBackground,
        useMaterial3: true,
        visualDensity: _compactDensity,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        appBarTheme: const AppBarTheme(
          backgroundColor: _brandOrange,
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          toolbarHeight: 56,
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
          margin: const EdgeInsets.symmetric(vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: compactButtonStyle.copyWith(
            backgroundColor: const WidgetStatePropertyAll(_brandOrange),
            foregroundColor: const WidgetStatePropertyAll(Colors.white),
            textStyle: const WidgetStatePropertyAll(
              TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(style: compactButtonStyle),
        textButtonTheme: TextButtonThemeData(
          style: compactButtonStyle.copyWith(
            minimumSize: const WidgetStatePropertyAll(Size(0, 38)),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size(40, 40),
            padding: const EdgeInsets.all(8),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: _compactDensity,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 11,
          ),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outlineVariant),
          ),
        ),
        listTileTheme: const ListTileThemeData(
          dense: true,
          minVerticalPadding: 4,
          contentPadding: EdgeInsets.symmetric(horizontal: 12),
        ),
        tabBarTheme: const TabBarThemeData(
          labelColor: _brandOrange,
          unselectedLabelColor: Colors.black54,
          indicatorColor: _brandOrange,
          labelStyle: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      home: const AppBootstrapScreen(),
    );
  }
}
