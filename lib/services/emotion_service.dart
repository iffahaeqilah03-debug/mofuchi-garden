
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';

class EmotionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // SAVE A COMPLETE EMOTION CHECK-IN
  Future<String> saveCheckIn({
    required String mood,
    required int intensity,
    required String eventCategory,
    required String note,
    File? attachment,
    String? attachmentType,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      throw StateError('Please log in first.');
    }

    final emotion = mood.trim().toLowerCase();

    const positiveMoods = {'happy', 'surprise'};
    const negativeMoods = {
      'sad',
      'angry',
      'fear',
      'disgust',
    };

    if (!positiveMoods.contains(emotion) &&
        !negativeMoods.contains(emotion)) {
      throw ArgumentError('Invalid emotion: $emotion');
    }

    if (intensity < 1 || intensity > 5) {
      throw ArgumentError(
        'Intensity must be between 1 and 5.',
      );
    }

    if (eventCategory.trim().length > 100) {
      throw ArgumentError('Category is too long.');
    }

    if (note.trim().length > 2000) {
      throw ArgumentError('Reflection is too long.');
    }

    if (attachment == null && attachmentType != null) {
      throw ArgumentError('No attachment was selected.');
    }

    final document =
        _firestore.collection('emotion_logs').doc();

    String? localMediaPath;
    File? copiedFile;

    try {
      // SAVE PHOTO OR VIDEO LOCALLY
      if (attachment != null) {
        if (attachmentType != 'image' &&
            attachmentType != 'video') {
          throw ArgumentError(
            'Attachment must be an image or video.',
          );
        }

        if (!await attachment.exists()) {
          throw FileSystemException(
            'Attachment file not found.',
            attachment.path,
          );
        }

        final fileSize = await attachment.length();

        if (fileSize > 50 * 1024 * 1024) {
          throw ArgumentError(
            'Attachment must be smaller than 50 MB.',
          );
        }

        final appDirectory =
            await getApplicationDocumentsDirectory();

        final mediaDirectory = Directory(
          '${appDirectory.path}/mofuchi_media/${user.uid}',
        );

        await mediaDirectory.create(recursive: true);

        final originalExtension =
            attachment.path.split('.').last.toLowerCase();

        final validExtension =
            RegExp(r'^[a-z0-9]{1,5}$')
                    .hasMatch(originalExtension)
                ? originalExtension
                : attachmentType == 'image'
                    ? 'jpg'
                    : 'mp4';

        localMediaPath =
            'mofuchi_media/${user.uid}/${document.id}.$validExtension';

        copiedFile = await attachment.copy(
          '${appDirectory.path}/$localMediaPath',
        );
      }

      // DETERMINE POSITIVE OR NEGATIVE
      final category = positiveMoods.contains(emotion)
          ? 'positive'
          : 'negative';

      // SAVE EMOTION DATA TO FIRESTORE
      await document.set({
        'userId': user.uid,
        'emotion': emotion,
        'category': category,
        'intensity': intensity,
        'eventCategory': eventCategory.trim(),
        'shortThought': note.trim(),
        'attachmentType':
            localMediaPath == null ? null : attachmentType,
        'localMediaPath': localMediaPath,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return document.id;
    } catch (error) {
      // REMOVE LOCAL COPY IF DATABASE SAVE FAILED
      if (copiedFile != null) {
        try {
          if (await copiedFile.exists()) {
            await copiedFile.delete();
          }
        } catch (_) {
          // Preserve the original error.
        }
      }

      rethrow;
    }
  }

  // FIND A SAVED PHOTO OR VIDEO FOR HISTORY
  Future<File?> localAttachment(
    Map<String, dynamic> entry,
  ) async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final storedPath = entry['localMediaPath'];

    if (storedPath is! String) {
      return null;
    }

    final expectedPrefix =
        'mofuchi_media/${user.uid}/';

    if (!storedPath.startsWith(expectedPrefix)) {
      return null;
    }

    final fileName =
        storedPath.substring(expectedPrefix.length);

    if (!RegExp(r'^[A-Za-z0-9_-]+\.[a-z0-9]{1,5}$')
        .hasMatch(fileName)) {
      return null;
    }

    final appDirectory =
        await getApplicationDocumentsDirectory();

    final file = File(
      '${appDirectory.path}/$storedPath',
    );

    if (await file.exists()) {
      return file;
    }

    return null;
  }
}
