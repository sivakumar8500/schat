import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:injectable/injectable.dart';

abstract class ConnectivityRepository {
  Stream<List<ConnectivityResult>> get onConnectivityChanged;
  Future<List<ConnectivityResult>> get currentConnectivity;
}

@LazySingleton(as: ConnectivityRepository)
class ConnectivityRepositoryImpl implements ConnectivityRepository {
  final Connectivity _connectivity;

  ConnectivityRepositoryImpl(this._connectivity);

  @override
  Stream<List<ConnectivityResult>> get onConnectivityChanged => _connectivity.onConnectivityChanged;

  @override
  Future<List<ConnectivityResult>> get currentConnectivity => _connectivity.checkConnectivity();
}
