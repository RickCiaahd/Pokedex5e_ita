import 'dart:async';

import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'localization/app_locale_controller.dart';
import 'localization/game_catalog_locale.dart';
import 'screens/onboarding/app_bootstrap_screen.dart';

class Pokedex5EApp extends StatefulWidget {
  const Pokedex5EApp({super.key, this.localeController});

  final AppLocaleController? localeController;

  @override
  State<Pokedex5EApp> createState() => _Pokedex5EAppState();
}

class _Pokedex5EAppState extends State<Pokedex5EApp> {
  static const Color _brandOrange = Color(0xFFF26A21);
  static const Color _appBackground = Color(0xFFF4F1EC);
  static const VisualDensity _compactDensity = VisualDensity(
    horizontal: -1,
    vertical: -1.5,
  );

  late final AppLocaleController _localeController;
  late final bool _ownsLocaleController;

  @override
  void initState() {
    super.initState();
    _ownsLocaleController = widget.localeController == null;
    _localeController = widget.localeController ?? AppLocaleController();
    if (_ownsLocaleController) {
      unawaited(_localeController.load());
    }
  }

  @override
  void dispose() {
    if (_ownsLocaleController) {
      _localeController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppLocaleScope(
      controller: _localeController,
      child: AnimatedBuilder(
        animation: _localeController,
        builder: (context, _) {
          final explicitLocale = _localeController.locale;
          if (explicitLocale != null) {
            GameCatalogLocale.setLanguageCode(explicitLocale.languageCode);
          }

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
            title: 'Trainer Atlas 5e',
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            locale: _localeController.locale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeResolutionCallback: (deviceLocale, supportedLocales) {
              final resolvedLocale = _localeController.resolveDeviceLocale(
                deviceLocale,
              );
              GameCatalogLocale.setLanguageCode(resolvedLocale.languageCode);
              return resolvedLocale;
            },
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
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: compactButtonStyle,
              ),
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
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
        },
      ),
    );
  }
}
