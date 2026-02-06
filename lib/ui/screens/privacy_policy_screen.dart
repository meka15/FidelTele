import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          Text('Privacy Policy for FidelTele', style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Effective Date: February 5, 2026', style: textTheme.bodyMedium),
          const SizedBox(height: 16),
          Text(
            'FidelTele (“we”, “our”, or “us”) respects your privacy. This policy explains how we handle information when you use the FidelTele mobile app.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('1. Information We Access', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '• SMS Messages: The app requests access to SMS only to read balance, plan, and notification messages from supported mobile network providers.\n'
            '• The app does not access or collect unrelated SMS content.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('2. How We Use Information', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '• SMS data is processed locally on your device to display balances, plan status, and alerts.\n'
            '• We do not upload or transmit SMS data to any server.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('3. Data Sharing', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '• We do not sell, share, or transfer your data to third parties.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('4. Permissions', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '• SMS permissions are required to provide the core feature of automatically reading balance messages.\n'
            '• We do not request unnecessary permissions.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('5. Data Security', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            '• All SMS processing happens on-device.\n'
            '• No SMS data is stored or transmitted outside your device.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('6. Changes to This Policy', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'We may update this policy from time to time. Updates will be posted within the app or the app listing.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text('7. Contact', style: textTheme.titleMedium),
          const SizedBox(height: 6),
          Text(
            'If you have questions, contact us at: mekbibtariku19@gmail.com',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
