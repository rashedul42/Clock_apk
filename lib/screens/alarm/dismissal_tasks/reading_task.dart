import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../../theme/app_theme.dart';
import 'task_base.dart';

/// Task 5: Speech / Reading. Displays [phrase] and requires the user to
/// read it aloud clearly. speech_to_text streams a live transcript; once
/// listening stops, we fuzzy-compare the recognized words against the
/// target phrase (normalized, punctuation-insensitive, allowing minor
/// recognition slips) and only call [onCompleted] above a match threshold.
class SpeechReadingTask extends StatefulWidget {
  final String phrase;
  final TaskCompletedCallback onCompleted;

  const SpeechReadingTask({
    super.key,
    required this.phrase,
    required this.onCompleted,
  });

  @override
  State<SpeechReadingTask> createState() => _SpeechReadingTaskState();
}

class _SpeechReadingTaskState extends State<SpeechReadingTask> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _available = false;
  bool _listening = false;
  String _transcript = '';
  double _matchScore = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'done' || status == 'notListening') {
          setState(() => _listening = false);
          _evaluate();
        }
      },
      onError: (_) => setState(() => _listening = false),
    );
    setState(() {});
  }

  void _startListening() {
    if (!_available) return;
    setState(() {
      _transcript = '';
      _matchScore = 0;
      _listening = true;
    });
    _speech.listen(
      onResult: (result) => setState(() => _transcript = result.recognizedWords),
      listenFor: const Duration(seconds: 20),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() {
    _speech.stop();
    setState(() => _listening = false);
    _evaluate();
  }

  List<String> _normalize(String s) => s
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), '')
      .split(RegExp(r'\s+'))
      .where((w) => w.isNotEmpty)
      .toList();

  void _evaluate() {
    if (_transcript.isEmpty) return;
    final target = _normalize(widget.phrase);
    final said = _normalize(_transcript).toSet();
    final matchedWords = target.where((w) => said.contains(w)).length;
    final score = target.isEmpty ? 0.0 : matchedWords / target.length;
    setState(() => _matchScore = score);
    // Require most of the target phrase's words to be recognized.
    if (score >= 0.8) {
      widget.onCompleted();
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TaskScaffold(
      emoji: '🗣️',
      title: 'Read Aloud to Dismiss',
      instructions: 'Read the sentence below clearly',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '"${widget.phrase}"',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontStyle: FontStyle.italic),
            ),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _listening ? _stopListening : _startListening,
            child: CircleAvatar(
              radius: 40,
              backgroundColor: _listening ? AppColors.danger : AppColors.accent,
              child: Icon(_listening ? Icons.stop : Icons.mic, color: Colors.white, size: 32),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _available
                ? (_listening ? 'Listening… tap to stop' : 'Tap the mic and start reading')
                : 'Speech recognition unavailable on this device',
            style: const TextStyle(color: Colors.white54),
          ),
          const SizedBox(height: 16),
          if (_transcript.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Heard: "$_transcript"',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white38, fontSize: 13),
              ),
            ),
          if (_matchScore > 0 && _matchScore < 0.8)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                'Not quite a match (${(_matchScore * 100).round()}%) — try again',
                style: const TextStyle(color: Colors.orangeAccent),
              ),
            ),
        ],
      ),
    );
  }
}
