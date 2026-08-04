import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';

enum ProfileImageFailure { missingData, tooLarge, unsupportedFormat }

class ProfileImageSelectionException implements Exception {
  const ProfileImageSelectionException(this.failure);

  final ProfileImageFailure failure;
}

class ProfileImageService {
  static const int maxSourceBytes = 20 * 1024 * 1024;
  static const int maxDimension = 512;
  static const int maxStoredBase64Length = 4 * 1024 * 1024;

  Future<String?> pickProfileImage({String? dialogTitle}) async {
    final result = await FilePicker.platform.pickFiles(
      dialogTitle: dialogTitle,
      type: FileType.custom,
      allowedExtensions: const ['png', 'jpg', 'jpeg', 'webp'],
      allowMultiple: false,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return null;

    final bytes = result.files.single.bytes;
    if (bytes == null || bytes.isEmpty) {
      throw const ProfileImageSelectionException(
        ProfileImageFailure.missingData,
      );
    }
    if (bytes.length > maxSourceBytes) {
      throw const ProfileImageSelectionException(ProfileImageFailure.tooLarge);
    }

    try {
      final normalized = await normalizeImage(bytes);
      final encoded = base64Encode(normalized);
      if (encoded.length > maxStoredBase64Length) {
        throw const ProfileImageSelectionException(
          ProfileImageFailure.tooLarge,
        );
      }
      return encoded;
    } on ProfileImageSelectionException {
      rethrow;
    } catch (_) {
      throw const ProfileImageSelectionException(
        ProfileImageFailure.unsupportedFormat,
      );
    }
  }

  Future<Uint8List> normalizeImage(Uint8List source) async {
    ui.Codec? sourceCodec;
    ui.FrameInfo? sourceFrame;
    ui.Codec? resizedCodec;
    ui.FrameInfo? resizedFrame;

    try {
      sourceCodec = await ui.instantiateImageCodec(source);
      sourceFrame = await sourceCodec.getNextFrame();

      final width = sourceFrame.image.width;
      final height = sourceFrame.image.height;
      if (width <= 0 || height <= 0) {
        throw const ProfileImageSelectionException(
          ProfileImageFailure.unsupportedFormat,
        );
      }

      final scale = maxDimension / (width > height ? width : height);
      final targetWidth = scale < 1 ? (width * scale).round() : width;
      final targetHeight = scale < 1 ? (height * scale).round() : height;

      resizedCodec = await ui.instantiateImageCodec(
        source,
        targetWidth: targetWidth,
        targetHeight: targetHeight,
      );
      resizedFrame = await resizedCodec.getNextFrame();
      final data = await resizedFrame.image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (data == null) {
        throw const ProfileImageSelectionException(
          ProfileImageFailure.unsupportedFormat,
        );
      }
      return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    } finally {
      resizedFrame?.image.dispose();
      resizedCodec?.dispose();
      sourceFrame?.image.dispose();
      sourceCodec?.dispose();
    }
  }

  static Uint8List? tryDecode(String encoded) {
    if (encoded.trim().isEmpty || encoded.length > maxStoredBase64Length) {
      return null;
    }
    try {
      return base64Decode(encoded);
    } catch (_) {
      return null;
    }
  }
}
