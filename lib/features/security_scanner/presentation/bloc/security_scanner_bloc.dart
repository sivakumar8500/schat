import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../domain/usecases/check_device_integrity_usecase.dart';
import '../../domain/usecases/scan_file_usecase.dart';
import '../../domain/usecases/scan_url_usecase.dart';
import 'security_scanner_event.dart';
import 'security_scanner_state.dart';

@injectable
class SecurityScannerBloc extends Bloc<SecurityScannerEvent, SecurityScannerState> {
  final CheckDeviceIntegrityUseCase checkDeviceIntegrityUseCase;
  final ScanUrlUseCase scanUrlUseCase;
  final ScanFileUseCase scanFileUseCase;

  SecurityScannerBloc(
    this.checkDeviceIntegrityUseCase,
    this.scanUrlUseCase,
    this.scanFileUseCase,
  ) : super(const SecurityScannerState.initial()) {
    on<CheckIntegrity>((event, emit) async {
      emit(const SecurityScannerState.loading());
      try {
        final result = await checkDeviceIntegrityUseCase();
        emit(SecurityScannerState.integrityResult(result));
      } catch (e) {
        emit(SecurityScannerState.error(e.toString()));
      }
    });

    on<ScanUrl>((event, emit) async {
      emit(const SecurityScannerState.loading());
      try {
        final report = await scanUrlUseCase(event.url);
        emit(SecurityScannerState.scanResult(report));
      } catch (e) {
        emit(SecurityScannerState.error(e.toString()));
      }
    });

    on<ScanFile>((event, emit) async {
      emit(const SecurityScannerState.loading());
      try {
        final report = await scanFileUseCase(event.filePath);
        emit(SecurityScannerState.scanResult(report));
      } catch (e) {
        emit(SecurityScannerState.error(e.toString()));
      }
    });
  }
}
