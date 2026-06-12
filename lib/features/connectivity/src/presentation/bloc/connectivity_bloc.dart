import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:schat/core/network/connectivity_repository.dart';
import 'connectivity_event.dart';
import 'connectivity_state.dart';

@injectable
class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final ConnectivityRepository _connectivityRepository;
  StreamSubscription? _subscription;

  ConnectivityBloc(this._connectivityRepository) : super(ConnectivityInitial()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityChanged>(_onChanged);
  }

  Future<void> _onStarted(ConnectivityStarted event, Emitter<ConnectivityState> emit) async {
    final result = await _connectivityRepository.currentConnectivity;
    add(ConnectivityChanged(result));
    
    _subscription?.cancel();
    _subscription = _connectivityRepository.onConnectivityChanged.listen((result) {
      add(ConnectivityChanged(result));
    });
  }

  void _onChanged(ConnectivityChanged event, Emitter<ConnectivityState> emit) {
    final isConnected = event.result.any((r) => r != ConnectivityResult.none);
    if (isConnected) {
      emit(ConnectivityConnected(event.result));
    } else {
      emit(ConnectivityDisconnected());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
