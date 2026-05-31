import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_icons.dart';
import 'package:schat/utils/common_spaces.dart';

class InternetConnectionPopup extends StatefulWidget {
  const InternetConnectionPopup({super.key});

  @override
  State<InternetConnectionPopup> createState() => _InternetConnectionPopupState();
}

class _InternetConnectionPopupState extends State<InternetConnectionPopup>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _offsetAnimation;
  
  Timer? _timer;
  bool _isOffline = false;
  bool _wasOffline = false;
  bool _showBanner = false;
  bool _checking = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0, -1.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _checkConnection();
    _timer = Timer.periodic(const Duration(seconds: 4), (_) => _checkConnection());
  }

  Future<void> _checkConnection() async {
    if (_checking) return;
    _checking = true;
    
    bool isConnected = false;
    try {
      if (kIsWeb) {
        final response = await Dio()
            .get('https://clients3.google.com/generate_204')
            .timeout(const Duration(seconds: 2));
        isConnected = response.statusCode == 204 || response.statusCode == 200;
      } else {
        final result = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 2));
        isConnected = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      }
    } catch (_) {
      isConnected = false;
    }

    _checking = false;
    if (!mounted) return;

    final isOfflineNow = !isConnected;
    if (_isOffline != isOfflineNow) {
      setState(() {
        _isOffline = isOfflineNow;
        if (_isOffline) {
          _wasOffline = true;
          _showBanner = true;
          _animationController.forward();
        } else {
          if (_wasOffline) {
            _showBanner = true;
            _animationController.forward();
            Timer(const Duration(seconds: 3), () {
              if (mounted && !_isOffline) {
                _animationController.reverse().then((_) {
                  if (mounted) {
                    setState(() {
                      _showBanner = false;
                    });
                  }
                });
              }
            });
          } else {
            _showBanner = false;
          }
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showBanner) return const SizedBox.shrink();

    final backgroundColor = _isOffline ? context.colors.error : context.colors.success;
    final message = _isOffline ? 'No Internet Connection' : 'Back Online';
    final icon = _isOffline ? CommonIcons.wifiOff : CommonIcons.wifi;

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: IgnorePointer(
        child: SlideTransition(
          position: _offsetAnimation,
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(16.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        color: Colors.white,
                        size: 22,
                      ),
                      CommonSpaces.w12,
                      Expanded(
                        child: Text(
                          message,
                          style: context.bodyMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
