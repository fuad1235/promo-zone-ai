import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';
import '../../campaigns/presentation/campaign_providers.dart';

class SubmitProofPage extends ConsumerStatefulWidget {
  const SubmitProofPage({
    super.key,
    required this.campaignId,
    required this.applicationId,
  });

  final String campaignId;
  final String applicationId;

  @override
  ConsumerState<SubmitProofPage> createState() => _SubmitProofPageState();
}

class _SubmitProofPageState extends ConsumerState<SubmitProofPage> {
  final _postUrl = TextEditingController();
  final _views = TextEditingController();
  List<File> _screenshots = const [];
  double _uploadProgress = 0;

  @override
  void dispose() {
    _postUrl.dispose();
    _views.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Proof')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: const Color(0xFF0E2A54),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Proof checklist',
                  style: TextStyle(
                    color: Color(0xFFA7CCFF),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Add post URL, current views, and clear screenshots to speed up payout approval.',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  TextField(
                    controller: _postUrl,
                    decoration: const InputDecoration(labelText: 'Post URL'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _views,
                    keyboardType: TextInputType.number,
                    decoration:
                        const InputDecoration(labelText: 'Declared views'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickScreenshots,
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Upload screenshots'),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Include screenshot(s) showing views and engagement details.',
                  ),
                  if (_screenshots.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: _screenshots
                          .map((f) => Chip(label: Text(_fileName(f.path))))
                          .toList(),
                    ),
                  ],
                  if (_uploadProgress > 0 && _uploadProgress < 1) ...[
                    const SizedBox(height: 8),
                    LinearProgressIndicator(value: _uploadProgress),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () async {
              final views = int.tryParse(_views.text.trim());
              final normalizedPostUrl = _normalizeUrl(_postUrl.text.trim());
              if (normalizedPostUrl == null || views == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Enter a valid post URL (including domain) and views.',
                    ),
                  ),
                );
                return;
              }
              final uid = ref.read(authRepositoryProvider).currentUser?.uid;
              if (uid == null) return;
              final screenshotUrls = <String>[];
              for (final file in _screenshots) {
                final url = await ref.read(storageServiceProvider).uploadFile(
                      path:
                          'submissions/$uid/proof/${DateTime.now().millisecondsSinceEpoch}_${_fileName(file.path)}',
                      file: file,
                      onProgress: (value) =>
                          setState(() => _uploadProgress = value),
                    );
                screenshotUrls.add(url);
              }

              await ref.read(submissionRepositoryProvider).create(
                    campaignId: widget.campaignId,
                    applicationId: widget.applicationId,
                    type: SubmissionType.proof,
                    message: 'Proof submitted',
                    mediaUrls: const [],
                    postUrl: normalizedPostUrl,
                    declaredViews: views,
                    screenshots: screenshotUrls,
                  );

              final apps = await ref.read(
                campaignApplicationsProvider(widget.campaignId).future,
              );
              final app = apps.firstWhere(
                (e) => e.id == widget.applicationId,
              );

              await ref.read(applicationRepositoryProvider).transitionStatus(
                    campaignId: widget.campaignId,
                    applicationId: widget.applicationId,
                    from: app.status,
                    to: ApplicationStatus.proofSubmitted,
                  );

              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Submit proof'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickScreenshots() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) return;
    setState(() {
      _screenshots = result.paths.whereType<String>().map(File.new).toList();
    });
  }

  String _fileName(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
  }

  String? _normalizeUrl(String input) {
    if (input.isEmpty) return null;
    var value = input.trim();
    if (!value.contains('://')) {
      value = 'https://$value';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) {
      return null;
    }
    return value;
  }
}
