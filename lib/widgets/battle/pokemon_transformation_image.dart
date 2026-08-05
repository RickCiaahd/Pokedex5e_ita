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
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size * 0.9,
          height: size * 0.9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFE91E63).withValues(alpha: 0.5),
                blurRadius: size * 0.18,
                spreadRadius: size * 0.04,
              ),
            ],
          ),
        ),
        Transform.scale(
          scale: 1.075,
          child: ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Color(0xFFD71558),
              BlendMode.srcATop,
            ),
            child: Opacity(opacity: 0.78, child: child),
          ),
        ),
        child,
      ],
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
    final typeColor = _teraColor(type);
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
          border: Border.all(color: typeColor, width: 2),
          borderRadius: BorderRadius.circular(9),
          boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Icon(
              Icons.diamond_outlined,
              size: badgeSize * 0.88,
              color: typeColor,
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

Color _teraColor(String type) {
  return switch (type) {
    'Normal' => const Color(0xFF8A8A7B),
    'Fighting' => const Color(0xFFC73535),
    'Flying' => const Color(0xFF6F8FD9),
    'Poison' => const Color(0xFF9A45A6),
    'Ground' => const Color(0xFFC9904A),
    'Rock' => const Color(0xFF9C8740),
    'Bug' => const Color(0xFF8AAE20),
    'Ghost' => const Color(0xFF65549B),
    'Steel' => const Color(0xFF71828F),
    'Fire' => const Color(0xFFE85A2A),
    'Water' => const Color(0xFF3989D8),
    'Grass' => const Color(0xFF4B9E42),
    'Electric' => const Color(0xFFE0B71A),
    'Psychic' => const Color(0xFFE65387),
    'Ice' => const Color(0xFF57B9C9),
    'Dragon' => const Color(0xFF5B59C8),
    'Dark' => const Color(0xFF57443E),
    'Fairy' => const Color(0xFFD779A9),
    'Stellar' => const Color(0xFF8C6DC0),
    _ => const Color(0xFF607D8B),
  };
}
