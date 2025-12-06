import 'package:flutter/material.dart';

/// Dialog to prompt user to enter a pass key for a private contest
class PassKeyDialog extends StatefulWidget {
  final Future<bool> Function(String passKey) onVerify;
  final String? contestTitle;

  const PassKeyDialog({super.key, required this.onVerify, this.contestTitle});

  @override
  State<PassKeyDialog> createState() => _PassKeyDialogState();
}

class _PassKeyDialogState extends State<PassKeyDialog> {
  final _passKeyController = TextEditingController();
  bool _isVerifying = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passKeyController.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final passKey = _passKeyController.text.trim();
    if (passKey.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter a pass key';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    try {
      final isValid = await widget.onVerify(passKey);
      if (mounted) {
        if (isValid) {
          Navigator.of(context).pop(passKey);
        } else {
          setState(() {
            _errorMessage = 'Invalid pass key. Please try again.';
            _isVerifying = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error verifying pass key: $e';
          _isVerifying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.contestTitle != null
            ? 'Enter Pass Key for "${widget.contestTitle}"'
            : 'Enter Pass Key',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This is a private contest. Please enter the pass key to continue.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passKeyController,
            decoration: InputDecoration(
              labelText: 'Pass Key',
              border: const OutlineInputBorder(),
              errorText: _errorMessage,
            ),
            enabled: !_isVerifying,
            autofocus: true,
            onSubmitted: (_) => _handleVerify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isVerifying ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _isVerifying ? null : _handleVerify,
          child: _isVerifying
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Verify'),
        ),
      ],
    );
  }
}

/// Show pass key dialog and return the verified pass key or null if cancelled
Future<String?> showPassKeyDialog({
  required BuildContext context,
  required Future<bool> Function(String passKey) onVerify,
  String? contestTitle,
}) async {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (context) =>
        PassKeyDialog(onVerify: onVerify, contestTitle: contestTitle),
  );
}
