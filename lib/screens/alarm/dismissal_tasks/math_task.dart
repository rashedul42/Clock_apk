import 'dart:math';
import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import 'task_base.dart';

/// Task 1: Math Challenges. Generates [problemCount] randomized problems
/// (addition, subtraction, multiplication, division — mixed and chained
/// like "23 x 4 + 15" at higher difficulty) and requires correct answers
/// in a row before calling [onCompleted]. A wrong answer regenerates a
/// fresh problem rather than dismissing, so it can't be brute-forced.
class MathTask extends StatefulWidget {
  final int problemCount;
  final int difficulty; // 1..3
  final TaskCompletedCallback onCompleted;

  const MathTask({
    super.key,
    required this.problemCount,
    required this.difficulty,
    required this.onCompleted,
  });

  @override
  State<MathTask> createState() => _MathTaskState();
}

class _Problem {
  final String prompt;
  final int answer;
  _Problem(this.prompt, this.answer);
}

class _MathTaskState extends State<MathTask> {
  final _rnd = Random();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  int _solved = 0;
  late _Problem _current;
  bool _wrongFlash = false;

  @override
  void initState() {
    super.initState();
    _current = _generate();
  }

  _Problem _generate() {
    // Difficulty scales operand size and whether a second operator chains in.
    final maxOperand = switch (widget.difficulty) {
      1 => 12,
      2 => 25,
      _ => 50,
    };
    int a = _rnd.nextInt(maxOperand) + 1;
    int b = _rnd.nextInt(maxOperand) + 1;
    const ops = ['+', '-', 'x', '÷'];
    String op = ops[_rnd.nextInt(widget.difficulty >= 2 ? 4 : 2)];

    int result;
    String prompt;
    switch (op) {
      case '+':
        result = a + b;
        prompt = '$a + $b';
        break;
      case '-':
        if (b > a) { final t = a; a = b; b = t; }
        result = a - b;
        prompt = '$a - $b';
        break;
      case 'x':
        a = _rnd.nextInt(12) + 1;
        b = _rnd.nextInt(12) + 1;
        result = a * b;
        prompt = '$a x $b';
        break;
      default: // ÷ — construct so it divides evenly
        b = _rnd.nextInt(10) + 1;
        result = _rnd.nextInt(12) + 1;
        a = b * result;
        prompt = '$a ÷ $b';
    }

    // At hard difficulty, chain a second operation, e.g. "23 x 4 + 15".
    if (widget.difficulty >= 3) {
      final extra = _rnd.nextInt(20) + 1;
      final addOrSub = _rnd.nextBool();
      prompt += addOrSub ? ' + $extra' : ' - $extra';
      result += addOrSub ? extra : -extra;
    }

    return _Problem(prompt, result);
  }

  void _submit() {
    final input = int.tryParse(_controller.text.trim());
    if (input == null) return;
    if (input == _current.answer) {
      setState(() {
        _solved++;
        _controller.clear();
        if (_solved >= widget.problemCount) {
          widget.onCompleted();
        } else {
          _current = _generate();
        }
      });
    } else {
      setState(() => _wrongFlash = true);
      _controller.clear();
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) setState(() => _wrongFlash = false);
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TaskScaffold(
      emoji: '➗',
      title: 'Solve to Dismiss',
      instructions: 'Answer ${widget.problemCount} problems correctly in a row',
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TaskProgressPill(current: _solved, total: widget.problemCount),
          const SizedBox(height: 28),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            decoration: BoxDecoration(
              color: _wrongFlash ? AppColors.danger.withValues(alpha: 0.25) : Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_current.prompt} = ?',
              style: const TextStyle(fontSize: 32, color: Colors.white, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: 160,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              autofocus: true,
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              style: const TextStyle(color: Colors.white, fontSize: 24),
              onSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                hintText: 'Answer',
                hintStyle: const TextStyle(color: Colors.white38),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(onPressed: _submit, child: const Text('Submit')),
        ],
      ),
    );
  }
}
