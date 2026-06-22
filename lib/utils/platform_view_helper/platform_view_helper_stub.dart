import 'package:flutter/material.dart';

Widget createWebVideoView(String url) {
  return const Center(
    child: Text(
      'In-app video playback is not supported on this platform.',
      style: TextStyle(color: Colors.white70),
    ),
  );
}

Widget createWebDocView(String url) {
  return const Center(
    child: Text(
      'In-app document viewing is not supported on this platform.',
      style: TextStyle(color: Colors.white70),
    ),
  );
}

Widget createWebAudioView(String url) {
  return const Center(
    child: Text(
      'In-app audio playback is not supported on this platform.',
      style: TextStyle(color: Colors.white70),
    ),
  );
}
