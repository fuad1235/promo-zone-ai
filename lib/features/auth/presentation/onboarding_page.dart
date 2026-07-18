import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../common/models/app_models.dart';
import 'auth_controller.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key, required this.role});

  final UserRole role;

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _formKey = GlobalKey<FormState>();
  final _displayName = TextEditingController();
  final _phone = TextEditingController();
  final _bioOrCompany = TextEditingController();

  @override
  void dispose() {
    _displayName.dispose();
    _phone.dispose();
    _bioOrCompany.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);

    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(
        data: (_) => context.go('/'),
        error: (error, _) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString()))),
      );
    });

    final isCreator = widget.role == UserRole.creator;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
          return;
        }
        context.go('/role-selection');
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Profile Setup')),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: isCreator
                    ? const Color(0xFF0E2A54)
                    : const Color(0xFF1D2738),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCreator ? 'Creator profile' : 'Business profile',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isCreator
                        ? 'Set up your creator identity'
                        : 'Set up your business identity',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isCreator
                        ? 'Tell brands what you create and how to reach you. You can edit this anytime.'
                        : 'Add your brand details used across campaigns and approvals. You can edit this anytime.',
                    style: const TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _displayName,
                        decoration: InputDecoration(
                          labelText: isCreator
                              ? 'Display name'
                              : 'Team lead display name',
                          prefixIcon: const Icon(Icons.person_outline_rounded),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _phone,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Phone (optional)',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioOrCompany,
                        maxLines: isCreator ? 3 : 1,
                        decoration: InputDecoration(
                          labelText: isCreator ? 'Bio' : 'Company name',
                          prefixIcon: Icon(
                            isCreator
                                ? Icons.auto_awesome_rounded
                                : Icons.domain_rounded,
                          ),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),
                      FilledButton.icon(
                        onPressed: state.isLoading
                            ? null
                            : () async {
                                if (!_formKey.currentState!.validate()) return;
                                await ref
                                    .read(authControllerProvider.notifier)
                                    .completeOnboarding(
                                      role: widget.role,
                                      displayName: _displayName.text.trim(),
                                      phone: _phone.text.trim().isEmpty
                                          ? null
                                          : _phone.text.trim(),
                                      bio: isCreator
                                          ? _bioOrCompany.text.trim()
                                          : null,
                                      companyName: !isCreator
                                          ? _bioOrCompany.text.trim()
                                          : null,
                                    );
                              },
                        icon: state.isLoading
                            ? const SizedBox.square(
                                dimension: 18,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check_circle_outline_rounded),
                        label: Text(
                          state.isLoading
                              ? 'Saving profile...'
                              : 'Save and continue',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
