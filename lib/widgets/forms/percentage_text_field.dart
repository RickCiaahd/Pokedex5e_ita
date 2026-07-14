import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PercentageTextField extends StatefulWidget {
  const PercentageTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 1,
    this.max = 100,
    this.width = 82,
  });

  final int value;
  final ValueChanged<int> onChanged;
  final int min;
  final int max;
  final double width;

  @override
  State<PercentageTextField> createState() => _PercentageTextFieldState();
}

class _PercentageTextFieldState extends State<PercentageTextField> {
  late final TextEditingController _controller;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: '${widget.value}');
    _focusNode = FocusNode()..addListener(_handleFocusChanged);
  }

  @override
  void didUpdateWidget(covariant PercentageTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_focusNode.hasFocus && oldWidget.value != widget.value) {
      _replaceText('${widget.value}');
    }
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_handleFocusChanged)
      ..dispose();
    _controller.dispose();
    super.dispose();
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _normalizeText();
    }
  }

  void _normalizeText() {
    final parsed = int.tryParse(_controller.text);
    final normalized = (parsed ?? widget.value)
        .clamp(widget.min, widget.max)
        .toInt();
    _replaceText('$normalized');
    if (normalized != widget.value) {
      widget.onChanged(normalized);
    }
  }

  void _replaceText(String value) {
    _controller.value = TextEditingValue(
      text: value,
      selection: TextSelection.collapsed(offset: value.length),
    );
  }

  void _handleChanged(String rawValue) {
    final parsed = int.tryParse(rawValue);
    if (parsed == null) return;
    widget.onChanged(parsed.clamp(widget.min, widget.max).toInt());
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        inputFormatters: const [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(3),
        ],
        decoration: const InputDecoration(
          suffixText: '%',
          border: OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: _handleChanged,
        onEditingComplete: () {
          _normalizeText();
          _focusNode.unfocus();
        },
      ),
    );
  }
}
