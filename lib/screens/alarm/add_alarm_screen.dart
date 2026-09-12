import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alarm.dart';
import '../../models/alarm_task.dart';
import '../../providers/alarm_provider.dart';
import '../../theme/app_theme.dart';

/// Add/Edit Alarm screen. Mirrors reference screenshots 1 & 2: a scrollable
/// time wheel up top, then a settings list (Repeat, Sound, Label, Snooze,
/// Vibrate, Delete after ringing) — extended here with the "Dismissal Task"
/// row that opens the task picker for the Task-Based Alarm Dismissal System.
class AddAlarmScreen extends StatefulWidget {
  final Alarm? existing;
  const AddAlarmScreen({super.key, this.existing});

  @override
  State<AddAlarmScreen> createState() => _AddAlarmScreenState();
}

class _AddAlarmScreenState extends State<AddAlarmScreen> {
  late TimeOfDay _time;
  late List<bool> _repeatDays;
  late String _label;
  late String _sound;
  late int _snoozeMinutes;
  late bool _vibrate;
  late bool _deleteAfterRinging;
  late AlarmTaskConfig _taskConfig;

  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _time = e?.time ?? TimeOfDay.now();
    _repeatDays = List.of(e?.repeatDays ?? List.filled(7, false));
    _label = e?.label ?? '';
    _sound = e?.soundName ?? 'Default Chime';
    _snoozeMinutes = e?.snoozeMinutes ?? 10;
    _vibrate = e?.vibrate ?? true;
    _deleteAfterRinging = e?.deleteAfterRinging ?? false;
    _taskConfig = e?.taskConfig ?? const AlarmTaskConfig();
  }

  void _save() {
    final provider = context.read<AlarmProvider>();
    final alarm = Alarm(
      id: widget.existing?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      time: _time,
      repeatDays: _repeatDays,
      label: _label,
      soundName: _sound,
      snoozeMinutes: _snoozeMinutes,
      vibrate: _vibrate,
      deleteAfterRinging: _deleteAfterRinging,
      taskConfig: _taskConfig,
    );
    widget.existing == null ? provider.addAlarm(alarm) : provider.updateAlarm(alarm);
    Navigator.of(context).pop();
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  Future<void> _openTaskPicker() async {
    final result = await Navigator.of(context).push<AlarmTaskConfig>(
      MaterialPageRoute(builder: (_) => TaskPickerScreen(initial: _taskConfig)),
    );
    if (result != null) setState(() => _taskConfig = result);
  }

  Future<void> _openSnoozeModal() async {
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (context) => _SnoozeModal(current: _snoozeMinutes),
    );
    if (result != null) setState(() => _snoozeMinutes = result);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.existing == null ? 'Add Alarm' : 'Edit Alarm'),
        actions: [
          if (widget.existing != null)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger),
              onPressed: () {
                context.read<AlarmProvider>().deleteAlarm(widget.existing!.id);
                Navigator.of(context).pop();
              },
            ),
          TextButton(onPressed: _save, child: const Text('Save')),
        ],
      ),
      body: ListView(
        children: [
          // ---- Time wheel selector ----
          GestureDetector(
            onTap: _pickTime,
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 28),
              alignment: Alignment.center,
              child: Text(
                _time.format(context),
                style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),

          _SectionCard(children: [
            _NavRow(
              title: 'Repeat',
              value: _repeatSummary(),
              onTap: () async {
                final result = await showModalBottomSheet<List<bool>>(
                  context: context,
                  builder: (_) => _RepeatDaysModal(initial: _repeatDays),
                );
                if (result != null) setState(() => _repeatDays = result);
              },
            ),
            const Divider(height: 1),
            _NavRow(
              title: 'Alarm Sound',
              value: _sound,
              onTap: () async {
                final result = await showModalBottomSheet<String>(
                  context: context,
                  builder: (_) => _SoundModal(current: _sound),
                );
                if (result != null) setState(() => _sound = result);
              },
            ),
            const Divider(height: 1),
            _NavRow(
              title: 'Label',
              value: _label.isEmpty ? 'None' : _label,
              onTap: () async {
                final controller = TextEditingController(text: _label);
                final result = await showDialog<String>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Label'),
                    content: TextField(controller: controller, autofocus: true),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, controller.text),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
                if (result != null) setState(() => _label = result);
              },
            ),
            const Divider(height: 1),
            _NavRow(
              title: 'Snooze',
              value: _snoozeMinutes == 0 ? 'Off' : '$_snoozeMinutes min',
              onTap: _openSnoozeModal,
            ),
          ]),

          const SizedBox(height: 16),

          // ---- Task-Based Alarm Dismissal System entry point ----
          _SectionCard(children: [
            _NavRow(
              title: 'Dismissal Task',
              value: _taskConfig.hasTask ? _taskConfig.taskType!.label : 'None (slide to dismiss)',
              subtitle: _taskConfig.hasTask ? _taskConfig.taskType!.description : null,
              icon: _taskConfig.hasTask ? _taskConfig.taskType!.icon : null,
              onTap: _openTaskPicker,
            ),
          ]),

          const SizedBox(height: 16),

          _SectionCard(children: [
            SwitchListTile(
              title: const Text('Delete after ringing'),
              value: _deleteAfterRinging,
              onChanged: (v) => setState(() => _deleteAfterRinging = v),
            ),
            const Divider(height: 1),
            SwitchListTile(
              title: const Text('Vibrate'),
              value: _vibrate,
              onChanged: (v) => setState(() => _vibrate = v),
            ),
          ]),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  String _repeatSummary() {
    if (!_repeatDays.any((d) => d)) return 'Once';
    if (_repeatDays.every((d) => d)) return 'Every day';
    return [for (int i = 0; i < 7; i++) if (_repeatDays[i]) _dayNames[i]].join(', ');
  }
}

// ---------------------------------------------------------------------
// Shared small building blocks
// ---------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _NavRow extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final String? icon;
  final VoidCallback onTap;

  const _NavRow({
    required this.title,
    required this.value,
    required this.onTap,
    this.subtitle,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!, style: const TextStyle(fontSize: 12)) : null,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) Padding(padding: const EdgeInsets.only(right: 6), child: Text(icon!)),
          Text(value, style: const TextStyle(color: AppColors.textSecondary)),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
        ],
      ),
      onTap: onTap,
    );
  }
}

class _RepeatDaysModal extends StatefulWidget {
  final List<bool> initial;
  const _RepeatDaysModal({required this.initial});

  @override
  State<_RepeatDaysModal> createState() => _RepeatDaysModalState();
}

class _RepeatDaysModalState extends State<_RepeatDaysModal> {
  late List<bool> _days;
  static const _names = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    _days = List.of(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (int i = 0; i < 7; i++)
            CheckboxListTile(
              title: Text(_names[i]),
              value: _days[i],
              onChanged: (v) => setState(() => _days[i] = v ?? false),
            ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context, _days),
                child: const Text('Done'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoundModal extends StatelessWidget {
  final String current;
  const _SoundModal({required this.current});

  static const _sounds = ['Default Chime', 'Gentle Wake', 'Classic Bell', 'Digital Beep', 'Nature Birds'];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final sound in _sounds)
            RadioListTile<String>(
              title: Text(sound),
              value: sound,
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
            ),
        ],
      ),
    );
  }
}

class _SnoozeModal extends StatelessWidget {
  final int current;
  const _SnoozeModal({required this.current});

  static const _options = [0, 5, 10, 15, 20, 30];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Snooze Duration', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          ),
          for (final option in _options)
            RadioListTile<int>(
              title: Text(option == 0 ? 'Off' : '$option minutes'),
              value: option,
              groupValue: current,
              onChanged: (v) => Navigator.pop(context, v),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Dismissal Task picker — the settings surface for the Task-Based
// Alarm Dismissal System. Choosing a task type reveals that task's
// specific difficulty/settings fields.
// ---------------------------------------------------------------------

class TaskPickerScreen extends StatefulWidget {
  final AlarmTaskConfig initial;
  const TaskPickerScreen({super.key, required this.initial});

  @override
  State<TaskPickerScreen> createState() => _TaskPickerScreenState();
}

class _TaskPickerScreenState extends State<TaskPickerScreen> {
  late AlarmTaskConfig _config;

  @override
  void initState() {
    super.initState();
    _config = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dismissal Task'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, _config),
            child: const Text('Done'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _TaskOptionTile(
            emoji: '🚫',
            title: 'None',
            subtitle: 'Slide to dismiss like a normal alarm',
            selected: !_config.hasTask,
            onTap: () => setState(() => _config = _config.copyWith(clearTaskType: true)),
          ),
          for (final type in AlarmTaskType.values)
            _TaskOptionTile(
              emoji: type.icon,
              title: type.label,
              subtitle: type.description,
              selected: _config.taskType == type,
              onTap: () => setState(() => _config = _config.copyWith(taskType: type)),
            ),
          if (_config.hasTask) ...[
            const SizedBox(height: 8),
            _TaskSettingsPanel(
              config: _config,
              onChanged: (c) => setState(() => _config = c),
            ),
          ],
        ],
      ),
    );
  }
}

class _TaskOptionTile extends StatelessWidget {
  final String emoji;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TaskOptionTile({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      color: selected ? AppColors.accentSoft : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: selected ? AppColors.accent : AppColors.border),
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 24)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: selected ? const Icon(Icons.check_circle_rounded, color: AppColors.accent) : null,
        onTap: onTap,
      ),
    );
  }
}

/// Difficulty/settings fields specific to whichever AlarmTaskType is
/// currently selected.
class _TaskSettingsPanel extends StatelessWidget {
  final AlarmTaskConfig config;
  final ValueChanged<AlarmTaskConfig> onChanged;

  const _TaskSettingsPanel({required this.config, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    switch (config.taskType!) {
      case AlarmTaskType.math:
        return _SectionCard(children: [
          ListTile(
            title: const Text('Problems to solve'),
            trailing: _Stepper(
              value: config.mathProblemCount,
              min: 1,
              max: 10,
              onChanged: (v) => onChanged(config.copyWith(mathProblemCount: v)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Difficulty'),
            trailing: _Stepper(
              value: config.mathDifficulty,
              min: 1,
              max: 3,
              onChanged: (v) => onChanged(config.copyWith(mathDifficulty: v)),
            ),
          ),
        ]);
      case AlarmTaskType.fitness:
        return _SectionCard(children: [
          ListTile(
            title: const Text('Exercise'),
            trailing: DropdownButton<FitnessExercise>(
              value: config.exercise,
              items: const [
                DropdownMenuItem(value: FitnessExercise.pushups, child: Text('Push-ups')),
                DropdownMenuItem(value: FitnessExercise.squats, child: Text('Squats')),
              ],
              onChanged: (v) => onChanged(config.copyWith(exercise: v)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Reps required'),
            trailing: _Stepper(
              value: config.repsRequired,
              min: 5,
              max: 30,
              step: 5,
              onChanged: (v) => onChanged(config.copyWith(repsRequired: v)),
            ),
          ),
          const Divider(height: 1),
          ListTile(
            title: const Text('Detection'),
            trailing: DropdownButton<FitnessDetectionMode>(
              value: config.detectionMode,
              items: const [
                DropdownMenuItem(value: FitnessDetectionMode.accelerometer, child: Text('Motion sensor')),
                DropdownMenuItem(value: FitnessDetectionMode.camera, child: Text('Camera')),
              ],
              onChanged: (v) => onChanged(config.copyWith(detectionMode: v)),
            ),
          ),
        ]);
      case AlarmTaskType.imageRecognition:
        return _SectionCard(children: [
          ListTile(
            title: const Text('Target object / scene'),
            subtitle: Text(config.targetObjectLabel),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () async {
              final controller = TextEditingController(text: config.targetObjectLabel);
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Target Object'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'e.g. coffee mug, green plant'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
                  ],
                ),
              );
              if (result != null && result.trim().isNotEmpty) {
                onChanged(config.copyWith(targetObjectLabel: result.trim()));
              }
            },
          ),
        ]);
      case AlarmTaskType.qrScan:
        return _SectionCard(children: [
          ListTile(
            title: const Text('Registered code'),
            subtitle: Text(config.qrPayload?.isNotEmpty == true ? config.qrPayload! : 'Not set — scan one now'),
            trailing: const Icon(Icons.qr_code_scanner_rounded),
            onTap: () async {
              // In the full app this opens the same MobileScanner used in
              // QrScanTask, in a one-shot "register this code" mode.
              final controller = TextEditingController(text: config.qrPayload ?? '');
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Registered Code (manual entry)'),
                  content: TextField(
                    controller: controller,
                    decoration: const InputDecoration(hintText: 'Paste code value, or scan via + button'),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('Save')),
                  ],
                ),
              );
              if (result != null) onChanged(config.copyWith(qrPayload: result.trim()));
            },
          ),
        ]);
      case AlarmTaskType.speechReading:
        return _SectionCard(children: [
          ListTile(
            title: const Text('Phrase to read'),
            subtitle: Text(config.readingPhrase),
            trailing: const Icon(Icons.edit_outlined, size: 18),
            onTap: () async {
              final controller = TextEditingController(text: config.readingPhrase);
              final result = await showDialog<String>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Reading Phrase'),
                  content: TextField(controller: controller, maxLines: 3),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(context, controller.text), child: const Text('OK')),
                  ],
                ),
              );
              if (result != null && result.trim().isNotEmpty) {
                onChanged(config.copyWith(readingPhrase: result.trim()));
              }
            },
          ),
        ]);
    }
  }
}

class _Stepper extends StatelessWidget {
  final int value;
  final int min;
  final int max;
  final int step;
  final ValueChanged<int> onChanged;

  const _Stepper({
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    this.step = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > min ? () => onChanged(value - step) : null,
        ),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w700)),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: value < max ? () => onChanged(value + step) : null,
        ),
      ],
    );
  }
}
