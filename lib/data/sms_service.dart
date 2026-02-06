import 'dart:async';
import 'dart:io';

import 'package:sms_user_consent/sms_user_consent.dart';
import 'package:telephony/telephony.dart' as telephony;

import '../data/sms_parser.dart';
import '../domain/provider.dart';
import '../domain/sms_message.dart';

class SmsService {
  SmsService() : _telephony = telephony.Telephony.instance;

  final telephony.Telephony _telephony;
  SmsUserConsent? _smsUserConsent;
  Timer? _consentTimer;

  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return false;
    final granted = await _telephony.requestPhoneAndSmsPermissions;
    return granted ?? false;
  }

  Future<List<SmsMessage>> fetchInbox() async {
    if (!Platform.isAndroid) return [];
    try {
      final messages = await _telephony.getInboxSms(
        columns: [
          telephony.SmsColumn.ADDRESS,
          telephony.SmsColumn.BODY,
          telephony.SmsColumn.DATE,
        ],
        sortOrder: [
          telephony.OrderBy(telephony.SmsColumn.DATE, sort: telephony.Sort.DESC),
        ],
      );

      final List<SmsMessage> result = [];
      for (final message in messages) {
        final sender = message.address ?? '';
        final body = message.body ?? '';
        final provider = SmsParser.detectProvider(sender) ?? SmsParser.detectProviderFromBody(body);
        if (provider == null) continue;
        // Check supported sender if we detected by sender address
        if (SmsParser.detectProvider(sender) != null && 
            !SmsParser.isSupportedSender(sender: sender, provider: provider)) {
          continue;
        }

        final parsed = SmsParser.parseAll(sender: sender, body: body).isNotEmpty;
        result.add(
          SmsMessage(
            id: '${message.date}-${sender.hashCode}-${body.hashCode}',
            sender: sender,
            body: body,
            receivedAt: DateTime.fromMillisecondsSinceEpoch(
              message.date ?? DateTime.now().millisecondsSinceEpoch,
            ),
            provider: provider,
            parsed: parsed,
          ),
        );
      }

      return result;
    } catch (e) {
      print('Error fetching inbox: $e');
      return [];
    }
  }

  void listenIncoming({
    required void Function(SmsMessage message) onMessage,
  }) {
    if (!Platform.isAndroid) return;

    _telephony.listenIncomingSms(
      onNewMessage: (telephony.SmsMessage message) {
        final sender = message.address ?? '';
        final body = message.body ?? '';
        final provider = SmsParser.detectProvider(sender);
        if (provider == null) return;
        if (!SmsParser.isSupportedSender(sender: sender, provider: provider)) {
          return;
        }
        final parsed = SmsParser.parse(sender: sender, body: body) != null;

        onMessage(
          SmsMessage(
            id: '${message.date}-${sender.hashCode}-${body.hashCode}',
            sender: sender,
            body: body,
            receivedAt: DateTime.fromMillisecondsSinceEpoch(
              message.date ?? DateTime.now().millisecondsSinceEpoch,
            ),
            provider: provider,
            parsed: parsed,
          ),
        );
      },
      listenInBackground: false,
    );
  }

  void listenIncomingWithConsent({
    required void Function(SmsMessage message) onMessage,
  }) {
    if (!Platform.isAndroid) return;

    _smsUserConsent ??= SmsUserConsent(
      smsListener: () {
        final body = _smsUserConsent?.receivedSms ?? '';
        final parsedList = SmsParser.parseAllFromBody(body: body);
        final provider = SmsParser.detectProviderFromBody(body);
        
        // Debug aid: print received body
        print('SmsUserConsent received: $body');

        // Allow update if we either parsed valid plans OR we just detected the provider (even if regex failed)
        // This ensures the UI receives the message and rebuilds, even if "parsed" is false.
        if (parsedList.isNotEmpty || provider != null) {
          final effectiveProvider = parsedList.isNotEmpty 
              ? parsedList.first.provider 
              : (provider ?? Provider.ethio);

          onMessage(
            SmsMessage(
              id: '${DateTime.now().millisecondsSinceEpoch}-${body.hashCode}',
              sender: effectiveProvider == Provider.ethio ? '994' : 'Safaricom',
              body: body,
              receivedAt: DateTime.now(),
              provider: effectiveProvider,
              parsed: parsedList.isNotEmpty,
            ),
          );
        } else {
             print('SmsUserConsent: failed to identify provider from body: $body');
        }

        // ALWAYS restart the listener immediately after receiving a message
        _smsUserConsent?.requestSms();
      },
    );

    _startConsentLoop();
  }

  void _startConsentLoop() {
    _smsUserConsent?.requestSms();
    _consentTimer?.cancel();
    // Restart listening every 4 minutes to prevent timeout (max 5 mins)
    _consentTimer = Timer.periodic(const Duration(minutes: 4), (_) {
       _smsUserConsent?.requestSms();
    });
  }

  void dispose() {
    _consentTimer?.cancel();
    _smsUserConsent?.dispose();
  }
}
