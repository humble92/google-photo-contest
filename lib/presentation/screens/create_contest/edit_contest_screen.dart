import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:humble_photo_contest/core/utils/pass_key_generator.dart';
import 'package:humble_photo_contest/data/models/contest.dart';
import 'package:humble_photo_contest/presentation/providers/contest_provider.dart';

class EditContestScreen extends ConsumerStatefulWidget {
  final Contest contest;

  const EditContestScreen({super.key, required this.contest});

  @override
  ConsumerState<EditContestScreen> createState() => _EditContestScreenState();
}

class _EditContestScreenState extends ConsumerState<EditContestScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _passKeyController;
  late bool _showVoteCounts;
  late bool _isPrivate;
  late ContestStatus _status;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.contest.title);
    _descriptionController = TextEditingController(
      text: widget.contest.description ?? '',
    );
    _passKeyController = TextEditingController(
      text: widget.contest.passKey ?? '',
    );
    _showVoteCounts = widget.contest.showVoteCounts;
    _isPrivate = widget.contest.isPrivate;
    _status = widget.contest.status;

    // Generate pass key if private but no key exists
    if (_isPrivate && _passKeyController.text.isEmpty) {
      _passKeyController.text = PassKeyGenerator.generate();
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _passKeyController.dispose();
    super.dispose();
  }

  void _regeneratePassKey() {
    setState(() {
      _passKeyController.text = PassKeyGenerator.generate();
    });
  }

  void _copyPassKey() {
    Clipboard.setData(ClipboardData(text: _passKeyController.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Pass key copied to clipboard')),
    );
  }

  Future<void> _updateContest() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await ref
          .read(contestRepositoryProvider)
          .updateContest(
            contestId: widget.contest.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim().isEmpty
                ? null
                : _descriptionController.text.trim(),
            status: _status.toString().split('.').last,
            showVoteCounts: _showVoteCounts,
            isPrivate: _isPrivate,
            passKey: _isPrivate ? _passKeyController.text.trim() : null,
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Contest updated successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update contest: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremiumAsync = ref.watch(isPremiumUserProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Contest')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Contest Title',
                border: OutlineInputBorder(),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ContestStatus>(
              value: _status,
              decoration: const InputDecoration(
                labelText: 'Contest Status',
                border: OutlineInputBorder(),
              ),
              items: ContestStatus.values.map((status) {
                return DropdownMenuItem(
                  value: status,
                  child: Text(_formatStatus(status)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _status = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Show Vote Counts'),
              subtitle: const Text(
                'If enabled, users can see the total number of likes for each photo.',
              ),
              value: _showVoteCounts,
              onChanged: (value) {
                setState(() {
                  _showVoteCounts = value;
                });
              },
            ),
            const Divider(),
            // Private Contest Toggle (Premium Only)
            isPremiumAsync.when(
              data: (isPremium) => SwitchListTile(
                title: Row(
                  children: [
                    const Text('Private Contest'),
                    if (!isPremium) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'PREMIUM',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Text(
                  isPremium
                      ? 'Only users with the pass key can access this contest.'
                      : 'Upgrade to Premium to create private contests.',
                ),
                value: _isPrivate,
                onChanged: isPremium
                    ? (value) {
                        setState(() {
                          _isPrivate = value;
                          if (value && _passKeyController.text.isEmpty) {
                            _passKeyController.text =
                                PassKeyGenerator.generate();
                          }
                        });
                      }
                    : null,
              ),
              loading: () => const ListTile(
                title: Text('Private Contest'),
                subtitle: Text('Loading...'),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
            // Pass Key Field (only shown when private)
            if (_isPrivate) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _passKeyController,
                decoration: InputDecoration(
                  labelText: 'Pass Key',
                  border: const OutlineInputBorder(),
                  helperText:
                      'Share this key with participants to allow them access.',
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _regeneratePassKey,
                        tooltip: 'Generate new key',
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy),
                        onPressed: _copyPassKey,
                        tooltip: 'Copy key',
                      ),
                    ],
                  ),
                ),
                validator: (value) {
                  if (_isPrivate && (value == null || value.trim().isEmpty)) {
                    return 'Please enter a pass key';
                  }
                  if (_isPrivate && value!.length < 6) {
                    return 'Pass key must be at least 6 characters';
                  }
                  return null;
                },
              ),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _isLoading ? null : _updateContest,
              child: _isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Update Contest'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatStatus(ContestStatus status) {
    switch (status) {
      case ContestStatus.draft:
        return 'Draft';
      case ContestStatus.active:
        return 'Active';
      case ContestStatus.ended:
        return 'Ended';
    }
  }
}
