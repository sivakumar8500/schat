import 'package:url_launcher/url_launcher.dart';

void downloadFile(String url, String fileName) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
