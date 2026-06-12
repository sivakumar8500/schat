import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityEvent {
  const ConnectivityEvent();
}

class ConnectivityStarted extends ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> result;
  const ConnectivityChanged(this.result);
}
