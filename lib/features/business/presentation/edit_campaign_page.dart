import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/repository_providers.dart';

class EditCampaignPage extends ConsumerStatefulWidget {
  const EditCampaignPage({super.key, this.campaignId});

  final String? campaignId;

  @override
  ConsumerState<EditCampaignPage> createState() => _EditCampaignPageState();
}

class _EditCampaignPageState extends ConsumerState<EditCampaignPage> {
  static const _platformOptions = <String>[
    'TikTok',
    'Instagram',
    'YouTube',
    'X',
  ];

  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _platform = TextEditingController(text: 'TikTok');
  final _targetViews = TextEditingController(text: '1000');
  final _payout = TextEditingController(text: '100');
  final _creatorsNeeded = TextEditingController(text: '1');
  final _hashtags = TextEditingController();
  final _doDont = TextEditingController();
  final _mention = TextEditingController();
  bool _publishing = false;
  List<File> _selectedImages = const [];
  double _uploadProgress = 0;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _platform.dispose();
    _targetViews.dispose();
    _payout.dispose();
    _creatorsNeeded.dispose();
    _hashtags.dispose();
    _doDont.dispose();
    _mention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.campaignId == null ? 'Create Campaign' : 'Edit Campaign',
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(labelText: 'Description'),
              maxLines: 4,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _platform.text.isEmpty ? null : _platform.text,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: _platformOptions
                  .map(
                    (platform) => DropdownMenuItem<String>(
                      value: platform,
                      child: Text(platform),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                _platform.text = value ?? '';
              },
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _targetViews,
              decoration: const InputDecoration(labelText: 'Target Views'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _payout,
              decoration: const InputDecoration(
                labelText: 'Payout Amount (GHS)',
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _creatorsNeeded,
              decoration: const InputDecoration(labelText: 'Creators Needed'),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _hashtags,
              decoration: const InputDecoration(
                labelText: 'Hashtags comma separated',
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mention,
              decoration: const InputDecoration(labelText: 'Mention'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _doDont,
              decoration: const InputDecoration(labelText: 'Do/Don\'t rules'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _publishing ? null : _pickImages,
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload product images'),
            ),
            const SizedBox(height: 8),
            if (_selectedImages.isNotEmpty)
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F7FC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_selectedImages.length} image(s) selected',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF35507A),
                  ),
                ),
              ),
            if (_publishing && _uploadProgress > 0 && _uploadProgress < 1) ...[
              const SizedBox(height: 8),
              LinearProgressIndicator(value: _uploadProgress),
            ],
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _publishing
                  ? null
                  : () => _save(context, CampaignStatus.published),
              child: Text(
                widget.campaignId == null ? 'Publish Campaign' : 'Save Changes',
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: _publishing
                  ? null
                  : () => _save(context, CampaignStatus.draft),
              child: Text(
                widget.campaignId == null ? 'Save as Draft' : 'Move to Draft',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save(BuildContext context, CampaignStatus status) async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _publishing = true);
    try {
      final user = ref.read(authRepositoryProvider).currentUser;
      if (user == null) throw StateError('Not authenticated');
      final imageUrls = <String>[];
      for (final file in _selectedImages) {
        final url = await ref.read(storageServiceProvider).uploadFile(
              path:
                  'campaigns/${user.uid}/${DateTime.now().millisecondsSinceEpoch}_${_fileName(file.path)}',
              file: file,
              onProgress: (value) => setState(() => _uploadProgress = value),
            );
        imageUrls.add(url);
      }

      final campaign = Campaign(
        id: '',
        businessId: user.uid,
        title: _title.text.trim(),
        description: _description.text.trim(),
        productImages: imageUrls,
        platform: _platform.text.trim(),
        targetViews: int.tryParse(_targetViews.text.trim()) ?? 0,
        payoutAmountGhs: int.tryParse(_payout.text.trim()) ?? 0,
        creatorsNeeded: int.tryParse(_creatorsNeeded.text.trim()) ?? 1,
        rules: {
          'hashtags': _hashtags.text
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList(),
          'mention': _mention.text.trim(),
          'doDont': _doDont.text.trim(),
        },
        startDate: DateTime.now(),
        endDate: DateTime.now().add(const Duration(days: 14)),
        status: status,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final repo = ref.read(campaignRepositoryProvider);
      if (widget.campaignId == null) {
        await repo.createCampaign(campaign);
      } else {
        await repo.updateCampaign(widget.campaignId!, {
          ...campaign.toJson(),
          'updatedAt': DateTime.now(),
        });
      }
      if (context.mounted) Navigator.pop(context);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Future<void> _pickImages() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.image,
    );
    if (result == null) return;
    setState(() {
      _selectedImages = result.paths.whereType<String>().map(File.new).toList();
    });
  }

  String _fileName(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isEmpty ? path : parts.last;
  }
}
