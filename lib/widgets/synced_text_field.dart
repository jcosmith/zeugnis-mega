import 'package:flutter/material.dart';

/// Textfeld, das seinen Inhalt übernimmt, wenn sich [value] von außen ändert
/// (z. B. nachdem das Sprachmodell einen Text erzeugt hat).
class SyncedTextField extends StatefulWidget {
  const SyncedTextField({
    super.key,
    required this.value,
    required this.onChanged,
    this.decoration = const InputDecoration(),
    this.minLines,
    this.maxLines = 1,
    this.enabled = true,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final InputDecoration decoration;
  final int? minLines;
  final int? maxLines;
  final bool enabled;

  @override
  State<SyncedTextField> createState() => _SyncedTextFieldState();
}

class _SyncedTextFieldState extends State<SyncedTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(SyncedTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: _controller,
      onChanged: widget.onChanged,
      decoration: widget.decoration,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      enabled: widget.enabled,
      textCapitalization: TextCapitalization.sentences,
    );
  }
}
