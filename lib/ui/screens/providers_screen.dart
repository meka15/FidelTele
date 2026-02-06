import 'package:flutter/material.dart';

import '../../app/app_state_scope.dart';
import '../../app/app_state.dart';
import '../../domain/provider.dart';

class ProvidersScreen extends StatelessWidget {
  const ProvidersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final total = appState.totalSummary();
    final items = appState.providerSummaries();

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
              child: Icon(Icons.public, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Providers',
                      style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 2),
                  Text('Data remaining by network',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _TotalDataCard(total: total.totalData),
        const SizedBox(height: 16),
        Text('Providers', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        ...items.expand(
          (item) => [
            _ProviderCard(item: item),
            const SizedBox(height: 12),
          ],
        ),
      ],
    );
  }
}

class _TotalDataCard extends StatelessWidget {
  const _TotalDataCard({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x331E3A8A),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.data_usage, color: scheme.onPrimary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total data remaining',
                    style: TextStyle(color: Color(0xFFE0E7FF)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    total,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProviderCard extends StatelessWidget {
  const _ProviderCard({required this.item});

  final ProviderSummary item;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant),
        boxShadow: const [
          BoxShadow(
            color: Color(0x140F172A),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_iconForProvider(item.provider), color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  _MetricRow(label: 'Data remaining', value: item.totalData),
                  const SizedBox(height: 4),
                  _MetricRow(label: 'Minutes', value: item.minutes),
                  const SizedBox(height: 4),
                  _MetricRow(label: 'SMS', value: item.sms),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

IconData _iconForProvider(Provider? provider) {
  switch (provider) {
    case Provider.ethio:
      return Icons.public;
    case Provider.safaricom:
      return Icons.network_check;
    default:
      return Icons.public;
  }
}
