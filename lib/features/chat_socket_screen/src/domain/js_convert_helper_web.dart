// ignore_for_file: uri_does_not_exist, avoid_web_libraries_in_flutter
import 'dart:js_util' as js_util;

dynamic convertJsObject(dynamic data) {
  try {
    return js_util.dartify(data);
  } catch (_) {
    return data;
  }
}
