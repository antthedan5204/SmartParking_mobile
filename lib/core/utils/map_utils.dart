import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class MapUtils {
  MapUtils._();

  static Future<void> openExternalMap(double latitude, double longitude) async {
    final String googleUrl =
        'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude';
    final String appleUrl =
        'https://maps.apple.com/?daddr=$latitude,$longitude&dirflg=d';

    try {
      if (Platform.isIOS) {
        final Uri appleUri = Uri.parse(appleUrl);
        if (await canLaunchUrl(appleUri)) {
          await launchUrl(appleUri, mode: LaunchMode.externalApplication);
          return;
        }
      }

      final Uri googleUri = Uri.parse(googleUrl);
      // Try to open externally (in Maps app)
      bool launched = await launchUrl(
        googleUri,
        mode: LaunchMode.externalApplication,
      );

      // Fallback to platform default (which will open in a browser if Maps is not installed)
      if (!launched) {
        await launchUrl(googleUri, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      print('Could not open map: $e');
    }
  }
}
