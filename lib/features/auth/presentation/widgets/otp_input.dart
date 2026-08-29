import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nova_modest/core/theme/app_colors.dart';
import 'package:nova_modest/core/theme/app_dimensions.dart';

/// The six-box one-time-code field.
///
/// Laid out in **logical** order with no `textDirection` set, so it mirrors with
/// the rest of the UI. The digits themselves are always read start-to-end, which
/// is what the user's typing order means.
///
/// Handles what a naive six-`TextField` version gets wrong: typing advances,
/// backspace on an empty box steps back and clears the previous one, and pasting
/// a whole code fills every box instead of dropping five characters.
class OtpInput extends StatefulWidget {
  const OtpInput({
    required this.onChanged,
    required this.onCompleted,
    this.enabled = true,
    this.length = 6,
    super.key,
  });

  final ValueChanged<String> onChanged;

  /// Fired once the final digit lands, so the common case needs no button tap.
  final ValueChanged<String> onCompleted;

  final bool enabled;
  final int length;

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _nodes;

  /// From the design: 48x56 boxes. Specific to this one control and used
  /// nowhere else, so it stays local rather than joining a shared scale
  /// (`12-flutter-design-system-guard.md` §5).
  static const double _boxWidth = 48;
  static const double _boxHeight = 56;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.length,
      (_) => TextEditingController(),
      growable: false,
    );
    _nodes = List.generate(widget.length, (_) => FocusNode(), growable: false);
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _nodes) {
      node.dispose();
    }
    super.dispose();
  }

  String get _code => _controllers.map((c) => c.text).join();

  void _report() {
    final code = _code;
    widget.onChanged(code);
    if (code.length == widget.length) {
      _nodes[widget.length - 1].unfocus();
      widget.onCompleted(code);
    }
  }

  void _onChanged(int index, String value) {
    // A paste lands entirely in one box; spread it across the remaining ones
    // rather than keeping the first character and discarding the rest.
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (var i = 0; i < widget.length; i++) {
        final target = index + i;
        if (target >= widget.length || i >= digits.length) break;
        _controllers[target].text = digits[i];
      }
      final next = (index + digits.length).clamp(0, widget.length - 1);
      _nodes[next].requestFocus();
      _report();
      return;
    }

    if (value.isNotEmpty && index < widget.length - 1) {
      _nodes[index + 1].requestFocus();
    }
    _report();
  }

  /// Backspace in an already-empty box clears the previous one and moves there.
  /// Without this the caret sticks and the code cannot be corrected.
  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (event.logicalKey != LogicalKeyboardKey.backspace) {
      return KeyEventResult.ignored;
    }
    if (_controllers[index].text.isNotEmpty || index == 0) {
      return KeyEventResult.ignored;
    }
    _controllers[index - 1].clear();
    _nodes[index - 1].requestFocus();
    _report();
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // Six 48pt boxes plus their gaps come to 336pt, which does not fit the
    // 327pt a 375pt screen leaves after page padding — the design's own row is
    // 348pt inside 350pt, with no margin for a narrower device. scaleDown keeps
    // the design's proportions and shrinks only when it has to, so the row
    // cannot overflow at any width.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          for (var index = 0; index < widget.length; index++)
            Padding(
              padding: EdgeInsetsDirectional.symmetric(
                horizontal: AppSpacing.xxs,
              ),
              child: SizedBox(
                width: _boxWidth,
                height: _boxHeight,
                child: Focus(
                  onKeyEvent: (_, event) => _onKey(index, event),
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _nodes[index],
                    enabled: widget.enabled,
                    autofocus: index == 0,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    // The code is digits, so it reads start-to-end whatever the
                    // ambient direction is.
                    // direction-fixed: a numeric code has no linguistic direction
                    textDirection: TextDirection.ltr,
                    style: textTheme.titleLarge,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      counterText: '',
                      filled: true,
                      fillColor: AppColors.secondary,
                      contentPadding: EdgeInsetsDirectional.zero,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.s),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.s),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppRadius.s),
                        borderSide: const BorderSide(
                          color: AppColors.accent,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => _onChanged(index, value),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
