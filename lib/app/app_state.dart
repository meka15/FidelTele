import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/sms_service.dart';
import '../data/sms_parser.dart';
import '../domain/app_settings.dart';
import '../domain/plan.dart';
import '../domain/plan_type.dart';
import '../domain/provider.dart';
import '../domain/sms_message.dart';

class AppState extends ChangeNotifier {
  AppState() : _smsService = SmsService();

  final SmsService _smsService;
  bool _initialized = false;
  bool _permissionGranted = false;
  bool _isLoading = false;

  AppSettings settings = AppSettings(
    ethioEnabled: true,
    safaricomEnabled: true,
    alertsEnabled: true,
    lowBalanceThresholdPct: 0.2,
    expiryWarningHours: 24,
  );

  final List<SmsMessage> _messages = [];
  final List<Plan> _plans = [];

  bool get permissionGranted => _permissionGranted;
  bool get isLoading => _isLoading;
  bool get isAndroid => Platform.isAndroid;

  List<SmsMessage> get messages => List.unmodifiable(_messages);
  List<Plan> get plans => List.unmodifiable(_plans);

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    if (!Platform.isAndroid) {
      _permissionGranted = false;
      notifyListeners();
      return;
    }
    await requestPermissions();
  }

  Future<void> requestPermissions() async {
    _isLoading = true;
    notifyListeners();
    final granted = await _smsService.requestPermissions();
    _permissionGranted = granted;
    if (granted) {
      await _loadMessages();
      _listenIncoming();
    } else {
      _listenIncomingWithConsent();
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> refresh() async {
    _isLoading = true;
    notifyListeners();
    // Re-verify permissions or just load? Best to just load if we have them.
    if (_permissionGranted) {
      await _loadMessages();
    } else {
      // If we are in consent mode, we can't "pull" messages, 
      // but we can ensure the listener is active.
      _smsService.listenIncomingWithConsent(onMessage: (message) {
          _messages.insert(0, message);
          _rebuildPlans();
          notifyListeners();
      });
      // Also maybe just try parsing existing body if we had one? 
      // Actually strictly speaking we can't 'refresh' without READ_SMS 
      // except for processing any pending state or re-parsing.
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _loadMessages() async {
    final messages = await _smsService.fetchInbox();
    _messages
      ..clear()
      ..addAll(messages);
    _rebuildPlans();
  }

  void _listenIncoming() {
    _smsService.listenIncoming(onMessage: (_) {
      // Small delay to ensure the OS has written the message to the database
      Future.delayed(const Duration(seconds: 1), () {
        _loadMessages().then((_) {
          notifyListeners();
        });
      });
    });
  }

  void _listenIncomingWithConsent() {
    _smsService.listenIncomingWithConsent(onMessage: (message) {
      _messages.insert(0, message);
      _rebuildPlans();
      notifyListeners();
      print("AppState: Consent message processed locally.");
    });
  }

  void addMessage({
    required String id,
    required String sender,
    required String body,
    required DateTime receivedAt,
  }) {
    final parsed = SmsParser.parseAll(sender: sender, body: body).isNotEmpty;
    final provider = SmsParser.detectProvider(sender) ?? Provider.ethio;

    _messages.insert(
      0,
      SmsMessage(
        id: id,
        sender: sender,
        body: body,
        receivedAt: receivedAt,
        provider: provider,
        parsed: parsed,
      ),
    );
    _rebuildPlans();
    notifyListeners();
  }

  void removeMessage(String id) {
    _messages.removeWhere((message) => message.id == id);
    _rebuildPlans();
    notifyListeners();
  }

  void updateSettings(AppSettings updated) {
    settings = updated;
    // Rebuild plans in case provider visibility changed
    _rebuildPlans();
    notifyListeners();
  }

  ProviderSummary totalSummary() {
    final data = _plans.where((plan) => plan.type == PlanType.data);
    final totalGb = data.fold<double>(0, (sum, plan) {
      return sum + _toGb(plan.balanceValue, plan.balanceUnit);
    });
    return ProviderSummary(
      name: 'All Providers',
      totalData: _formatGb(totalGb),
      minutes: _formatMinutes(_totalByType(PlanType.minutes)),
      sms: _formatSms(_totalByType(PlanType.sms)),
      provider: null,
    );
  }

  List<ProviderSummary> providerSummaries() {
    final Map<Provider, List<Plan>> byProvider = {};
    for (final plan in _plans) {
      byProvider.putIfAbsent(plan.provider, () => []).add(plan);
    }

    return byProvider.entries.map((entry) {
      final data = entry.value.where((plan) => plan.type == PlanType.data);
      final totalGb = data.fold<double>(0, (sum, plan) {
        return sum + _toGb(plan.balanceValue, plan.balanceUnit);
      });
      return ProviderSummary(
        name: _providerLabel(entry.key),
        totalData: _formatGb(totalGb),
        minutes: _formatMinutes(
            _totalByType(PlanType.minutes, plans: entry.value)),
        sms: _formatSms(_totalByType(PlanType.sms, plans: entry.value)),
        provider: entry.key,
      );
    }).toList();
  }

  double _totalByType(PlanType type, {List<Plan>? plans}) {
    final source = plans ?? _plans;
    return source
        .where((plan) => plan.type == type)
        .fold(0, (sum, plan) => sum + plan.balanceValue);
  }

  void _rebuildPlans() {
    _plans.clear();
    final Map<String, Plan> deduped = {};

    final Map<Provider, SmsMessage> latestSnapshots = {};
    for (final message in _messages) {
      final provider = SmsParser.detectProvider(message.sender);
      if (provider == null) continue;
      
      // Respect user settings for disabling providers
      if (provider == Provider.ethio && !settings.ethioEnabled) continue;
      if (provider == Provider.safaricom && !settings.safaricomEnabled) continue;

      if (provider == Provider.ethio) {
        if (!SmsParser.hasUnitIndicators(message.body)) continue;
      } else {
        if (!SmsParser.isSnapshotMessage(message.body)) continue;
        if (!SmsParser.hasBalanceIndicators(message.body)) continue;
      }

      final existing = latestSnapshots[provider];
      if (existing == null || message.receivedAt.isAfter(existing.receivedAt)) {
        latestSnapshots[provider] = message;
      }
    }

    final String? ethioSnapshotBody = _composeEthioSnapshotBody(
      latestSnapshots[Provider.ethio],
    );

    for (final message in _messages) {
      final provider = SmsParser.detectProvider(message.sender);
      if (provider == null) continue;

      // Respect user settings for disabling providers
      if (provider == Provider.ethio && !settings.ethioEnabled) continue;
      if (provider == Provider.safaricom && !settings.safaricomEnabled) continue;

      final snapshot = latestSnapshots[provider];
      if (snapshot != null && snapshot.id != message.id) {
        continue;
      }

      final String bodyToParse;
      if (provider == Provider.ethio &&
          ethioSnapshotBody != null &&
          snapshot != null &&
          snapshot.id == message.id) {
        bodyToParse = ethioSnapshotBody;
      } else {
        bodyToParse = message.body;
      }

      final parsedList = SmsParser.parseAll(
        sender: message.sender,
        body: bodyToParse,
      );
      if (parsedList.isEmpty) continue;

      for (final parsed in parsedList) {
        DateTime expiry = _expiryFromLabel(parsed.expiryLabel);
        // If parsing fails (returns default/past), try to infer from message receipt time
        // if the label was actually unknown/missing. 
        // We use a fallback of received + 24 hours for messages without explicit expiry.
        if (expiry.year == 1970) {
           expiry = message.receivedAt.add(const Duration(hours: 24));
        }

        if (expiry.isBefore(DateTime.now())) {
          continue;
        }

        final labelPart = parsed.label ?? 'Standard';
        String dedupeKey =
            '${parsed.provider}-${parsed.type}-${labelPart}-${expiry.toIso8601String()}';
        
        // Handle collision within the same message (e.g. overlapping similar plans)
        // Though label should distinguish most (e.g. Night vs Student)
        int suffix = 2;
        while (deduped.containsKey(dedupeKey)) {
          final existing = deduped[dedupeKey]!;
          if (existing.sourceMessageId == message.id) {
             dedupeKey = '${parsed.provider}-${parsed.type}-${labelPart}-${expiry.toIso8601String()}-$suffix';
             suffix++;
          } else {
            break;
          }
        }

        final plan = Plan(
          id: dedupeKey,
          provider: parsed.provider,
          type: parsed.type,
          balanceValue: parsed.balanceValue,
          balanceUnit: parsed.balanceUnit,
          expiryAt: expiry,
          lastUpdatedAt: message.receivedAt,
          label: parsed.label,
          totalValue: null,
          sourceMessageId: message.id,
        );

        final existing = deduped[dedupeKey];
        if (existing == null) {
          deduped[dedupeKey] = plan;
          continue;
        }

        if (plan.lastUpdatedAt.isAfter(existing.lastUpdatedAt)) {
          deduped[dedupeKey] = plan;
        }
      }
    }

    _plans.addAll(deduped.values);
  }

  String? _composeEthioSnapshotBody(SmsMessage? endMessage) {
    if (endMessage == null) return null;
    SmsMessage resolvedEnd = endMessage;
    if (!SmsParser.isEthioSnapshotEnd(resolvedEnd.body)) {
      return resolvedEnd.body;
    }

    final ethioMessages = _messages
        .where((m) => SmsParser.detectProvider(m.sender) == Provider.ethio)
        .toList()
      ..sort((a, b) => a.receivedAt.compareTo(b.receivedAt));

    int endIndex = ethioMessages.indexWhere((m) => m.id == resolvedEnd.id);
    if (endIndex == -1) return resolvedEnd.body;

    if (!SmsParser.hasUnitIndicators(resolvedEnd.body)) {
      for (int i = endIndex - 1; i >= 0; i--) {
        final candidate = ethioMessages[i];
        if (!SmsParser.hasUnitIndicators(candidate.body)) continue;
        resolvedEnd = candidate;
        endIndex = i;
        break;
      }
    }

    int startIndex = endIndex;
    for (int i = endIndex; i >= 0; i--) {
      final message = ethioMessages[i];
      final diff = resolvedEnd.receivedAt.difference(message.receivedAt);
      if (diff.inMinutes > 10) break;
      if (SmsParser.isEthioSnapshotStart(message.body)) {
        startIndex = i;
        break;
      }
    }

    final buffer = StringBuffer();
    for (int i = startIndex; i <= endIndex; i++) {
      buffer.write(ethioMessages[i].body.trim());
      buffer.write(' ');
    }
    return buffer.toString().trim();
  }

  DateTime _expiryFromLabel(String label) {
    final normalized = label.trim();

    // Try yyyy-MM-dd or yyyy/MM/dd with optional Time
    // e.g. "2026-02-06 at 13:41:10" or "2026-02-06 13:41"
    final matchYMD = RegExp(r'(\d{4})[-\/](\d{1,2})[-\/](\d{1,2})(?:(?: at |[ T])(\d{1,2}):(\d{1,2})(?::(\d{1,2}))?)?').firstMatch(normalized);
    if (matchYMD != null) {
      final y = int.parse(matchYMD.group(1)!);
      final m = int.parse(matchYMD.group(2)!);
      final d = int.parse(matchYMD.group(3)!);
      
      int h = 23;
      int min = 59;
      int s = 59;
      
      if (matchYMD.group(4) != null) {
        h = int.parse(matchYMD.group(4)!);
        min = int.parse(matchYMD.group(5)!);
        if (matchYMD.group(6) != null) {
          s = int.parse(matchYMD.group(6)!);
        } else {
          s = 0;
        }
      }
      
      return DateTime(y, m, d, h, min, s);
    }

    // Try dd-MM-yyyy or dd/MM/yyyy
    final matchDMY = RegExp(r'(\d{1,2})[-\/](\d{1,2})[-\/](\d{4})').firstMatch(normalized);
    if (matchDMY != null) {
      final d = int.parse(matchDMY.group(1)!);
      final m = int.parse(matchDMY.group(2)!);
      final y = int.parse(matchDMY.group(3)!);
      // Fallback to end of day if time is missing for this format (less common)
      return DateTime(y, m, d, 23, 59, 59);
    }

    // Return sentinel for "unknown/unparseable"
    return DateTime(1970);
  }

  double _toGb(double value, String unit) {
    final upper = unit.toUpperCase();
    if (upper == 'MB') return value / 1024;
    return value;
  }

  String _formatGb(double valueBytesOrGb) {
    // Current input is GB.
    if (!settings.showInGb) {
      final mb = valueBytesOrGb * 1024;
      return '${mb.toStringAsFixed(0)} MB';
    }
    return '${valueBytesOrGb.toStringAsFixed(2)} GB';
  }

  String _formatMinutes(double value) {
    return '${value.toStringAsFixed(0)} min';
  }

  String _formatSms(double value) {
    return '${value.toStringAsFixed(0)} SMS';
  }

  String _providerLabel(Provider provider) {
    switch (provider) {
      case Provider.ethio:
        return 'Ethio telecom';
      case Provider.safaricom:
        return 'Safaricom';
    }
  }
}

class ProviderSummary {
  ProviderSummary({
    required this.name,
    required this.totalData,
    required this.minutes,
    required this.sms,
    required this.provider,
  });

  final String name;
  final String totalData;
  final String minutes;
  final String sms;
  final Provider? provider;
}
