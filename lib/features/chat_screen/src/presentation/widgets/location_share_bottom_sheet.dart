import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';
import 'package:schat/utils/common_notifications.dart';
import 'package:schat/utils/common_spaces.dart';

const String _kGoogleApiKey = 'AIzaSyDQ5sYBkse3w-n-QyrlvdTOCIQM86nQVKI';

class LocationShareBottomSheet extends StatefulWidget {
  final Function(double lat, double lng, [String? address]) onSendLocation;
  final Function(double lat, double lng, int durationSeconds, String? comment, [String? address])? onSendLiveLocation;

  const LocationShareBottomSheet({
    super.key,
    required this.onSendLocation,
    this.onSendLiveLocation,
  });

  @override
  State<LocationShareBottomSheet> createState() => _LocationShareBottomSheetState();
}

class _LocationShareBottomSheetState extends State<LocationShareBottomSheet> {
  bool _isLoading = true;
  bool _permissionDenied = false;
  Position? _currentPosition;
  String? _currentAddress;

  // Search State
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _searchResults = [];
  bool _isSearching = false;
  LatLng? _selectedPosition;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _checkPermissionsAndFetchLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _checkPermissionsAndFetchLocation() async {
    setState(() {
      _isLoading = true;
      _permissionDenied = false;
    });

    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) context.showErrorNotification('Location services are disabled.');
      setState(() => _permissionDenied = true);
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) context.showErrorNotification('Location permissions are denied');
        setState(() => _permissionDenied = true);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) context.showErrorNotification('Location permissions are permanently denied.');
      setState(() => _permissionDenied = true);
      return;
    }

    try {
      final Position? lastKnown = await Geolocator.getLastKnownPosition();
      if (lastKnown != null) {
        setState(() {
          _currentPosition = lastKnown;
          _selectedPosition ??= LatLng(lastKnown.latitude, lastKnown.longitude);
          _isLoading = false;
        });
        _reverseGeocode(lastKnown.latitude, lastKnown.longitude);
      }
      final Position currentPos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      if (mounted) {
        setState(() {
          _currentPosition = currentPos;
          _selectedPosition = LatLng(currentPos.latitude, currentPos.longitude);
          _isLoading = false;
        });
        _reverseGeocode(currentPos.latitude, currentPos.longitude);
      }
    } catch (e) {
      debugPrint('Location fetch error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (_selectedPosition == null) {
        if (mounted) context.showErrorNotification('Failed to get location: $e');
        setState(() => _permissionDenied = true);
      }
    }
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    try {
      final url = Uri.parse(
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_kGoogleApiKey',
      );
      final response = await http.get(url).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          final addr = data['results'][0]['formatted_address'] as String?;
          if (mounted && addr != null) {
            setState(() {
              _currentAddress = addr;
            });
          }
        }
      }
    } catch (_) {}
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    if (query.isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final url = Uri.parse('https://places.googleapis.com/v1/places:autocomplete');
        final response = await http.post(
          url,
          headers: {
            'Content-Type': 'application/json',
            'X-Goog-Api-Key': _kGoogleApiKey,
          },
          body: json.encode({
            'input': query,
            if (_selectedPosition != null)
              'locationBias': {
                'circle': {
                  'center': {
                    'latitude': _selectedPosition!.latitude,
                    'longitude': _selectedPosition!.longitude,
                  },
                  'radius': 50000.0,
                }
              }
          }),
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (mounted) {
            final suggestions = (data['suggestions'] as List?)
                ?.map((item) => item['placePrediction'] as Map<String, dynamic>?)
                .where((item) => item != null)
                .map((item) => item!)
                .toList() ?? [];
            setState(() {
              _searchResults = suggestions;
              _isSearching = false;
            });
          }
        } else {
          if (mounted) setState(() => _isSearching = false);
        }
      } catch (e) {
        debugPrint('Places autocomplete error: $e');
        if (mounted) setState(() => _isSearching = false);
      }
    });
  }

  Future<void> _selectPlace(String placeId, String mainText) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchResults = [];
      _isSearching = true;
      _searchController.text = mainText;
    });

    try {
      final url = Uri.parse('https://places.googleapis.com/v1/places/$placeId');
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _kGoogleApiKey,
          'X-Goog-FieldMask': 'location,formattedAddress',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['location'] != null) {
          final loc = data['location'];
          final lat = loc['latitude'] as double;
          final lng = loc['longitude'] as double;
          final target = LatLng(lat, lng);

          setState(() {
            _selectedPosition = target;
            _currentAddress = data['formattedAddress'] as String? ?? mainText;
            _isSearching = false;
          });

          _mapController?.animateCamera(
            CameraUpdate.newCameraPosition(CameraPosition(target: target, zoom: 16)),
          );
        }
      }
    } catch (e) {
      debugPrint('Place details fetch error: $e');
      if (mounted) context.showErrorNotification('Failed to get place details');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _recenterMap() {
    if (_currentPosition != null && _mapController != null) {
      final pos = LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
      setState(() {
        _selectedPosition = pos;
      });
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(CameraPosition(target: pos, zoom: 16)),
      );
    }
  }

  void _showLiveLocationDurationPicker() {
    final lat = _selectedPosition?.latitude ?? _currentPosition?.latitude;
    final lng = _selectedPosition?.longitude ?? _currentPosition?.longitude;

    if (lat == null || lng == null) {
      context.showErrorNotification('Waiting for current location...');
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LiveLocationDurationSheet(
        initialLatitude: lat,
        initialLongitude: lng,
        initialAddress: _currentAddress,
        onSendLive: (durationSecs, comment) {
          Navigator.pop(context); // Close duration sheet
          widget.onSendLiveLocation?.call(lat, lng, durationSecs, comment, _currentAddress);
          Navigator.pop(context); // Close location share sheet
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;
    final accuracy = _currentPosition?.accuracy.round() ?? 10;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Header handle
          Container(
            width: 38,
            height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 8),
            decoration: BoxDecoration(
              color: context.colors.textHint.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header Title & Close
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'Share Location',
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 22),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232D36) : const Color(0xFFF0F2F5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: TextStyle(color: context.colors.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Search places...',
                  hintStyle: TextStyle(color: context.colors.textSecondary, fontSize: 14),
                  prefixIcon: Icon(Icons.search_rounded, color: context.colors.textSecondary, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty || _isSearching
                      ? IconButton(
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
          ),

          // Map Preview section
          if (!_permissionDenied && _selectedPosition != null)
            Expanded(
              flex: 4,
              child: Stack(
                children: [
                  GoogleMap(
                    onMapCreated: (controller) => _mapController = controller,
                    initialCameraPosition: CameraPosition(
                      target: _selectedPosition!,
                      zoom: 16,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    markers: {
                      Marker(
                        markerId: const MarkerId('current_loc'),
                        position: _selectedPosition!,
                      ),
                    },
                    onCameraMove: (position) {
                      _selectedPosition = position.target;
                    },
                    onCameraIdle: () {
                      if (_selectedPosition != null) {
                        _reverseGeocode(_selectedPosition!.latitude, _selectedPosition!.longitude);
                      }
                    },
                  ),

                  // Center pin indicator
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 24),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFE53935),
                        size: 38,
                      ),
                    ),
                  ),

                  // Recenter button
                  Positioned(
                    right: 14,
                    bottom: 14,
                    child: FloatingActionButton.small(
                      heroTag: 'recenter_loc_btn',
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF00873C),
                      elevation: 4,
                      onPressed: _recenterMap,
                      child: const Icon(Icons.my_location_rounded, size: 20),
                    ),
                  ),

                  // Loading overlay
                  if (_isLoading)
                    Container(
                      color: Colors.black.withValues(alpha: 0.1),
                      child: const Center(
                        child: CircularProgressIndicator(color: Color(0xFF00873C)),
                      ),
                    ),
                ],
              ),
            )
          else if (_permissionDenied)
            Expanded(
              flex: 4,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.location_off_rounded, color: context.colors.error, size: 48),
                      CommonSpaces.h12,
                      Text(
                        'Location permission is required to share your location.',
                        textAlign: TextAlign.center,
                        style: context.bodyMedium,
                      ),
                      CommonSpaces.h16,
                      ElevatedButton(
                        onPressed: _checkPermissionsAndFetchLocation,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00873C),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Grant Permission'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            const Expanded(
              flex: 4,
              child: Center(child: CircularProgressIndicator(color: Color(0xFF00873C))),
            ),

          // Search results or WhatsApp Location Options
          Expanded(
            flex: 5,
            child: _searchResults.isNotEmpty
                ? ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: _searchResults.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: context.colors.border.withValues(alpha: 0.2)),
                    itemBuilder: (context, index) {
                      final place = _searchResults[index];
                      final mainText = place['structuredFormat']?['mainText']?['text'] ??
                          place['text']?['text'] ??
                          'Unknown place';
                      final secondaryText = place['structuredFormat']?['secondaryText']?['text'] ?? '';

                      return ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: context.colors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.location_on_rounded, color: context.colors.primary, size: 20),
                        ),
                        title: Text(mainText, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: context.colors.textPrimary)),
                        subtitle: secondaryText.isNotEmpty
                            ? Text(secondaryText, style: TextStyle(fontSize: 12, color: context.colors.textSecondary))
                            : null,
                        onTap: () => _selectPlace(place['placeId'], mainText),
                      );
                    },
                  )
                : ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      // 1. WhatsApp Option: Share live location
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE8F5E9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.share_location_rounded,
                            color: Color(0xFF00873C),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Share live location',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Share real-time location as you move',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.grey),
                        onTap: _showLiveLocationDurationPicker,
                      ),
                      Divider(height: 1, indent: 72, color: context.colors.border.withValues(alpha: 0.2)),

                      // 2. WhatsApp Option: Send your current location
                      ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: context.colors.isDark ? const Color(0xFF1E2428) : const Color(0xFFF0F4F8),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.my_location_rounded,
                            color: Color(0xFF1976D2),
                            size: 24,
                          ),
                        ),
                        title: Text(
                          'Send your current location',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w700,
                            color: context.colors.textPrimary,
                          ),
                        ),
                        subtitle: Text(
                          'Accurate to $accuracy meters',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: context.colors.textSecondary,
                          ),
                        ),
                        onTap: () {
                          final lat = _selectedPosition?.latitude ?? _currentPosition?.latitude;
                          final lng = _selectedPosition?.longitude ?? _currentPosition?.longitude;
                          if (lat != null && lng != null) {
                            widget.onSendLocation(lat, lng, _currentAddress);
                            Navigator.pop(context);
                          }
                        },
                      ),
                      Divider(height: 1, indent: 72, color: context.colors.border.withValues(alpha: 0.2)),

                      // 3. If a custom location was selected from search
                      if (_searchController.text.isNotEmpty && _selectedPosition != null) ...[
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
                          leading: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFEBEE),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.pin_drop_rounded,
                              color: Color(0xFFE53935),
                              size: 24,
                            ),
                          ),
                          title: Text(
                            'Send selected place',
                            style: TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: context.colors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            _searchController.text,
                            style: TextStyle(
                              fontSize: 12.5,
                              color: context.colors.textSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () {
                            widget.onSendLocation(
                              _selectedPosition!.latitude,
                              _selectedPosition!.longitude,
                              _searchController.text.trim(),
                            );
                            Navigator.pop(context);
                          },
                        ),
                        Divider(height: 1, indent: 72, color: context.colors.border.withValues(alpha: 0.2)),
                      ],

                      // Address preview bar if available
                      if (_currentAddress != null && _currentAddress!.isNotEmpty) ...[
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  _currentAddress!,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: context.colors.textSecondary,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _LiveLocationDurationSheet extends StatefulWidget {
  final double initialLatitude;
  final double initialLongitude;
  final String? initialAddress;
  final Function(int durationSeconds, String? comment) onSendLive;

  const _LiveLocationDurationSheet({
    required this.initialLatitude,
    required this.initialLongitude,
    this.initialAddress,
    required this.onSendLive,
  });

  @override
  State<_LiveLocationDurationSheet> createState() => _LiveLocationDurationSheetState();
}

class _LiveLocationDurationSheetState extends State<_LiveLocationDurationSheet> {
  // Predefined durations in seconds: 15 min, 1 hr, 8 hr, custom
  int _selectedDurationSeconds = 900; // default 15 minutes
  bool _isCustomDuration = false;
  int _customMinutes = 30; // default custom: 30 minutes
  final TextEditingController _commentController = TextEditingController();

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _handleSend() {
    final duration = _isCustomDuration ? (_customMinutes * 60) : _selectedDurationSeconds;
    final comment = _commentController.text.trim();
    widget.onSendLive(duration, comment.isNotEmpty ? comment : null);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.colors.isDark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        top: 12,
        left: 20,
        right: 20,
      ),
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4,
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: context.colors.textHint.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: Color(0xFFE8F5E9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.sensors_rounded, color: Color(0xFF00873C), size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                'Share Live Location',
                style: context.titleMedium.copyWith(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          CommonSpaces.h8,
          Text(
            'Participants in this chat will see your real-time location. You can stop sharing at any time.',
            style: TextStyle(fontSize: 12.5, color: context.colors.textSecondary, height: 1.3),
          ),
          CommonSpaces.h16,

          // Duration label
          Text(
            'Select duration',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.colors.textPrimary,
            ),
          ),
          CommonSpaces.h8,

          // Duration Pills (15 min, 1 hour, 8 hours, Custom)
          Row(
            children: [
              _buildDurationPill('15 minutes', 900, false),
              const SizedBox(width: 8),
              _buildDurationPill('1 hour', 3600, false),
              const SizedBox(width: 8),
              _buildDurationPill('8 hours', 28800, false),
              const SizedBox(width: 8),
              _buildDurationPill('Custom', 0, true),
            ],
          ),

          // Custom Duration Picker options if selected
          if (_isCustomDuration) ...[
            CommonSpaces.h12,
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF232D36) : const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF00873C).withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Custom Duration:',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        _formatCustomDurationLabel(_customMinutes),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00873C),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Quick preset custom pills
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildCustomPresetChip('30 min', 30),
                      _buildCustomPresetChip('2 hours', 120),
                      _buildCustomPresetChip('4 hours', 240),
                      _buildCustomPresetChip('12 hours', 720),
                      _buildCustomPresetChip('24 hours', 1440),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Slider
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: const Color(0xFF00873C),
                      thumbColor: const Color(0xFF00873C),
                      inactiveTrackColor: context.colors.border,
                      trackHeight: 3,
                    ),
                    child: Slider(
                      value: _customMinutes.toDouble(),
                      min: 5,
                      max: 1440,
                      divisions: 143,
                      onChanged: (val) {
                        setState(() {
                          _customMinutes = val.toInt();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],

          CommonSpaces.h16,

          // Comment / Message input with WhatsApp send button
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF232D36) : const Color(0xFFF0F2F5),
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(fontSize: 14, color: context.colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Add comment...',
                      hintStyle: TextStyle(fontSize: 14, color: context.colors.textSecondary),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: Color(0xFF00873C),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: const Icon(Icons.send_rounded, color: Colors.white, size: 21),
                  tooltip: 'Share Live Location',
                  onPressed: _handleSend,
                ),
              ),
            ],
          ),
          CommonSpaces.h8,
        ],
      ),
    );
  }

  Widget _buildDurationPill(String label, int seconds, bool isCustom) {
    final isSelected = isCustom ? _isCustomDuration : (!_isCustomDuration && _selectedDurationSeconds == seconds);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            if (isCustom) {
              _isCustomDuration = true;
            } else {
              _isCustomDuration = false;
              _selectedDurationSeconds = seconds;
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF00873C) : context.colors.cardBackground,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? const Color(0xFF00873C) : context.colors.border.withValues(alpha: 0.4),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : context.colors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomPresetChip(String label, int minutes) {
    final isSelected = _customMinutes == minutes;
    return GestureDetector(
      onTap: () => setState(() => _customMinutes = minutes),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF00873C) : context.colors.scaffoldBackground,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? const Color(0xFF00873C) : context.colors.border.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            color: isSelected ? Colors.white : context.colors.textPrimary,
          ),
        ),
      ),
    );
  }

  String _formatCustomDurationLabel(int minutes) {
    if (minutes < 60) {
      return '$minutes min';
    }
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    if (mins == 0) {
      return '$hours hr${hours > 1 ? 's' : ''}';
    }
    return '$hours hr $mins min';
  }
}
