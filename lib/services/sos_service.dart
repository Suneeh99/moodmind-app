import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../models/emergency_contact_model.dart';

class SosService {
  /// Sends an SOS for free using local apps (SMS composer / WhatsApp / share sheet / dialer).
  static Future<bool> sendSOS({
    required List<EmergencyContact> contacts,
    required String message,
  }) async {
    if (contacts.isEmpty) return false;

    // Limit to 3 recipients (UI-friendly)
    final to = contacts.take(3).map((c) => c.phoneNumber).toList();

    // 1) Try native SMS composer (group; fall back to per-recipient)
    if (await _sendSms(to, message)) return true;

    // 2) Try WhatsApp (one-by-one)
    for (final n in to) {
      if (await _sendWhatsApp(n, message)) return true;
    }

    // 3) Share sheet fallback (user picks app: Messenger, Telegram, Email, etc.)
    try {
      await Share.share(message);
      return true;
    } catch (_) {}

    // 4) Final fallback: open dialer to first contact
    final first = to.first;
    final tel = Uri(scheme: 'tel', path: first);
    if (await canLaunchUrl(tel)) {
      return await launchUrl(tel, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> _sendSms(List<String> recipients, String message) async {
    if (recipients.isEmpty) return false;
    final body = Uri.encodeComponent(message);

    // Many devices accept comma-separated numbers for group compose
    final numbers = recipients.join(',');
    final groupUri = Uri.parse('sms:$numbers?body=$body');
    if (await canLaunchUrl(groupUri)) {
      if (await launchUrl(groupUri, mode: LaunchMode.externalApplication)) {
        return true;
      }
    }

    // Fallback: open composer per-recipient until one succeeds
    for (final n in recipients) {
      final single = Uri.parse('sms:$n?body=$body');
      if (await canLaunchUrl(single)) {
        if (await launchUrl(single, mode: LaunchMode.externalApplication)) {
          return true;
        }
      }
    }
    return false;
  }

  static Future<bool> _sendWhatsApp(String phone, String message) async {
    final text = Uri.encodeComponent(message);
    final wa = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    if (await canLaunchUrl(wa)) {
      return await launchUrl(wa, mode: LaunchMode.externalApplication);
    }
    // Web fallback (opens WhatsApp Web/app)
    final waWeb = Uri.parse('https://wa.me/$phone?text=$text');
    if (await canLaunchUrl(waWeb)) {
      return await launchUrl(waWeb, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
