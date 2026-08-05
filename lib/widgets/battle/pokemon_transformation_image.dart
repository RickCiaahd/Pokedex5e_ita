import 'package:flutter/material.dart';

import '../../models/battle_transformation.dart';
import '../../models/pokemon.dart';
import '../../services/pokemon_transform_asset_catalog.dart';
import '../pokemon/pokemon_asset_image.dart';

class PokemonTransformationImage extends StatelessWidget {
  const PokemonTransformationImage({
    super.key,
    required this.pokemon,
    required this.size,
    required this.transformation,
    this.formName,
    this.gender,
    this.isShiny = false,
    this.useLargeArtwork = false,
  });

  final Pokemon pokemon;
  final double size;
  final BattleTransformationState? transformation;
  final String? formName;
  final String? gender;
  final bool isShiny;
  final bool useLargeArtwork;

  @override
  Widget build(BuildContext context) {
    final state = transformation;
    final art = state?.formIdentifier == null
        ? null
        : PokemonTransformAssetCatalog.byIdentifier(state!.formIdentifier!);

    Widget coreImage() {
      final fallback = PokemonAssetImage(
        pokemon: pokemon,
        size: size,
        useLargeArtwork: useLargeArtwork,
        formName: formName,
        gender: gender,
        isShiny: isShiny,
      );
      if (art == null) return fallback;
      return Image.asset(
        art.assetPath(shiny: isShiny),
        width: size,
        height: size,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, _, _) => fallback,
      );
    }

    Widget image = coreImage();
    if (state?.isDynamaxLike == true) {
      image = _DynamaxAura(size: size, child: image);
    }

    if (state?.kind == BattleTransformationKind.terastal &&
        state?.teraType != null) {
      image = Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          image,
          Positioned(
            right: 0,
            bottom: 0,
            child: _TeraBadge(type: state!.teraType!, size: size),
          ),
        ],
      );
    }

    return SizedBox(width: size, height: size, child: image);
  }
}

class _DynamaxAura extends StatelessWidget {
  const _DynamaxAura({required this.size, required this.child});

  final double size;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFD71558).withValues(alpha: 0.72),
          width: size >= 80 ? 3 : 2,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE91E63).withValues(alpha: 0.52),
            blurRadius: size * 0.16,
            spreadRadius: size * 0.035,
          ),
          BoxShadow(
            color: const Color(0xFF8E0038).withValues(alpha: 0.34),
            blurRadius: size * 0.08,
            spreadRadius: size * 0.015,
          ),
        ],
      ),
      child: Padding(padding: EdgeInsets.all(size * 0.035), child: child),
    );
  }
}

class _TeraBadge extends StatelessWidget {
  const _TeraBadge({required this.type, required this.size});

  final String type;
  final double size;

  @override
  Widget build(BuildContext context) {
    final badgeSize = size >= 80 ? 34.0 : 24.0;
    final shortLabel = type == 'Stellar'
        ? '★'
        : type.substring(0, type.length < 3 ? type.length : 3).toUpperCase();
    return Tooltip(
      message: 'Teracristal · $type',
      child: Container(
        width: badgeSize,
        height: badgeSize,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
          border: Border.all(color: Theme.of(context).colorScheme.primary),
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.diamond_outlined,
              size: badgeSize * 0.88,
              color: Theme.of(context).colorScheme.primary,
            ),
            Text(
              shortLabel,
              style: TextStyle(
                fontSize: badgeSize * 0.24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
