import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

/// Singleton service for handling communication actions
/// Provides call, SMS, and WhatsApp functionality
class CommunicationService {
  static final CommunicationService _instance = CommunicationService._internal();
  
  factory CommunicationService() => _instance;
  static CommunicationService get instance => _instance;
  
  CommunicationService._internal();

  /// Format phone number for URL schemes
  /// Removes spaces, dashes, and ensures proper format
  String _formatPhoneNumber(String phone) {
    // Remove all non-digit characters except + at the beginning
    String cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If number doesn't start with + or country code, assume India (+91)
    if (!cleaned.startsWith('+') && !cleaned.startsWith('91')) {
      // If it's a 10-digit number, add India country code
      if (cleaned.length == 10) {
        cleaned = '91$cleaned';
      }
    }
    
    // Remove leading + if present for WhatsApp API
    return cleaned.replaceFirst('+', '');
  }

  /// Make a phone call to the given number
  /// Opens the device's phone dialer with the number pre-filled
  Future<bool> makeCall(String phoneNumber, {BuildContext? context}) async {
    if (phoneNumber.isEmpty) {
      _showError(context, 'Phone number not available');
      return false;
    }

    final Uri uri = Uri(scheme: 'tel', path: phoneNumber);
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        _showError(context, 'Could not open phone dialer');
        return false;
      }
    } catch (e) {
      debugPrint('[CommunicationService] Call error: $e');
      _showError(context, 'Could not make call');
      return false;
    }
  }

  /// Send an SMS to the given number
  /// Opens the device's messaging app with the number pre-filled
  Future<bool> sendSms(String phoneNumber, {String? message, BuildContext? context}) async {
    if (phoneNumber.isEmpty) {
      _showError(context, 'Phone number not available');
      return false;
    }

    Uri uri;
    if (message != null && message.isNotEmpty) {
      // Include message body in the URI
      uri = Uri(
        scheme: 'sms',
        path: phoneNumber,
        queryParameters: {'body': message},
      );
    } else {
      uri = Uri(scheme: 'sms', path: phoneNumber);
    }
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return true;
      } else {
        _showError(context, 'Could not open messaging app');
        return false;
      }
    } catch (e) {
      debugPrint('[CommunicationService] SMS error: $e');
      _showError(context, 'Could not send message');
      return false;
    }
  }

  /// Open WhatsApp chat with the given number
  /// Uses WhatsApp's URL scheme to open a chat
  Future<bool> openWhatsApp(String phoneNumber, {String? message, BuildContext? context}) async {
    if (phoneNumber.isEmpty) {
      _showError(context, 'Phone number not available');
      return false;
    }

    final formattedNumber = _formatPhoneNumber(phoneNumber);
    
    // Use wa.me URL (works on both mobile and desktop)
    String url;
    if (message != null && message.isNotEmpty) {
      url = 'https://wa.me/$formattedNumber?text=${Uri.encodeComponent(message)}';
    } else {
      url = 'https://wa.me/$formattedNumber';
    }
    
    final Uri uri = Uri.parse(url);
    
    try {
      // Launch directly without canLaunchUrl check
      // canLaunchUrl requires URL schemes to be declared in AndroidManifest/Info.plist
      // and may return false even when WhatsApp is installed
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (launched) {
        return true;
      }
      
      // Try with whatsapp:// scheme as fallback
      final fallbackUri = Uri.parse('whatsapp://send?phone=$formattedNumber');
      final fallbackLaunched = await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      if (fallbackLaunched) {
        return true;
      }
      
      _showError(context, 'Could not open WhatsApp');
      return false;
    } catch (e) {
      debugPrint('[CommunicationService] WhatsApp error: $e');
      _showError(context, 'Could not open WhatsApp');
      return false;
    }
  }

  /// Show error snackbar if context is available
  void _showError(BuildContext? context, String message) {
    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
    }
  }
}

/// Reusable widget showing call, message, and WhatsApp action buttons
/// Can be used in any list item or detail page
class CommunicationActionButtons extends StatelessWidget {
  final String phoneNumber;
  final double iconSize;
  final double spacing;
  final Color? callColor;
  final Color? smsColor;
  final Color? whatsAppColor;
  final String? defaultMessage;
  final bool showLabels;

  const CommunicationActionButtons({
    super.key,
    required this.phoneNumber,
    this.iconSize = 20,
    this.spacing = 8,
    this.callColor,
    this.smsColor,
    this.whatsAppColor,
    this.defaultMessage,
    this.showLabels = false,
  });

  @override
  Widget build(BuildContext context) {
    final service = CommunicationService.instance;
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call button
        _ActionButton(
          icon: Icons.call_rounded,
          color: callColor ?? const Color(0xFF2E7D32),
          label: showLabels ? 'Call' : null,
          onTap: () => service.makeCall(phoneNumber, context: context),
          iconSize: iconSize,
        ),
        SizedBox(width: spacing),
        // SMS button
        _ActionButton(
          icon: Icons.message_rounded,
          color: smsColor ?? const Color(0xFF1976D2),
          label: showLabels ? 'SMS' : null,
          onTap: () => service.sendSms(phoneNumber, message: defaultMessage, context: context),
          iconSize: iconSize,
        ),
        SizedBox(width: spacing),
        // WhatsApp button
        _ActionButton(
          icon: FontAwesomeIcons.whatsapp,
          color: whatsAppColor ?? const Color(0xFF25D366),
          label: showLabels ? 'WhatsApp' : null,
          onTap: () => service.openWhatsApp(phoneNumber, message: defaultMessage, context: context),
          iconSize: iconSize,
          isWhatsApp: true,
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String? label;
  final VoidCallback onTap;
  final double iconSize;
  final bool isWhatsApp;

  const _ActionButton({
    required this.icon,
    required this.color,
    this.label,
    required this.onTap,
    required this.iconSize,
    this.isWhatsApp = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: label != null
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, color: color, size: iconSize),
                    const SizedBox(height: 4),
                    Text(
                      label!,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
              : Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

/// Compact horizontal action icons (for list items)
class CommunicationActionIcons extends StatelessWidget {
  final String phoneNumber;
  final double iconSize;
  final double containerSize;
  final double spacing;

  const CommunicationActionIcons({
    super.key,
    required this.phoneNumber,
    this.iconSize = 16,
    this.containerSize = 32,
    this.spacing = 6,
  });

  @override
  Widget build(BuildContext context) {
    final service = CommunicationService.instance;
    
    if (phoneNumber.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Call icon
        _CompactActionIcon(
          icon: Icons.call_rounded,
          color: const Color(0xFF2E7D32),
          onTap: () => service.makeCall(phoneNumber, context: context),
          iconSize: iconSize,
          containerSize: containerSize,
        ),
        SizedBox(width: spacing),
        // SMS icon
        _CompactActionIcon(
          icon: Icons.message_rounded,
          color: const Color(0xFF1976D2),
          onTap: () => service.sendSms(phoneNumber, context: context),
          iconSize: iconSize,
          containerSize: containerSize,
        ),
        SizedBox(width: spacing),
        // WhatsApp icon
        _CompactActionIcon(
          icon: FontAwesomeIcons.whatsapp,
          color: const Color(0xFF25D366),
          onTap: () => service.openWhatsApp(phoneNumber, context: context),
          iconSize: iconSize,
          containerSize: containerSize,
        ),
      ],
    );
  }
}

class _CompactActionIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;
  final double containerSize;

  const _CompactActionIcon({
    required this.icon,
    required this.color,
    required this.onTap,
    required this.iconSize,
    required this.containerSize,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: containerSize,
        height: containerSize,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: iconSize),
      ),
    );
  }
}
