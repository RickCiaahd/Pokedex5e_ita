import 'package:flutter/material.dart';

class EggAssetImage extends StatelessWidget {
  const EggAssetImage({
    super.key,
    this.size = 64,
    this.fit = BoxFit.contain,
    this.fallback,
  });

  static const String assetPath = 'assets/textures/sprites/egg.png';
  static const String semanticLabel = 'Uovo Pokémon';

  final double size;
  final BoxFit fit;
  final Widget? fallback;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: fit,
      filterQuality: FilterQuality.none,
      semanticLabel: semanticLabel,
      errorBuilder: (context, error, stackTrace) => SizedBox.square(
        dimension: size,
        child: Center(child: fallback ?? const Icon(Icons.egg_alt_outlined)),
      ),
    );
  }
}
