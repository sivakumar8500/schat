import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityState {
  const ConnectivityState();
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityConnected extends ConnectivityState {
  final List<ConnectivityResult> result;
  const ConnectivityConnected(this.result);
}

class ConnectivityDisconnected extends ConnectivityState {}
