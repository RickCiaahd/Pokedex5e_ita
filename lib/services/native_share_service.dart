import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:share_plus/share_plus.dart';

enum NativeShareOutcome { completed, dismissed, unavailable }

class NativeShareService {
  const NativeShareService();

  Future<NativeShareOutcome> shareTextFile({
    required BuildContext context,
    required String content,
    required String fileName,
    required String mimeType,
    required String title,
    String? subject,
    String? text,
  }) async {
    final renderBox = context.findRenderObject() as RenderBox?;
    final origin = renderBox != null && renderBox.hasSize
        ? renderBox.localToGlobal(Offset.zero) & renderBox.size
        : null;

    final result = await SharePlus.instance.share(
      ShareParams(
        title: title,
        subject: subject,
        text: text,
        files: [
          XFile.fromData(
            Uint8List.fromList(utf8.encode(content)),
            mimeType: mimeType,
          ),
        ],
        fileNameOverrides: [fileName],
        sharePositionOrigin: origin,
      ),
    );

    return switch (result.status) {
      ShareResultStatus.success => NativeShareOutcome.completed,
      ShareResultStatus.dismissed => NativeShareOutcome.dismissed,
      ShareResultStatus.unavailable => NativeShareOutcome.unavailable,
    };
  }

  String feedback(
    NativeShareOutcome outcome, {
    required String successMessage,
  }) {
    return switch (outcome) {
      NativeShareOutcome.completed => successMessage,
      NativeShareOutcome.dismissed => 'Condivisione annullata.',
      NativeShareOutcome.unavailable =>
        'Condivisione avviata. Il sistema non comunica l’esito finale.',
    };
  }
}
