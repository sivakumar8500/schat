import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_bloc.dart';
import 'package:schat/features/connectivity/src/presentation/bloc/connectivity_state.dart';
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
  
  bool _isOffline = false;
  bool _wasOffline = false;
  bool _showBanner = false;

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
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ConnectivityBloc, ConnectivityState>(
      listener: (context, state) {
        if (state is ConnectivityDisconnected) {
          setState(() {
            _isOffline = true;
            _wasOffline = true;
            _showBanner = true;
          });
          _animationController.forward();
        } else if (state is ConnectivityConnected) {
          if (_wasOffline) {
            setState(() {
              _isOffline = false;
              _showBanner = true;
            });
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
            setState(() {
              _showBanner = false;
            });
          }
        }
      },
      child: _showBanner ? _buildBanner() : const SizedBox.shrink(),
    );
  }

  Widget _buildBanner() {
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
                        color: Colors.black.withOpacity(0.15),
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
