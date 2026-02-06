import '../domain/plan_type.dart';
import '../domain/provider.dart';

class ParsedSms {
  ParsedSms({
    required this.provider,
    required this.type,
    required this.balanceValue,
    required this.balanceUnit,
    required this.expiryLabel,
    this.label,
  });

  final Provider provider;
  final PlanType type;
  final double balanceValue;
  final String balanceUnit;
  final String expiryLabel;
  final String? label;
}

class SmsParser {
  static const _ethioSender = '994';
  static const _ethioCountrySender = '251994';

  static bool isSnapshotMessage(String body) {
    final lower = body.toLowerCase();
    return lower.contains('your current airtime balance') ||
        lower.contains('current airtime balance') ||
        lower.contains('thank you');
  }

  static bool isEthioSnapshotStart(String body) {
    return body.toLowerCase().contains('dear customer');
  }

  static bool isEthioSnapshotEnd(String body) {
    final lower = body.toLowerCase();
    return lower.contains('thank you') && lower.contains('ethio');
  }

  static bool hasBalanceIndicators(String body) {
    final lower = body.toLowerCase();
    return lower.contains('mb') ||
        lower.contains('gb') ||
        lower.contains('min') ||
        lower.contains('sms') ||
        lower.contains('balance') ||
        lower.contains('remaining');
  }

  static bool hasUnitIndicators(String body) {
    final lower = body.toLowerCase();
    return lower.contains('mb') ||
        lower.contains('gb') ||
        lower.contains('min') ||
        lower.contains('sms');
  }

  static bool hasExpiryIndicators(String body) {
    final lower = body.toLowerCase();
    return lower.contains('expiry') ||
        lower.contains('expired on') ||
        lower.contains('valid until') ||
        RegExp(r'\d{4}-\d{2}-\d{2}').hasMatch(body) ||
        RegExp(r'\d{2}/\d{2}/\d{4}').hasMatch(body);
  }


  static bool isSupportedSender({required String sender, required Provider provider}) {
    final normalized = _normalizeSender(sender);
    switch (provider) {
      case Provider.ethio:
        return normalized == _ethioSender || normalized == _ethioCountrySender;
      case Provider.safaricom:
        return normalized == 'safaricom' || normalized.contains('safaricom');
    }
  }

  static ParsedSms? parse({required String sender, required String body}) {
    final all = parseAll(sender: sender, body: body);
    if (all.isEmpty) return null;
    return all.first;
  }

  static List<ParsedSms> parseAll({required String sender, required String body}) {
    final normalizedBody = body.trim();
    final normalizedSender = sender.trim();

    final Provider? provider = detectProvider(normalizedSender);
    if (provider == null) return [];

    if (!isSupportedSender(sender: normalizedSender, provider: provider)) {
      return [];
    }

    final segments = _splitSegments(normalizedBody);
    final List<ParsedSms> results = [];

    for (final segment in segments) {
      if (segment.isEmpty) continue;
      if (_isPromoSegment(segment)) continue;
      if (_isIgnoredPackageSegment(segment)) continue;
      if (_isDepletedSegment(segment)) continue;

      final expiry = _extractExpiry(segment);
      final matches = _extractBalances(segment);
      if (matches.isEmpty) continue;

      for (final match in matches) {
        final type = _detectPlanTypeFromUnit(match.unit);
        if (type == null) continue;

        // Prefer label found in the balance match (e.g. "Besh Combo": 500MB)
        // Fallback to segment-wide keyword search
        final combinedLabel = match.label ?? _extractLabel(segment);

        results.add(
          ParsedSms(
            provider: provider,
            type: type,
            balanceValue: match.value,
            balanceUnit: match.unit,
            expiryLabel: expiry,
            label: combinedLabel,
          ),
        );
      }
    }

    return results;
  }

  static Provider? detectProvider(String sender) {
    final normalized = _normalizeSender(sender);
    if (normalized == _ethioSender || normalized == _ethioCountrySender) {
      return Provider.ethio;
    }
    final lower = sender.toLowerCase();
    if (lower.contains('safaricom')) return Provider.safaricom;
    return null;
  }

  static Provider? detectProviderFromBody(String body) {
    final lower = body.toLowerCase();
    if (lower.contains('ethio') || lower.contains('dear customer') || lower.contains('airtime balance')) return Provider.ethio;
    if (lower.contains('safaricom')) return Provider.safaricom;
    return null;
  }

  static List<ParsedSms> parseAllFromBody({required String body}) {
    final provider = detectProviderFromBody(body);
    if (provider == null) return [];
    final sender = provider == Provider.ethio ? _ethioSender : 'safaricom';
    return parseAll(sender: sender, body: body);
  }

  static String _normalizeSender(String sender) {
    final digitsOnly = sender.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.isEmpty) return sender.trim().toLowerCase();
    return digitsOnly;
  }


  static PlanType? _detectPlanTypeFromUnit(String unit) {
    final upper = unit.toUpperCase();
    if (upper == 'SMS' || upper == 'SM') return PlanType.sms;
    if (upper == 'MIN' || upper == 'MINS' || upper == 'MINUTE' || upper == 'MINUTES') {
      return PlanType.minutes;
    }
    if (upper == 'MB' || upper == 'GB') return PlanType.data;
    return null;
  }

  static String _extractExpiry(String body) {
    final expiryPatterns = [
      RegExp(r'valid until\s*([\w\-: ]+)', caseSensitive: false),
      RegExp(r'expiry\s*date[:\s]*([\d\-:/ ]+)', caseSensitive: false),
      RegExp(r'expiry[:\s]*([\d\-:/ ]+)', caseSensitive: false),
      RegExp(r'expires?\s*(on|in)?\s*([\w\-: ]+)', caseSensitive: false),
    ];

    for (final pattern in expiryPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final expiry = (match.group(1) ?? match.group(2) ?? '').trim();
        if (expiry.isNotEmpty) return expiry;
      }
    }

    return 'Unknown expiry';
  }

  static String? _extractLabel(String segment) {
    final lower = segment.toLowerCase();
    
    // Check for explicit "Night" markers
    if (lower.contains('night')) return 'Night';

    // Student pack often contains separate voice/night voice - but label might match both?
    // If it contains "night bonus", it returns Night used above.
    
    if (lower.contains('student')) return 'Student';
    if (lower.contains('daily')) return 'Daily';
    if (lower.contains('weekly')) return 'Weekly';
    if (lower.contains('monthly')) return 'Monthly';
    if (lower.contains('unlimited')) return 'Unlimited';
    if (lower.contains('premium')) return 'Premium';
    if (lower.contains('voice') || lower.contains('mins') || lower.contains('minutes')) return 'Voice';
    if (lower.contains('data') || lower.contains('internet')) return 'Data';
    // Add logic to catch SMS context if missed
    if (lower.contains('sms') || lower.contains('message')) return 'SMS';

    return null;
  }

  static bool _isPromoSegment(String segment) {
    if (segment.toLowerCase().contains(' is ')) return false;
    final lower = segment.toLowerCase();
    return _promoPhrases.any(lower.contains);
  }

  static bool _isDepletedSegment(String segment) {
    final lower = segment.toLowerCase();
    return lower.contains('exhausted') ||
        lower.contains('depleted') ||
        lower.contains('used up') ||
        lower.contains('finished') ||
        lower.contains('consumed');
  }

  static bool _isIgnoredPackageSegment(String segment) {
    final lower = segment.toLowerCase();
    // Removed 'gursha' and 'opera mini' if user wants to see them.
    return lower.contains('successfully purchased') ||
        lower.contains('valid for') ||
        lower.contains('night data package');
  }

  static bool _isDataBalanceContext(String segment) {
    final lower = segment.toLowerCase();
    return lower.contains('balance') ||
        lower.contains('remaining') ||
        lower.contains('expiry') ||
        lower.contains('valid') ||
        lower.contains('credit') ||
        lower.contains('daily') ||
        lower.contains('combo') ||
        lower.contains('besh') ||
        lower.contains('opera') ||
        lower.contains('minutes') ||
        lower.contains('sms');
  }

  static List<String> _splitSegments(String body) {
    final normalized = body.replaceAll(RegExp(r'[\n\r]+'), ' ');
    final primaryParts = normalized.split(RegExp(r'[.;]\s+'));
    final List<String> segments = [];

    for (final part in primaryParts) {
      final trimmed = part.trim();
      if (trimmed.isEmpty) continue;
      final subParts = trimmed.split(
        RegExp(
          r'(?=(Dear customer|Dear Customer|Dear Customer\.|Free |Daily |Combo |Besh |Gursha|Night Data Package|You have successfully purchased|Recharge of|Your Daily|Your Night|your remaining amount))',
          caseSensitive: false,
        ),
      );
      for (final sub in subParts) {
        final cleaned = sub.trim();
        if (cleaned.isNotEmpty) segments.add(cleaned);
      }
    }

    return segments;
  }

  static List<_BalanceMatch> _extractBalances(String body) {
    // 1. Check for Safaricom style "Label: Value Unit"
    // e.g. "Besh Combo: 836.64 MB" or "Daily Safaricom Minutes: 25 ..."
    final colonMatch = RegExp(r'([^:;\.\n]+?):\s*(\d+(?:\.\d+)?)\s*(MB|GB|Minutes?|Mins?|SMS)', caseSensitive: false).firstMatch(body);
    if (colonMatch != null) {
      final rawLabel = colonMatch.group(1)?.trim();
      final value = double.tryParse(colonMatch.group(2) ?? '0');
      final rawUnit = colonMatch.group(3)?.toUpperCase() ?? '';
      
      // Filter out labels that are just "Balance" or "Remaining"
      String? label = rawLabel;
      if (label != null) {
        final lowerL = label.toLowerCase();
        if (lowerL.contains('balance') || lowerL.contains('remaining') || lowerL.contains('expiry')) {
           label = null; 
        }
      }

      final unit = rawUnit.endsWith('S') ? rawUnit.substring(0, rawUnit.length - 1) : rawUnit;
      if (value != null && value > 0) {
         return [_BalanceMatch(value: value, unit: unit, label: label)];
      }
    }

    // 2. Fallback to Ethio / Generic extraction
    String textToSearch = body;
    final lower = body.toLowerCase();
    
    // ETHIO FILTER: 
    if (lower.trim().startsWith('from ') && !lower.contains(' is ') && !lower.contains('balance')) {
       return [];
    }

    final isIndex = body.toLowerCase().lastIndexOf(' is ');
    if (isIndex != -1) {
      textToSearch = body.substring(isIndex);
    } else {
       final colonIndex = body.indexOf(':');
       if (colonIndex != -1) {
        final prefix = body.substring(0, colonIndex).toLowerCase();
        if (prefix.contains('balance') || prefix.contains('remaining')) {
           textToSearch = body.substring(colonIndex);
        }
      }
    }

    final List<_BalanceMatch> matches = [];
    final patterns = [
      RegExp(r'(?:balance|remaining)[:\s]*(\d+(?:\.\d+)?)\s*(gbs?|mbs?)\b', caseSensitive: false),
      RegExp(r'(?:balance|remaining)[:\s]*(\d+(?:\.\d+)?)\s*(mins?|minutes?)\b', caseSensitive: false),
      RegExp(r'(?:balance|remaining)[:\s]*(\d+(?:\.\d+)?)\s*(sms)\b', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*(gbs?|mbs?)\b', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*(?:safaricom\s+)?(mins?|minutes?|minute)\b', caseSensitive: false),
      RegExp(r'(\d+(?:\.\d+)?)\s*(sms)\b', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      for (final match in pattern.allMatches(textToSearch)) {
        final value = double.tryParse(match.group(1) ?? '');
        final rawUnit = match.group(2)?.toUpperCase() ?? '';
        
        // Don't strip 'S' from 'SMS', but do strip from 'MINUTES' -> 'MINUTE'
        final String unit;
        if (rawUnit == 'SMS') {
          unit = 'SMS';
        } else {
          unit = rawUnit.endsWith('S') ? rawUnit.substring(0, rawUnit.length - 1) : rawUnit;
        }

        if (value != null && unit.isNotEmpty) {
          if (value <= 0) continue;
          if ((unit == 'MB' || unit == 'GB') && !_isDataBalanceContext(body)) continue;
          matches.add(_BalanceMatch(value: value, unit: unit));
        }
      }
    }

    final bool hasMb = matches.any((m) => m.unit == 'MB');
    final bool hasGb = matches.any((m) => m.unit == 'GB');
    if (hasMb && hasGb) {
      return matches.where((m) => m.unit != 'GB').toList();
    }

    return matches;
  }

  static const _promoPhrases = [
    'receive international calls',
    'thank you for choosing safaricom',
    'get 1gb data for free',
    'to get',
    'mega internet',
    'packages',
    'dial *777',
    'bit.ly',
    'click http',
    'for free',
    'offer',
    'promo',
  ];
}

class _BalanceMatch {
  _BalanceMatch({required this.value, required this.unit, this.label});

  final double value;
  final String unit;
  final String? label;
}
