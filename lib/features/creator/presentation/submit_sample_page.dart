import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/app_models.dart';
import '../../../common/services/repository_providers.dart';
import '../../campaigns/presentation/campaign_providers.dart';

class SubmitSamplePage extends ConsumerStatefulWidget {
  const SubmitSamplePage({
    super.key,
    required this.campaignId,
    required this.applicationId,
  });

  final String campaignId;
  final String applicationId;

  @override
  ConsumerState<SubmitSamplePage> createState() => _SubmitSamplePageState();
}

class _SubmitSamplePageState extends ConsumerState<SubmitSamplePage> {
  final _message = TextEditingController();
  List<File> _media = const [];
  double _uploadProgress = 0;

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Sample')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _message,
              decoration: const InputDecoration(
                labelText: 'Message / caption text',
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickMedia,
              icon: const Icon(Icons.attach_file),
              label: const Text('Attach sample media'),
            ),
            if (_media.isNotEmpty)
              Wrap(
                spacing: 8,
                children: _media
                    .map((f) => Chip(label: Text(_fileName(f.path))))
                    .toList(),
              ),
            if (_uploadProgress > 0 && _uploadProgress < 1)
              LinearProgressIndicator(value: _uploadProgress),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final uid = ref.read(authRepositoryProvider).currentUser?.uid;
                if (uid == null) return;
                final mediaUrls = <String>[];
                for (final file in _media) {
                  final url = await ref.read(storageServiceProvider).uploadFile(
                        path:
                            'submissions/$uid/sample/${DateTime.now().millisecondsSinceEpoch}_${_fileName(file.path)}',
                        file: file,
                        onProgress: (value) =>
                            setState(() => _uploadProgress = value),
                      );
                  mediaUrls.add(url);
                }
                await ref.read(submissionRepositoryProvider).create(
                      campaignId: widget.campaignId,
                      applicationId: widget.applicationId,
                      type: SubmissionType.sample,
                      message: _message.text.trim(),
                      mediaUrls: mediaUrls,
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
                      to: ApplicationStatus.sampleSubmitted,
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Submit sample'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickMedia() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.media,
    );
    if (result == null) return;
    setState(() {
      _media = result.paths.whereType<String>().map(File.new).toList();
    });
  }

  String _fileName(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
  }
}
