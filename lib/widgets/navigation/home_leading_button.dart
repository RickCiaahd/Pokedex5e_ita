import 'package:flutter/material.dart';

/// Pulsante principale di navigazione delle schermate interne.
///
/// Torna di un solo livello, rispettando la gerarchia con cui la schermata è
/// stata aperta. Il nome della classe viene mantenuto per compatibilità con le
/// schermate esistenti.
class HomeLeadingButton extends StatelessWidget {
  const HomeLeadingButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Indietro',
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        final navigator = Navigator.of(context);
        if (navigator.canPop()) {
          navigator.pop();
        }
      },
    );
  }
}

/// Azione esplicita per tornare direttamente alla schermata iniziale.
class HomeAppBarAction extends StatelessWidget {
  const HomeAppBarAction({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Home',
      icon: const Icon(Icons.home_outlined),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    );
  }
}
