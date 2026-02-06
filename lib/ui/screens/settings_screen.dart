import 'package:flutter/material.dart';

import '../../app/app_state_scope.dart';
import '../../domain/app_settings.dart';
import 'privacy_policy_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final AppSettings settings = appState.settings;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Row(
          children: [
            Container(
              height: 44,
              width: 44,
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.tune, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Settings',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text('Customize alerts and display',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text('Providers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: settings.ethioEnabled,
                onChanged: (value) {
                  appState.updateSettings(
                    settings.copyWith(ethioEnabled: value),
                  );
                },
                title: const Text('Ethio telecom'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: settings.safaricomEnabled,
                onChanged: (value) {
                  appState.updateSettings(
                    settings.copyWith(safaricomEnabled: value),
                  );
                },
                title: const Text('Safaricom'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('Alerts', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: settings.alertsEnabled,
                onChanged: (value) {
                  appState.updateSettings(
                    settings.copyWith(alertsEnabled: value),
                  );
                },
                title: const Text('Enable notifications'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: settings.showInGb,
                onChanged: (value) {
                  appState.updateSettings(
                    settings.copyWith(showInGb: value),
                  );
                },
                title: const Text('Show data in GB'),
                subtitle: const Text('Format large balances as GB'),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Low balance threshold',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: settings.lowBalanceThresholdPct,
                            min: 0.05,
                            max: 0.5,
                            divisions: 9,
                            label:
                                '${(settings.lowBalanceThresholdPct * 100).round()}%',
                            onChanged: (value) {
                              appState.updateSettings(
                                settings.copyWith(lowBalanceThresholdPct: value),
                              );
                            },
                          ),
                        ),
                        Text('${(settings.lowBalanceThresholdPct * 100).round()}%'),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expiry warning',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            value: settings.expiryWarningHours.toDouble(),
                            min: 6,
                            max: 72,
                            divisions: 11,
                            label: '${settings.expiryWarningHours}h',
                            onChanged: (value) {
                              appState.updateSettings(
                                settings.copyWith(
                                    expiryWarningHours: value.round()),
                              );
                            },
                          ),
                        ),
                        Text('${settings.expiryWarningHours}h'),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text('About', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy Policy'),
            subtitle: const Text('How we handle your data'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const PrivacyPolicyScreen(),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
