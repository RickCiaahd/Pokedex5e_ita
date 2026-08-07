import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'l10n/app_localizations.dart';
import 'localization/app_locale_controller.dart';
import 'localization/game_catalog_locale.dart';
import 'screens/onboarding/app_bootstrap_screen.dart';

const Color _brandOrange = Color(0xFFF26A21);
const Color _appBackground = Color(0xFFF4F1EC);
const VisualDensity _desktopCompactDensity = VisualDensity(
  horizontal: -1,
  vertical: -1.5,
);

bool _usesTouchLayout(TargetPlatform platform) {
  return switch (platform) {
    TargetPlatform.android ||
    TargetPlatform.iOS ||
    TargetPlatform.fuchsia => true,
    TargetPlatform.linux ||
    TargetPlatform.macOS ||
    TargetPlatform.windows => false,
  };
}

@visibleForTesting
ThemeData buildTrainerAtlasTheme({TargetPlatform? platform}) {
  final effectivePlatform = platform ?? defaultTargetPlatform;
  final touchLayout = _usesTouchLayout(effectivePlatform);
  final density = touchLayout ? VisualDensity.standard : _desktopCompactDensity;
  final tapTargetSize = touchLayout
      ? MaterialTapTargetSize.padded
      : MaterialTapTargetSize.shrinkWrap;
  final colorScheme = ColorScheme.fromSeed(
    seedColor: _brandOrange,
    brightness: Brightness.light,
  );

  final compactButtonStyle = ButtonStyle(
    minimumSize: WidgetStatePropertyAll(Size(0, touchLayout ? 48 : 42)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    ),
    visualDensity: density,
    tapTargetSize: tapTargetSize,
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );

  return ThemeData(
    platform: effectivePlatform,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: _appBackground,
    useMaterial3: true,
    visualDensity: density,
    materialTapTargetSize: tapTargetSize,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        minimumSize: WidgetStatePropertyAll(Size(0, touchLayout ? 48 : 38)),
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        minimumSize: Size.square(touchLayout ? 48 : 40),
        padding: const EdgeInsets.all(8),
        tapTargetSize: tapTargetSize,
        visualDensity: density,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      isDense: !touchLayout,
      contentPadding: EdgeInsets.symmetric(
        horizontal: 12,
        vertical: touchLayout ? 13 : 11,
      ),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant),
      ),
    ),
    listTileTheme: ListTileThemeData(
      dense: !touchLayout,
      minVerticalPadding: touchLayout ? 8 : 4,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    ),
    tabBarTheme: const TabBarThemeData(
      labelColor: _brandOrange,
      unselectedLabelColor: Colors.black54,
      indicatorColor: _brandOrange,
      labelStyle: TextStyle(fontWeight: FontWeight.w900),
    ),
  );
}

/// Rebuilds platform media information when Android changes its font scale.
///
/// Keeping this boundary explicit ensures every route receives the live
/// [TextScaler] exposed by the current Flutter view.
@visibleForTesting
Widget buildPlatformMediaQuery(BuildContext context, Widget? child) {
  return MediaQuery.fromView(
    view: View.of(context),
    child: child ?? const SizedBox.shrink(),
  );
}

class Pokedex5EApp extends StatefulWidget {
  const Pokedex5EApp({super.key, this.localeController});

  final AppLocaleController? localeController;

  @override
  State<Pokedex5EApp> createState() => _Pokedex5EAppState();
}

class _Pokedex5EAppState extends State<Pokedex5EApp> {
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
          final platformLocales =
              WidgetsBinding.instance.platformDispatcher.locales;
          final catalogLocale =
              explicitLocale ??
              _localeController.resolveDeviceLocales(platformLocales);
          GameCatalogLocale.setLanguageCode(catalogLocale.languageCode);

          return MaterialApp(
            title: 'Trainer Atlas 5e',
            onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
            debugShowCheckedModeBanner: false,
            locale: explicitLocale,
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            localeListResolutionCallback: (deviceLocales, supportedLocales) {
              final effectiveDeviceLocales =
                  deviceLocales ??
                  WidgetsBinding.instance.platformDispatcher.locales;
              final resolvedLocale = _localeController.resolveDeviceLocales(
                effectiveDeviceLocales,
              );
              GameCatalogLocale.setLanguageCode(resolvedLocale.languageCode);
              return resolvedLocale;
            },
            scrollBehavior: const MaterialScrollBehavior().copyWith(
              scrollbars: false,
            ),
            theme: buildTrainerAtlasTheme(),
            builder: buildPlatformMediaQuery,
            home: const AppBootstrapScreen(),
          );
        },
      ),
    );
  }
}
