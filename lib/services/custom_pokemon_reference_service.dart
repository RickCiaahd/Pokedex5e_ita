import '../models/profile_backup.dart';
import '../repositories/profile_repository.dart';
import 'profile_backup_service.dart';

class CustomPokemonReference {
  const CustomPokemonReference({
    required this.profileName,
    required this.location,
    required this.detail,
  });

  final String profileName;
  final String location;
  final String detail;

  String get displayText => '$profileName · $location: $detail';
}

class CustomPokemonReferenceReport {
  const CustomPokemonReferenceReport({
    required this.pokemonId,
    required this.references,
  });

  final int pokemonId;
  final List<CustomPokemonReference> references;

  bool get isInUse => references.isNotEmpty;
}

class CustomPokemonReferenceService {
  CustomPokemonReferenceService({
    ProfileRepository? profileRepository,
    ProfileBackupService? backupService,
  }) : _profileRepository = profileRepository ?? ProfileRepository(),
       _backupService = backupService ?? ProfileBackupService();

  final ProfileRepository _profileRepository;
  final ProfileBackupService _backupService;

  Future<CustomPokemonReferenceReport> findReferences(int pokemonId) async {
    final profiles = await _profileRepository.getProfiles();
    final references = <CustomPokemonReference>[];

    for (final profile in profiles) {
      final backup = await _backupService.createBackup(profile.id);
      _collectFromBackup(
        backup,
        pokemonId: pokemonId,
        profileName: profile.name,
        references: references,
      );
    }

    references.sort((a, b) {
      final profileCompare = a.profileName.toLowerCase().compareTo(
        b.profileName.toLowerCase(),
      );
      if (profileCompare != 0) return profileCompare;
      final locationCompare = a.location.compareTo(b.location);
      return locationCompare != 0
          ? locationCompare
          : a.detail.compareTo(b.detail);
    });

    return CustomPokemonReferenceReport(
      pokemonId: pokemonId,
      references: List<CustomPokemonReference>.unmodifiable(references),
    );
  }

  void _collectFromBackup(
    ProfileBackup backup, {
    required int pokemonId,
    required String profileName,
    required List<CustomPokemonReference> references,
  }) {
    for (final slot in backup.team) {
      if (slot.pokemonId == pokemonId) {
        references.add(
          CustomPokemonReference(
            profileName: profileName,
            location: 'Squadra',
            detail: 'slot ${slot.slotIndex + 1}${_nickname(slot.nickname)}',
          ),
        );
      }
    }

    for (final pokemon in backup.pc) {
      if (pokemon.pokemonId == pokemonId) {
        references.add(
          CustomPokemonReference(
            profileName: profileName,
            location: 'PC',
            detail: pokemon.nickname?.trim().isNotEmpty == true
                ? pokemon.nickname!.trim()
                : 'esemplare ${pokemon.id}',
          ),
        );
      }
    }

    if (backup.pokedex.any(
      (entry) =>
          entry.pokemonId == pokemonId &&
          (entry.seen || entry.caught || entry.forms.isNotEmpty),
    )) {
      references.add(
        CustomPokemonReference(
          profileName: profileName,
          location: 'Pokédex',
          detail: 'voce registrata',
        ),
      );
    }

    for (final collection in backup.encounterCollections) {
      if (collection.entries.any((entry) => entry.pokemonId == pokemonId)) {
        references.add(
          CustomPokemonReference(
            profileName: profileName,
            location: 'Raccolta incontri',
            detail: collection.name,
          ),
        );
      }
    }

    for (final encounter in backup.savedEncounters) {
      final count = encounter.members
          .where((member) => member.pokemonId == pokemonId)
          .length;
      if (count > 0) {
        references.add(
          CustomPokemonReference(
            profileName: profileName,
            location: 'Incontro',
            detail:
                '${encounter.name} · $count esemplar${count == 1 ? 'e' : 'i'}',
          ),
        );
      }
    }

    for (final trainer in backup.savedNpcTrainers) {
      final count = trainer.team
          .where((member) => member.pokemonId == pokemonId)
          .length;
      if (count > 0) {
        references.add(
          CustomPokemonReference(
            profileName: profileName,
            location: 'Allenatore PNG',
            detail:
                '${trainer.name} · $count esemplar${count == 1 ? 'e' : 'i'}',
          ),
        );
      }
    }

    final battleSession = backup.battleSession;
    if (battleSession != null &&
        battleSession.pokemonStates.values.any(
          (state) => state.pokemonId == pokemonId,
        )) {
      references.add(
        CustomPokemonReference(
          profileName: profileName,
          location: 'Battle Companion',
          detail: 'sessione salvata',
        ),
      );
    }

    final masterSession = backup.masterBattleSession;
    if (masterSession != null) {
      for (final participant in masterSession.participants) {
        final count = participant.team
            .where((state) => state.pokemon.pokemonId == pokemonId)
            .length;
        if (count > 0) {
          references.add(
            CustomPokemonReference(
              profileName: profileName,
              location: 'Fight del Master',
              detail:
                  '${participant.displayName} · $count esemplar${count == 1 ? 'e' : 'i'}',
            ),
          );
        }
      }
    }

    for (final egg in backup.breedingEggs) {
      if (egg.speciesId == pokemonId) {
        references.add(
          CustomPokemonReference(
            profileName: profileName,
            location: 'Allevamento',
            detail: egg.isReady
                ? 'uovo pronto alla schiusa'
                : 'uovo in incubazione',
          ),
        );
      }
    }
  }

  String _nickname(String? value) {
    final nickname = value?.trim() ?? '';
    return nickname.isEmpty ? '' : ' · $nickname';
  }
}
