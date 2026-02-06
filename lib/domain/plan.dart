import 'plan_type.dart';
import 'provider.dart';

class Plan {
  Plan({
    required this.id,
    required this.provider,
    required this.type,
    required this.balanceValue,
    required this.balanceUnit,
    required this.expiryAt,
    required this.lastUpdatedAt,
    this.label,
    this.totalValue,
    this.sourceMessageId,
  });

  final String id;
  final Provider provider;
  final PlanType type;
  final double balanceValue;
  final String balanceUnit;
  final String? label;
  final double? totalValue;
  final DateTime expiryAt;
  final DateTime lastUpdatedAt;
  final String? sourceMessageId;
}
