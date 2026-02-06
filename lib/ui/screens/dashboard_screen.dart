import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/app_state_scope.dart';
import '../../domain/plan.dart';
import '../../domain/plan_type.dart';
import '../../domain/provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  _SortOption _sortOption = _SortOption.expiry;
  _FilterOption _filterOption = _FilterOption.all;

  Future<void> _refresh() async {
    // 1. Reload local state/check DB
    final appState = AppStateScope.of(context);
    await appState.refresh();
    
    // 2. Also prompt user if they want to dial USSD (OPTIONAL, or keep separate)
    // The previous logic forced the prompt. Keep it separate behaviors?
    // The RefreshIndicator usually implies "fetch latest data". 
    // If we have permissions, we fetch from DB. If not, we can't do much but wait for SMS.
    
    if (appState.permissionGranted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inbox refreshed')),
      );
    } else {
      // In consent mode, manual refresh is limited.
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for incoming SMS...')),
      );
    }
  }

  Future<void> _showProviderPrompt() async {
    return showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Refresh from provider',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text(
                'Choose a network to check balance via USSD.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _ProviderActionTile(
                title: 'Ethio telecom',
                subtitle: '*804#',
                icon: Icons.public,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _dialUssd('*804#');
                },
              ),
              const SizedBox(height: 10),
              _ProviderActionTile(
                title: 'Safaricom',
                subtitle: '*704#',
                icon: Icons.network_check,
                onTap: () async {
                  Navigator.of(context).pop();
                  await _dialUssd('*704#');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _dialUssd(String code) async {
    final uri = Uri(scheme: 'tel', path: code);
    await launchUrl(uri);
  }

  List<Plan> _filteredPlans(List<Plan> source) {
    Iterable<Plan> filtered = source;
    if (_filterOption == _FilterOption.expiringSoon) {
      filtered = filtered.where(
          (plan) => plan.expiryAt.difference(DateTime.now()).inHours <= 24);
    } else if (_filterOption == _FilterOption.data) {
      filtered = filtered.where((plan) => plan.type == PlanType.data);
    } else if (_filterOption == _FilterOption.minutes) {
      filtered = filtered.where((plan) => plan.type == PlanType.minutes);
    } else if (_filterOption == _FilterOption.sms) {
      filtered = filtered.where((plan) => plan.type == PlanType.sms);
    }

    final List<Plan> result = filtered.toList();
    if (_sortOption == _SortOption.expiry) {
      result.sort((a, b) => a.expiryAt.compareTo(b.expiryAt));
    } else if (_sortOption == _SortOption.provider) {
      result.sort((a, b) => a.provider.index.compareTo(b.provider.index));
    } else if (_sortOption == _SortOption.type) {
      result.sort((a, b) => a.type.index.compareTo(b.type.index));
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final plans = _filteredPlans(appState.plans);
    final nextExpiryPlan = _nextExpiry(appState.plans);
    final totalSummary = appState.totalSummary();
    final nextExpiryLabel = nextExpiryPlan == null
      ? 'No active plans'
      : '${_planTypeLabel(nextExpiryPlan.type)} – ${_providerLabel(nextExpiryPlan.provider)}';
    final nextExpiryTime = nextExpiryPlan == null
      ? 'No expiry'
      : _expiryLabel(nextExpiryPlan.expiryAt);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          const _HeaderHero(),
          const SizedBox(height: 12),
          _SummaryCard(
            nextExpiryTitle: nextExpiryLabel,
            nextExpirySubtitle: nextExpiryTime,
            totalDataLabel: totalSummary.totalData,
            totalSmsLabel: totalSummary.sms,
            totalMinutesLabel: totalSummary.minutes,
          ),
          const SizedBox(height: 12),
          _QuickActionsCard(
            onRefresh: _showProviderPrompt,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text('Active Plans',
                    style: Theme.of(context).textTheme.titleMedium),
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: 'Refresh Inbox',
                onPressed: _refresh,
              ),
              const SizedBox(width: 4),
              _SortMenu(
                value: _sortOption,
                onChanged: (value) {
                  if (value == null) return;
                  setState(() {
                    _sortOption = value;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          _FilterChips(
            value: _filterOption,
            onChanged: (value) {
              setState(() {
                _filterOption = value;
              });
            },
          ),
          const SizedBox(height: 12),
          if (plans.isEmpty)
            const _EmptyState()
          else
            ...plans.expand(
              (plan) => [
                _PlanCard(
                  title: _planTitle(plan),
                  balance: _planBalance(plan),
                  expiry: _expiryLabel(plan.expiryAt),
                  color: (plan.label == 'Night' || plan.label == 'Night Package') 
                      ? Colors.red.shade800 
                      : const Color(0xFF1E3A8A),
                  badgeText: _badgeForPlan(plan),
                  hoursToExpiry: plan.expiryAt
                      .difference(DateTime.now())
                      .inHours,
                  icon: _planIcon(plan),
                  isNight: plan.label == 'Night' || plan.label == 'Night Package',
                ),
                const SizedBox(height: 12),
              ],
            ),
        ],
      ),
    );
  }

  String _planTitle(Plan plan) {
    final type = _planTypeLabel(plan.type);
    final provider = _providerLabel(plan.provider);
    if (plan.label != null && plan.label!.isNotEmpty) {
      // e.g. "Night - Minutes (Ethio telecom)" or just "Night - Minutes"
      return '${plan.label} $type – $provider';
    }
    return '$type – $provider';
  }

  String _planBalance(Plan plan) {
    final unit = plan.balanceUnit.toUpperCase();
    final value = plan.type == PlanType.data
        ? plan.balanceValue.toStringAsFixed(2)
        : plan.balanceValue.toStringAsFixed(0);
    return '$value $unit';
  }

  String _expiryLabel(DateTime expiryAt) {
    final now = DateTime.now();
    final diff = expiryAt.difference(now);
    if (diff.inHours <= 0) return 'Expired';
    if (diff.inHours < 24) return 'Expires in ${diff.inHours} hours';
    final days = diff.inDays;
    return 'Expires in $days days';
  }

  String _planTypeLabel(PlanType type) {
    switch (type) {
      case PlanType.data:
        return 'Data';
      case PlanType.minutes:
        return 'Minutes';
      case PlanType.sms:
        return 'SMS';
    }
  }

  String _providerLabel(Provider provider) {
    switch (provider) {
      case Provider.ethio:
        return 'Ethio telecom';
      case Provider.safaricom:
        return 'Safaricom';
    }
  }

  IconData _planIcon(Plan plan) {
    switch (plan.type) {
      case PlanType.data:
        return Icons.public;
      case PlanType.minutes:
        return Icons.call;
      case PlanType.sms:
        return Icons.sms;
    }
  }

  String? _badgeForPlan(Plan plan) {
    // Check if this plan is the absolute NEXT one to expire
    final appState = AppStateScope.of(context);
    final next = _nextExpiry(appState.plans); // This re-sorts every time, inefficient but functional
    if (next != null && next.id == plan.id) {
       final hours = plan.expiryAt.difference(DateTime.now()).inHours;
       if (hours <= 24) return 'Expiring soon';
    }
    return null;
  }

  Plan? _nextExpiry(List<Plan> plans) {
    if (plans.isEmpty) return null;
    final sorted = List<Plan>.from(plans)
      ..sort((a, b) => a.expiryAt.compareTo(b.expiryAt));
    return sorted.first;
  }
}

enum _SortOption { expiry, provider, type }

enum _FilterOption { all, expiringSoon, data, minutes, sms }


class _SortMenu extends StatelessWidget {
  const _SortMenu({
    required this.value,
    required this.onChanged,
  });

  final _SortOption value;
  final ValueChanged<_SortOption?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButton<_SortOption>(
      value: value,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(
          value: _SortOption.expiry,
          child: Text('Sort: Expiry'),
        ),
        DropdownMenuItem(
          value: _SortOption.provider,
          child: Text('Sort: Network'),
        ),
        DropdownMenuItem(
          value: _SortOption.type,
          child: Text('Sort: Type'),
        ),
      ],
      onChanged: onChanged,
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.value,
    required this.onChanged,
  });

  final _FilterOption value;
  final ValueChanged<_FilterOption> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        _FilterChip(
          label: 'All',
          selected: value == _FilterOption.all,
          onTap: () => onChanged(_FilterOption.all),
        ),
        _FilterChip(
          label: 'Expiring Soon',
          selected: value == _FilterOption.expiringSoon,
          onTap: () => onChanged(_FilterOption.expiringSoon),
        ),
        _FilterChip(
          label: 'Data',
          selected: value == _FilterOption.data,
          onTap: () => onChanged(_FilterOption.data),
        ),
        _FilterChip(
          label: 'Minutes',
          selected: value == _FilterOption.minutes,
          onTap: () => onChanged(_FilterOption.minutes),
        ),
        _FilterChip(
          label: 'SMS',
          selected: value == _FilterOption.sms,
          onTap: () => onChanged(_FilterOption.sms),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            'No plans to show',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            'Pull down to refresh and parse new SMS messages.',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.nextExpiryTitle,
    required this.nextExpirySubtitle,
    required this.totalDataLabel,
    required this.totalSmsLabel,
    required this.totalMinutesLabel,
  });

  final String nextExpiryTitle;
  final String nextExpirySubtitle;
  final String totalDataLabel;
  final String totalSmsLabel;
  final String totalMinutesLabel;

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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: scheme.onPrimary.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.network_check, color: scheme.onPrimary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Next Expiry',
                          style: TextStyle(color: Color(0xFFE0E7FF))),
                      const SizedBox(height: 4),
                      Text(nextExpiryTitle,
                          style: TextStyle(
                            color: scheme.onPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        nextExpirySubtitle,
                        style: const TextStyle(color: Color(0xFFE0E7FF)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.onPrimary.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.data_usage, color: scheme.onPrimary),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text('All data remaining',
                        style: TextStyle(color: Color(0xFFE0E7FF))),
                  ),
                  Text(
                    totalDataLabel,
                    style: TextStyle(
                      color: scheme.onPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Total SMS',
                    value: totalSmsLabel,
                    icon: Icons.sms,
                    color: Colors.white,
                    onDark: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _StatTile(
                    label: 'Minutes',
                    value: totalMinutesLabel,
                    icon: Icons.phone_in_talk,
                    color: Colors.white,
                    onDark: true,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onRefresh,
  });

  final VoidCallback onRefresh;

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
            color: Color(0x120F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: InkWell(
        onTap: onRefresh,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.sync, color: scheme.primary),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Update Balance',
                        style: Theme.of(context).textTheme.titleMedium),
                    Text(
                      'Dial USSD code to fetch latest',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}



class _ProviderActionTile extends StatelessWidget {
  const _ProviderActionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: scheme.primaryContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onDark = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: onDark
            ? scheme.onPrimary.withOpacity(0.16)
            : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: onDark ? scheme.onPrimary : color),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: onDark ? const Color(0xFFE0E7FF) : null,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: onDark ? scheme.onPrimary : null,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeaderHero extends StatelessWidget {
  const _HeaderHero();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          height: 44,
          width: 44,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(Icons.shield_moon, color: scheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Welcome back',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 2),
              Text('Your network snapshot',
                  style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            'Today',
            style: TextStyle(
              color: scheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.title,
    required this.balance,
    required this.expiry,
    required this.color,
    required this.hoursToExpiry,
    required this.icon,
    this.badgeText,
    this.isNight = false,
  });

  final String title;
  final String balance;
  final String expiry;
  final Color color;
  final int hoursToExpiry;
  final IconData icon;
  final String? badgeText;
  final bool isNight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final titleColor = isNight ? Colors.red.shade700 : scheme.onSurface;
    final iconBgColor = isNight ? Colors.red.shade100 : scheme.primaryContainer;
    final iconColor = isNight ? Colors.red.shade700 : scheme.primary;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: isNight ? Colors.red.shade200 : scheme.outlineVariant),
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: titleColor,
                      fontWeight: isNight ? FontWeight.bold : null,
                    ),
                  ),
                ),
                if (badgeText != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      badgeText!,
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  balance,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.timer_outlined, size: 14, color: scheme.primary),
                      const SizedBox(width: 6),
                      Text(
                        expiry,
                        style: TextStyle(
                          color: scheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hoursToExpiry <= 24)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded,
                        size: 16, color: scheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      'Expiring today',
                      style: TextStyle(
                        color: scheme.primary,
                        fontWeight: FontWeight.w700,
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
