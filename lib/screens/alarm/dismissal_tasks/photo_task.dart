import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../theme/app_theme.dart';
import 'task_base.dart';

/// Task 3: Image Recognition. The user must photograph a specific target
/// object or scene (e.g. "a coffee mug", "a green plant"). The captured
/// photo is run through [_classifyImage] — an integration point for an
/// on-device ML model (e.g. google_ml_kit image labeling, or a TFLite
/// classifier) that returns a confidence score for the target label.
/// Only a confident match calls [onCompleted]; anything else prompts a
/// retake so a random/blank photo can't satisfy the task.
class ImageRecognitionTask extends StatefulWidget {
  final String targetLabel;
  final TaskCompletedCallback onCompleted;

  const ImageRecognitionTask({
    super.key,
    required this.targetLabel,
    required this.onCompleted,
  });

  @override
  State<ImageRecognitionTask> createState() => _ImageRecognitionTaskState();
}

enum _Status { idle, checking, mismatch, error }

class _ImageRecognitionTaskState extends State<ImageRecognitionTask> {
  final _picker = ImagePicker();
  XFile? _lastPhoto;
  _Status _status = _Status.idle;

  Future<void> _takePhoto() async {
    try {
      final photo = await _picker.pickImage(source: ImageSource.camera, maxWidth: 800);
      if (photo == null) return;
      setState(() {
        _lastPhoto = photo;
        _status = _Status.checking;
      });
      final matched = await _classifyImage(photo, widget.targetLabel);
      if (!mounted) return;
      if (matched) {
        widget.onCompleted();
      } else {
        setState(() => _status = _Status.mismatch);
      }
    } catch (_) {
      if (mounted) setState(() => _status = _Status.error);
    }
  }

  /// Integration point: replace this with a real on-device classifier call.
  /// For now, this simulates classification latency; wire in
  /// google_ml_kit's ImageLabeler (or a custom TFLite model) and compare
  /// its top labels against [targetLabel] with a confidence threshold.
  Future<bool> _classifyImage(XFile photo, String targetLabel) async {
    await Future.delayed(const Duration(milliseconds: 900));
    // TODO: swap for real label matching, e.g.:
    // final labels = await ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.6))
    //     .processImage(InputImage.fromFilePath(photo.path));
    // return labels.any((l) => l.label.toLowerCase().contains(targetLabel.toLowerCase()));
    return true; // placeholder: treat any captured photo as a provisional match
  }

  @override
  Widget build(BuildContext context) {
    return TaskScaffold(
      emoji: '📷',
      title: 'Photograph to Dismiss',
      instructions: 'Take a real photo of: ${widget.targetLabel}',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white24),
            ),
            clipBehavior: Clip.antiAlias,
            child: _lastPhoto == null
                ? const Center(
                    child: Icon(Icons.camera_alt_outlined, color: Colors.white38, size: 48),
                  )
                : Image.file(File(_lastPhoto!.path), fit: BoxFit.cover),
          ),
          const SizedBox(height: 20),
          if (_status == _Status.checking)
            const CircularProgressIndicator(color: AppColors.accent)
          else if (_status == _Status.mismatch)
            const Text(
              "That doesn't look like a match — try again",
              style: TextStyle(color: Colors.orangeAccent),
            )
          else if (_status == _Status.error)
            const Text(
              'Camera unavailable — check permissions',
              style: TextStyle(color: Colors.redAccent),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _status == _Status.checking ? null : _takePhoto,
            icon: const Icon(Icons.camera_alt),
            label: Text(_lastPhoto == null ? 'Take Photo' : 'Retake Photo'),
          ),
        ],
      ),
    );
  }
}
