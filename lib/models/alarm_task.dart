/// The five supported "Dismissal Task Types" for the Task-Based Alarm
/// Dismissal System. An alarm CANNOT be silenced through a normal
/// stop/slide action — the ringing alarm forces the user into
/// AlarmRingScreen ("Alarm Challenge Screen"), which mounts the task
/// widget matching this enum and only calls AlarmProvider.dismiss()
/// once that widget reports success.
enum AlarmTaskType {
  math,             // Randomized arithmetic challenges (e.g. 23 x 4 + 15)
  fitness,          // Push-ups / Squats via accelerometer rep counting (or camera count)
  imageRecognition, // Photograph a specific target object/nature scene
  qrScan,           // Scan a pre-configured QR code / barcode in another room
  speechReading,    // Read a phrase aloud, verified via Speech-to-Text
}

extension AlarmTaskTypeX on AlarmTaskType {
  String get label {
    switch (this) {
      case AlarmTaskType.math:
        return 'Math Challenge';
      case AlarmTaskType.fitness:
        return 'Fitness Task';
      case AlarmTaskType.imageRecognition:
        return 'Image Recognition';
      case AlarmTaskType.qrScan:
        return 'QR / Barcode Scan';
      case AlarmTaskType.speechReading:
        return 'Speech Reading';
    }
  }

  String get description {
    switch (this) {
      case AlarmTaskType.math:
        return 'Solve randomized math problems to dismiss';
      case AlarmTaskType.fitness:
        return 'Complete push-ups or squats, counted live';
      case AlarmTaskType.imageRecognition:
        return 'Take a photo of a specific target object';
      case AlarmTaskType.qrScan:
        return 'Scan a QR code placed in another room';
      case AlarmTaskType.speechReading:
        return 'Read a phrase aloud, verified by speech-to-text';
    }
  }

  String get icon {
    switch (this) {
      case AlarmTaskType.math:
        return '➗';
      case AlarmTaskType.fitness:
        return '🏋️';
      case AlarmTaskType.imageRecognition:
        return '📷';
      case AlarmTaskType.qrScan:
        return '🔳';
      case AlarmTaskType.speechReading:
        return '🗣️';
    }
  }
}

enum FitnessExercise { pushups, squats }
enum FitnessDetectionMode { accelerometer, camera }

/// Per-task tunable difficulty/settings, persisted alongside the Alarm.
/// `taskType == null` means "no task" (classic slide-to-dismiss).
class AlarmTaskConfig {
  final AlarmTaskType? taskType;

  // --- Math ---
  final int mathProblemCount; // how many correct answers required
  final int mathDifficulty; // 1 easy .. 3 hard (controls operand size / operators used)

  // --- Fitness ---
  final FitnessExercise exercise;
  final int repsRequired; // 10-20 typical
  final FitnessDetectionMode detectionMode;

  // --- Image recognition ---
  final String targetObjectLabel; // e.g. "coffee mug", "green plant"

  // --- QR / barcode ---
  final String? qrPayload; // expected code content, pre-registered by the user

  // --- Speech reading ---
  final String readingPhrase;

  const AlarmTaskConfig({
    this.taskType,
    this.mathProblemCount = 3,
    this.mathDifficulty = 1,
    this.exercise = FitnessExercise.pushups,
    this.repsRequired = 10,
    this.detectionMode = FitnessDetectionMode.accelerometer,
    this.targetObjectLabel = 'coffee mug',
    this.qrPayload,
    this.readingPhrase = 'The early bird catches the worm and greets the sun.',
  });

  bool get hasTask => taskType != null;

  AlarmTaskConfig copyWith({
    AlarmTaskType? taskType,
    bool clearTaskType = false,
    int? mathProblemCount,
    int? mathDifficulty,
    FitnessExercise? exercise,
    int? repsRequired,
    FitnessDetectionMode? detectionMode,
    String? targetObjectLabel,
    String? qrPayload,
    String? readingPhrase,
  }) {
    return AlarmTaskConfig(
      taskType: clearTaskType ? null : (taskType ?? this.taskType),
      mathProblemCount: mathProblemCount ?? this.mathProblemCount,
      mathDifficulty: mathDifficulty ?? this.mathDifficulty,
      exercise: exercise ?? this.exercise,
      repsRequired: repsRequired ?? this.repsRequired,
      detectionMode: detectionMode ?? this.detectionMode,
      targetObjectLabel: targetObjectLabel ?? this.targetObjectLabel,
      qrPayload: qrPayload ?? this.qrPayload,
      readingPhrase: readingPhrase ?? this.readingPhrase,
    );
  }

  Map<String, dynamic> toJson() => {
        'taskType': taskType?.name,
        'mathProblemCount': mathProblemCount,
        'mathDifficulty': mathDifficulty,
        'exercise': exercise.name,
        'repsRequired': repsRequired,
        'detectionMode': detectionMode.name,
        'targetObjectLabel': targetObjectLabel,
        'qrPayload': qrPayload,
        'readingPhrase': readingPhrase,
      };

  factory AlarmTaskConfig.fromJson(Map<String, dynamic> json) {
    return AlarmTaskConfig(
      taskType: json['taskType'] == null
          ? null
          : AlarmTaskType.values.firstWhere((e) => e.name == json['taskType']),
      mathProblemCount: json['mathProblemCount'] ?? 3,
      mathDifficulty: json['mathDifficulty'] ?? 1,
      exercise: FitnessExercise.values.firstWhere(
        (e) => e.name == json['exercise'],
        orElse: () => FitnessExercise.pushups,
      ),
      repsRequired: json['repsRequired'] ?? 10,
      detectionMode: FitnessDetectionMode.values.firstWhere(
        (e) => e.name == json['detectionMode'],
        orElse: () => FitnessDetectionMode.accelerometer,
      ),
      targetObjectLabel: json['targetObjectLabel'] ?? 'coffee mug',
      qrPayload: json['qrPayload'],
      readingPhrase: json['readingPhrase'] ??
          'The early bird catches the worm and greets the sun.',
    );
  }
}
