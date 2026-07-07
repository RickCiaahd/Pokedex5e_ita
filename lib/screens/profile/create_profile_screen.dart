import 'package:flutter/material.dart';

import '../../repositories/profile_repository.dart';
import '../../widgets/navigation/home_leading_button.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final ProfileRepository _profileRepository = ProfileRepository();
  final TextEditingController _nicknameController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci un nickname per continuare.')),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    final profile = await _profileRepository.createProfile(nickname);
    await _profileRepository.setActiveProfile(profile.id);

    if (!mounted) return;

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const HomeLeadingButton(),
        title: const Text('Crea profilo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_add_alt_1, size: 72),
                const SizedBox(height: 24),
                const Text(
                  'Benvenuto allenatore!',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Scegli un nickname per creare il tuo profilo.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Nickname',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _continue(),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isSaving ? null : _continue,
                    child: Text(_isSaving ? 'Creazione...' : 'Crea profilo'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
