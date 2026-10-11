import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import 'package:schat/core/services/live_location_service.dart';
import 'package:url_launcher/url_launcher.dart';

class LiveLocationViewerPage extends StatefulWidget {
  final String messageId;
  final String conversationId;
  final double initialLatitude;
  final double initialLongitude;
  final String? address;
  final String senderName;
  final String? senderAvatarUrl;
  final bool isMe;
  final bool isLiveActive;
  final int? liveExpiresAt;
  final String? comment;
  final VoidCallback? onStopSharing;

  const LiveLocationViewerPage({
    super.key,
    required this.messageId,
    required this.conversationId,
    required this.initialLatitude,
    required this.initialLongitude,
    this.address,
    required this.senderName,
    this.senderAvatarUrl,
    required this.isMe,
    required this.isLiveActive,
    this.liveExpiresAt,
    this.comment,
    this.onStopSharing,
  });

  @override
  State<LiveLocationViewerPage> createState() => _LiveLocationViewerPageState();
}

class _LiveLocationViewerPageState extends State<LiveLocationViewerPage> {
  GoogleMapController? _mapController;
  late double _currentLat;
  late double _currentLng;
  late bool _isActive;
  Timer? _countdownTimer;
  StreamSubscription<LiveLocationSession>? _sessionSub;
  MapType _mapType = MapType.normal;

  @override
  void initState() {
    super.initState();
    _currentLat = widget.initialLatitude;
    _currentLng = widget.initialLongitude;
    _isActive = widget.isLiveActive &&
        (widget.liveExpiresAt == null ||
            widget.liveExpiresAt! > DateTime.now().millisecondsSinceEpoch);

    // If active, listen to session updates from LiveLocationService
    _sessionSub = LiveLocationService.instance.sessionStream.listen((session) {
      if (session.messageId == widget.messageId && mounted) {
        setState(() {
          _currentLat = session.currentLatitude;
          _currentLng = session.currentLongitude;
          _isActive = session.isActive;
        });
        _mapController?.animateCamera(
          CameraUpdate.newLatLng(LatLng(_currentLat, _currentLng)),
        );
      }
    });

    // Countdown ticker to refresh remaining time
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.liveExpiresAt != null) {
        final remaining = widget.liveExpiresAt! - DateTime.now().millisecondsSinceEpoch;
        if (remaining <= 0 && _isActive) {
          setState(() {
            _isActive = false;
          });
          timer.cancel();
        } else if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _sessionSub?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  String _formatRemainingTime() {
    if (!_isActive || widget.liveExpiresAt == null) {
      return 'Live location ended';
    }
    final remainingMillis = widget.liveExpiresAt! - DateTime.now().millisecondsSinceEpoch;
    if (remainingMillis <= 0) return 'Live location ended';

    final remainingDuration = Duration(milliseconds: remainingMillis);
    if (remainingDuration.inHours > 0) {
      return '${remainingDuration.inHours}h ${remainingDuration.inMinutes.remainder(60)}m left';
    } else if (remainingDuration.inMinutes > 0) {
      return '${remainingDuration.inMinutes}m ${remainingDuration.inSeconds.remainder(60)}s left';
    } else {
      return '${remainingDuration.inSeconds}s left';
    }
  }

  String _formatLiveUntil() {
    if (widget.liveExpiresAt == null) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(widget.liveExpiresAt!);
    return 'Live until ${DateFormat('h:mm a').format(dt)}';
  }

  Future<void> _openDirections() async {
    final uri = Uri.parse(
        'https://www.google.com/maps/dir/?api=1&destination=$_currentLat,$_currentLng');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open navigation app')),
        );
      }
    }
  }

  void _confirmStopSharing() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Stop sharing live location?'),
        content: const Text(
            'Participants in this chat will no longer see your real-time location.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              widget.onStopSharing?.call();
              setState(() {
                _isActive = false;
              });
            },
            child: const Text('Stop Sharing'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liveColor = const Color(0xFF25D366);

    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: LatLng(_currentLat, _currentLng),
              zoom: 16.0,
            ),
            mapType: _mapType,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            compassEnabled: true,
            onMapCreated: (controller) => _mapController = controller,
            circles: {
              if (_isActive)
                Circle(
                  circleId: const CircleId('live_halo'),
                  center: LatLng(_currentLat, _currentLng),
                  radius: 40,
                  fillColor: liveColor.withValues(alpha: 0.2),
                  strokeColor: liveColor,
                  strokeWidth: 2,
                ),
            },
            markers: {
              Marker(
                markerId: const MarkerId('live_pos'),
                position: LatLng(_currentLat, _currentLng),
                infoWindow: InfoWindow(
                  title: widget.senderName,
                  snippet: _isActive ? _formatRemainingTime() : 'Ended',
                ),
              ),
            },
          ),

          // Custom Top App Bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withValues(alpha: 0.6),
                    radius: 20,
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: liveColor,
                            backgroundImage: widget.senderAvatarUrl != null
                                ? NetworkImage(widget.senderAvatarUrl!)
                                : null,
                            child: widget.senderAvatarUrl == null
                                ? Text(
                                    widget.senderName.isNotEmpty
                                        ? widget.senderName[0].toUpperCase()
                                        : 'U',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  )
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.senderName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Row(
                                  children: [
                                    Container(
                                      width: 7,
                                      height: 7,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isActive ? liveColor : Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      _isActive ? _formatRemainingTime() : 'Ended',
                                      style: TextStyle(
                                        color: _isActive ? liveColor : Colors.white70,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Map Control Buttons (Floating)
          Positioned(
            right: 16,
            bottom: 220,
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: 'mapTypeToggle',
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  onPressed: () {
                    setState(() {
                      _mapType = _mapType == MapType.normal
                          ? MapType.satellite
                          : MapType.normal;
                    });
                  },
                  child: Icon(
                    _mapType == MapType.normal ? Icons.satellite_alt : Icons.map,
                  ),
                ),
                const SizedBox(height: 10),
                FloatingActionButton.small(
                  heroTag: 'recenterLive',
                  backgroundColor: Colors.white,
                  foregroundColor: liveColor,
                  onPressed: () {
                    _mapController?.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: LatLng(_currentLat, _currentLng),
                          zoom: 16.5,
                        ),
                      ),
                    );
                  },
                  child: const Icon(Icons.my_location),
                ),
              ],
            ),
          ),

          // Bottom Details & Action Card
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 15,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Drag Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),

                    // User Info & Status
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: liveColor,
                          backgroundImage: widget.senderAvatarUrl != null
                              ? NetworkImage(widget.senderAvatarUrl!)
                              : null,
                          child: widget.senderAvatarUrl == null
                              ? Text(
                                  widget.senderName.isNotEmpty
                                      ? widget.senderName[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.senderName,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                _isActive
                                    ? '${_formatLiveUntil()} • ${_formatRemainingTime()}'
                                    : 'Live location ended',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _isActive
                                      ? liveColor
                                      : Colors.grey,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_isActive)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: liveColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: liveColor,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'LIVE',
                                  style: TextStyle(
                                    color: liveColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),

                    // Optional Comment
                    if (widget.comment != null && widget.comment!.trim().isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                widget.comment!.trim(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.color,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(
                                color: liveColor,
                              ),
                            ),
                            onPressed: _openDirections,
                            icon: Icon(Icons.directions, color: liveColor),
                            label: Text(
                              'Directions',
                              style: TextStyle(
                                color: liveColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        if (widget.isMe && _isActive) ...[
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade600,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _confirmStopSharing,
                              icon: const Icon(Icons.stop_circle_outlined, size: 20),
                              label: const Text(
                                'Stop Sharing',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
