import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../common/models/app_models.dart';
import '../../../common/models/entities.dart';
import '../../../common/services/repository_providers.dart';
import '../../ai/domain/ai_campaign_models.dart';

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
  CampaignBriefSuggestion? _aiSuggestion;

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
            _CampaignArchitectCard(
              suggestion: _aiSuggestion,
              onPressed: _publishing ? null : _openCampaignArchitect,
            ),
            const SizedBox(height: 16),
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
              key: ValueKey(_platform.text),
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

  Future<void> _openCampaignArchitect() async {
    final suggestion = await showModalBottomSheet<CampaignBriefSuggestion>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _CampaignArchitectSheet(
        initialTitle: _title.text.trim(),
        initialDescription: _description.text.trim(),
        initialPlatform: _platform.text.trim(),
        initialTargetViews: int.tryParse(_targetViews.text.trim()) ?? 1000,
        initialPayout: int.tryParse(_payout.text.trim()) ?? 100,
        initialCreators: int.tryParse(_creatorsNeeded.text.trim()) ?? 1,
        initialMention: _mention.text.trim(),
        platformOptions: _platformOptions,
      ),
    );

    if (!mounted || suggestion == null) return;
    setState(() {
      _aiSuggestion = suggestion;
      _title.text = suggestion.title;
      _description.text = suggestion.description;
      _platform.text = suggestion.platform;
      _targetViews.text = '${suggestion.targetViews}';
      _payout.text = '${suggestion.payoutAmountGhs}';
      _creatorsNeeded.text = '${suggestion.creatorsNeeded}';
      _hashtags.text = suggestion.hashtags.join(', ');
      _doDont.text = suggestion.doDont;
      _mention.text = suggestion.mention;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'GPT-5.6 filled the form. Review every field before publishing.',
        ),
      ),
    );
  }
}

class _CampaignArchitectCard extends StatelessWidget {
  const _CampaignArchitectCard({
    required this.suggestion,
    required this.onPressed,
  });

  final CampaignBriefSuggestion? suggestion;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF091E42), Color(0xFF173F7A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x260B2D5E),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0x26FFFFFF),
                child: Icon(Icons.auto_awesome_rounded, color: Colors.white),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campaign Architect',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      'Powered by GPT-5.6',
                      style: TextStyle(
                        color: Color(0xFFB9D5FF),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0x26FFFFFF),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'AI',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            suggestion == null
                ? 'Turn a rough product idea into an editable creator brief, '
                    'content guardrails, and three campaign angles.'
                : 'Brief generated. The fields below remain fully editable.',
            style: const TextStyle(
              color: Color(0xFFE3EEFF),
              height: 1.4,
            ),
          ),
          if (suggestion != null) ...[
            const SizedBox(height: 14),
            _AiBriefInsight(
              label: 'Best-fit creator',
              value: suggestion!.creatorProfile,
            ),
            const SizedBox(height: 8),
            _AiBriefInsight(
              label: 'Success signal',
              value: suggestion!.successMetric,
            ),
            if (suggestion!.contentAngles.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'CONTENT ANGLES',
                style: TextStyle(
                  color: Color(0xFF9FC4FF),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              for (final angle in suggestion!.contentAngles.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    '• ${angle.hook} — ${angle.concept}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
                ),
            ],
          ],
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF0C3268),
              ),
              onPressed: onPressed,
              icon: const Icon(Icons.auto_fix_high_rounded),
              label: Text(
                suggestion == null
                    ? 'Build brief with GPT-5.6'
                    : 'Regenerate brief',
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI suggestions never publish automatically. You stay in control.',
            style: TextStyle(
              color: Color(0xFFAAC5EC),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _AiBriefInsight extends StatelessWidget {
  const _AiBriefInsight({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0x1FFFFFFF),
        borderRadius: BorderRadius.circular(12),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            height: 1.35,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }
}

class _CampaignArchitectSheet extends ConsumerStatefulWidget {
  const _CampaignArchitectSheet({
    required this.initialTitle,
    required this.initialDescription,
    required this.initialPlatform,
    required this.initialTargetViews,
    required this.initialPayout,
    required this.initialCreators,
    required this.initialMention,
    required this.platformOptions,
  });

  final String initialTitle;
  final String initialDescription;
  final String initialPlatform;
  final int initialTargetViews;
  final int initialPayout;
  final int initialCreators;
  final String initialMention;
  final List<String> platformOptions;

  @override
  ConsumerState<_CampaignArchitectSheet> createState() =>
      _CampaignArchitectSheetState();
}

class _CampaignArchitectSheetState
    extends ConsumerState<_CampaignArchitectSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _productName;
  late final TextEditingController _productDescription;
  late final TextEditingController _audience;
  late final TextEditingController _goal;
  late final TextEditingController _tone;
  late final TextEditingController _mention;
  late String _platform;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _productName = TextEditingController(text: widget.initialTitle);
    _productDescription = TextEditingController(
      text: widget.initialDescription,
    );
    _audience = TextEditingController();
    _goal = TextEditingController(text: 'Build awareness and product trial');
    _tone = TextEditingController(text: 'Authentic, clear, and energetic');
    _mention = TextEditingController(text: widget.initialMention);
    _platform = widget.platformOptions.contains(widget.initialPlatform)
        ? widget.initialPlatform
        : widget.platformOptions.first;
  }

  @override
  void dispose() {
    _productName.dispose();
    _productDescription.dispose();
    _audience.dispose();
    _goal.dispose();
    _tone.dispose();
    _mention.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            20,
            12,
            20,
            MediaQuery.viewInsetsOf(context).bottom + 24,
          ),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4DEED),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Row(
              children: [
                CircleAvatar(
                  backgroundColor: Color(0xFFE1ECFF),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: Color(0xFF174EA6),
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Campaign Architect',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'GPT-5.6 turns your context into an editable brief',
                        style: TextStyle(color: Color(0xFF5A6F8F)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            TextFormField(
              controller: _productName,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Product or service',
                hintText: 'Spark Brew Mango Rush',
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _productDescription,
              enabled: !_loading,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'What should creators know?',
                hintText:
                    'Describe the product, differentiator, and facts the AI '
                    'must not invent.',
              ),
              validator: (value) {
                if ((value ?? '').trim().length < 20) {
                  return 'Add at least 20 characters of product context';
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _audience,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Target audience',
                hintText: 'Young professionals in Accra',
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _goal,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'Campaign goal',
              ),
              validator: _required,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _platform,
              decoration: const InputDecoration(labelText: 'Platform'),
              items: widget.platformOptions
                  .map(
                    (platform) => DropdownMenuItem(
                      value: platform,
                      child: Text(platform),
                    ),
                  )
                  .toList(),
              onChanged: _loading
                  ? null
                  : (value) => setState(() {
                        _platform = value ?? _platform;
                      }),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _tone,
              enabled: !_loading,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Brand tone'),
              validator: _required,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _mention,
              enabled: !_loading,
              decoration: const InputDecoration(
                labelText: 'Brand mention (optional)',
                hintText: '@yourbrand',
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F6FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                '${widget.initialTargetViews} target views • '
                'GHS ${widget.initialPayout} payout • '
                '${widget.initialCreators} creator(s)\n'
                'These business-controlled values will not be changed by AI.',
                style: const TextStyle(
                  color: Color(0xFF244C82),
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                style: const TextStyle(
                  color: Color(0xFFB42318),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _loading ? null : _generate,
              icon: _loading
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.auto_fix_high_rounded),
              label: Text(
                _loading ? 'GPT-5.6 is building...' : 'Generate editable brief',
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _loading ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  String? _required(String? value) {
    return (value ?? '').trim().isEmpty ? 'Required' : null;
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final suggestion =
          await ref.read(aiCampaignRepositoryProvider).generateCampaignBrief(
                productName: _productName.text.trim(),
                productDescription: _productDescription.text.trim(),
                audience: _audience.text.trim(),
                campaignGoal: _goal.text.trim(),
                platform: _platform,
                tone: _tone.text.trim(),
                targetViews: widget.initialTargetViews,
                payoutAmountGhs: widget.initialPayout,
                creatorsNeeded: widget.initialCreators,
                brandMention: _mention.text.trim(),
              );
      if (!mounted) return;
      Navigator.pop(context, suggestion);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }
}
