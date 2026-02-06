import 'package:flutter/material.dart';

import '../../app/app_state_scope.dart';
import '../../domain/provider.dart';

class MessagesScreen extends StatelessWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appState = AppStateScope.of(context);
    final items = appState.messages;

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: items.length + 2,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == 0) {
          return Row(
            children: [
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.sms_rounded, color: scheme.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Message history',
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text('Parsed SMS and alerts',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ],
          );
        }

        if (index == 1) {
          if (!appState.isAndroid) {
            return _NoticeCard(
              icon: Icons.info_outline,
              title: 'SMS access not available',
              message: 'SMS parsing is supported on Android only.',
              color: scheme.primary,
              background: scheme.primaryContainer,
            );
          }
          if (appState.isLoading) {
            return _NoticeCard(
              icon: Icons.sync,
              title: 'Loading messages',
              message: 'Fetching SMS inbox…',
              color: scheme.primary,
              background: scheme.primaryContainer,
            );
          }
          if (!appState.permissionGranted) {
            return _ActionCard(
              icon: Icons.lock,
              title: 'Permission needed',
              message: 'Allow SMS permission to read your balance messages.',
              buttonLabel: 'Grant permission',
              onPressed: appState.requestPermissions,
              color: scheme.primary,
              background: scheme.primaryContainer,
            );
          }
          if (items.isEmpty) {
            return _NoticeCard(
              icon: Icons.inbox_outlined,
              title: 'No messages yet',
              message: 'We will show your SMS balances here.',
              color: scheme.primary,
              background: scheme.primaryContainer,
            );
          }
          return const SizedBox.shrink();
        }

        final item = items[index - 2];
        final statusColor = item.parsed
          ? scheme.primary
          : const Color(0xFFDC2626);
        final statusBg = item.parsed
          ? scheme.primaryContainer
          : const Color(0xFFFEE2E2);
        final statusLabel = item.parsed ? 'Parsed' : 'Ignored';

        return Dismissible(
          key: ValueKey(item.id),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.delete, color: Color(0xFFDC2626)),
          ),
          onDismissed: (_) {
            appState.removeMessage(item.id);
          },
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_iconForProvider(item.provider),
                            color: scheme.primary),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _providerLabel(item.provider),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _timeLabel(item.receivedAt),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusBg,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          statusLabel,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        color: const Color(0xFFDC2626),
                        onPressed: () {
                          appState.removeMessage(item.id);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(item.body),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _providerLabel(Provider provider) {
    switch (provider) {
      case Provider.ethio:
        return 'Ethio telecom';
      case Provider.safaricom:
        return 'Safaricom';
    }
  }

  IconData _iconForProvider(Provider provider) {
    switch (provider) {
      case Provider.ethio:
        return Icons.public;
      case Provider.safaricom:
        return Icons.network_check;
    }
  }

  String _timeLabel(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inHours < 24) {
      return 'Today · ${_formatTime(time)}';
    }
    if (diff.inDays == 1) {
      return 'Yesterday · ${_formatTime(time)}';
    }
    return '${time.year}-${time.month.toString().padLeft(2, '0')}-${time.day.toString().padLeft(2, '0')}';
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }
}

class _NoticeCard extends StatelessWidget {
  const _NoticeCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 4),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(message,
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(buttonLabel),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
