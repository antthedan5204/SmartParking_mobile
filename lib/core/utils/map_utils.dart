import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class MapUtils {
  MapUtils._();

  static Future<void> openExternalMap(double latitude, double longitude) async {
    String googleUrl = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    String appleUrl = 'https://maps.apple.com/?sll=$latitude,$longitude';

    if (Platform.isAndroid) {
      final intentUrl = Uri.parse('google.navigation:q=$latitude,$longitude');
      if (await canLaunchUrl(intentUrl)) {
        await launchUrl(intentUrl);
      } else {
        final httpUrl = Uri.parse(googleUrl);
        if (await canLaunchUrl(httpUrl)) {
          await launchUrl(httpUrl);
        } else {
          throw 'Could not open the map.';
        }
      }
    } else if (Platform.isIOS) {
      final appleMapsUri = Uri.parse(appleUrl);
      if (await canLaunchUrl(appleMapsUri)) {
        await launchUrl(appleMapsUri);
      } else {
        final googleMapsUri = Uri.parse(googleUrl);
        if (await canLaunchUrl(googleMapsUri)) {
          await launchUrl(googleMapsUri);
        } else {
          throw 'Could not open the map.';
        }
      }
    }
  }
}
