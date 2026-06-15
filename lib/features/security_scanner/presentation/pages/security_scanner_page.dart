import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_spaces.dart';
import '../bloc/security_scanner_bloc.dart';
import '../bloc/security_scanner_event.dart';
import '../bloc/security_scanner_state.dart';

class SecurityScannerPage extends StatelessWidget {
  const SecurityScannerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.scaffoldBackground,
      appBar: AppBar(
        title: Text('Security Scanner', style: context.titleMedium),
        backgroundColor: context.colors.cardBackground,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Keep your schat experience safe. Scan your device and links for threats.',
              style: context.bodyMedium,
              textAlign: TextAlign.center,
            ),
            CommonSpaces.h24,
            ElevatedButton(
              onPressed: () {
                context.read<SecurityScannerBloc>().add(const SecurityScannerEvent.checkIntegrity());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.colors.primary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text('Check Device Integrity', style: context.buttonText),
            ),
            CommonSpaces.h16,
            BlocBuilder<SecurityScannerBloc, SecurityScannerState>(
              builder: (context, state) {
                return state.maybeWhen(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  integrityResult: (isSafe) => _buildResultCard(
                    context,
                    isSafe ? 'Device is Secure' : 'Device Compromised (Root/Jailbreak)',
                    isSafe ? context.colors.success : context.colors.error,
                    isSafe ? Icons.check_circle : Icons.warning,
                  ),
                  scanResult: (report) => _buildResultCard(
                    context,
                    report.message,
                    report.isSafe ? context.colors.success : context.colors.error,
                    report.isSafe ? Icons.security : Icons.bug_report,
                  ),
                  error: (msg) => Text('Error: $msg', style: TextStyle(color: context.colors.error)),
                  orElse: () => const SizedBox.shrink(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(BuildContext context, String message, Color color, IconData icon) {
    return Card(
      color: context.colors.cardBackground,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: color, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color, size: 32),
            CommonSpaces.w16,
            Expanded(
              child: Text(
                message,
                style: context.bodyLarge.copyWith(color: color, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
