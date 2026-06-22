import 'dart:html' as html;
import 'dart:ui_web' as ui_web;
import 'package:flutter/material.dart';

Widget createWebVideoView(String url) {
  final viewId = 'video-${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final video = html.VideoElement()
        ..src = url
        ..controls = true
        ..autoplay = false
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return video;
    },
  );
  return HtmlElementView(viewType: viewId);
}

Widget createWebDocView(String url) {
  final viewId = 'doc-${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final iframe = html.IFrameElement()
        ..src = url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%';
      return iframe;
    },
  );
  return HtmlElementView(viewType: viewId);
}

Widget createWebAudioView(String url) {
  final viewId = 'audio-${url.hashCode}';
  ui_web.platformViewRegistry.registerViewFactory(
    viewId,
    (int id) {
      final audio = html.AudioElement()
        ..src = url
        ..controls = true
        ..autoplay = false
        ..style.width = '100%'
        ..style.border = 'none'
        ..style.padding = '12px';
      return audio;
    },
  );
  return Container(
    alignment: Alignment.center,
    padding: const EdgeInsets.all(16),
    child: SizedBox(
      height: 60,
      width: 400,
      child: HtmlElementView(viewType: viewId),
    ),
  );
}
