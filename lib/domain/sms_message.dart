import 'provider.dart';

class SmsMessage {
  SmsMessage({
    required this.id,
    required this.sender,
    required this.body,
    required this.receivedAt,
    required this.provider,
    this.parsed = false,
  });

  final String id;
  final String sender;
  final String body;
  final DateTime receivedAt;
  final Provider provider;
  final bool parsed;
}
