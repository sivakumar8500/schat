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

const String _kGoogleApiKey = 'AIzaSyDzdftYEP9bbhXFHyjGSmydrvGKZSx6cSk';

class LocationShareBottomSheet extends StatefulWidget {
  final Function(double lat, double lng) onSendLocation;

  const LocationShareBottomSheet({
    super.key,
    required this.onSendLocation,
  });

  @override
  State<LocationShareBottomSheet> createState() => _LocationShareBottomSheetState();
}

class _LocationShareBottomSheetState extends State<LocationShareBottomSheet> {
  bool _isLoading = true;
  bool _permissionDenied = false;
  Position? _currentPosition;
  
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
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null) {
        setState(() {
          _currentPosition = position;
          _selectedPosition ??= LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      }
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );
      if (mounted) {
        setState(() {
          _currentPosition = position;
          _selectedPosition ??= LatLng(position.latitude, position.longitude);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) context.showErrorNotification('Failed to get location');
      setState(() => _permissionDenied = true);
    }
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
    
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _isSearching = true);
      
      final url = Uri.parse('https://maps.googleapis.com/maps/api/place/autocomplete/json?input=\&key=\');
      try {
        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK') {
            setState(() {
              _searchResults = List<Map<String, dynamic>>.from(data['predictions']);
            });
          } else {
            setState(() => _searchResults = []);
          }
        }
      } catch (e) {
        debugPrint('Error searching places: \');
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    });
  }

  Future<void> _selectPlace(String placeId, String description) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _searchController.text = description;
      _searchResults = [];
      _isSearching = true;
    });

    final url = Uri.parse('https://maps.googleapis.com/maps/api/place/details/json?place_id=\&key=\');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['status'] == 'OK') {
          final loc = data['result']['geometry']['location'];
          final latLng = LatLng(loc['lat'], loc['lng']);
          setState(() {
            _selectedPosition = latLng;
          });
          _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 15));
        }
      }
    } catch (e) {
      debugPrint('Error getting place details: \');
      if (mounted) context.showErrorNotification('Failed to get location details');
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colors.scaffoldBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: context.colors.textHint.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          CommonSpaces.h16,
          Text(
            'Share Location',
            style: context.titleMedium.copyWith(fontWeight: FontWeight.bold),
          ),
          CommonSpaces.h16,
          
          if (!_isLoading && !_permissionDenied)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  hintText: 'Search places...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchController.text.isNotEmpty || _isSearching
                      ? IconButton(
                          icon: _isSearching
                              ? const SizedBox(
                                  width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                              : const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                            FocusScope.of(context).unfocus();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: context.colors.lightBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                ),
              ),
            ),
          
          if (_searchResults.isNotEmpty)
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.3),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: _searchResults.length,
                itemBuilder: (context, index) {
                  final place = _searchResults[index];
                  return ListTile(
                    leading: const Icon(Icons.location_on, color: Colors.grey),
                    title: Text(place['structured_formatting']?['main_text'] ?? place['description']),
                    subtitle: Text(place['structured_formatting']?['secondary_text'] ?? ''),
                    onTap: () => _selectPlace(place['place_id'], place['description']),
                  );
                },
              ),
            )
          else if (_isLoading && !_permissionDenied)
            const Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_permissionDenied)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Icon(Icons.location_off, color: context.colors.error, size: 48),
                  CommonSpaces.h16,
                  Text(
                    'Location permission is required to share your current location.',
                    textAlign: TextAlign.center,
                    style: context.bodyMedium,
                  ),
                  CommonSpaces.h16,
                  ElevatedButton(
                    onPressed: _checkPermissionsAndFetchLocation,
                    style: ElevatedButton.styleFrom(backgroundColor: context.colors.primary),
                    child: const Text('Try Again', style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            )
          else if (_selectedPosition != null)
            Column(
              children: [
                CommonSpaces.h16,
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    height: 250,
                    width: MediaQuery.of(context).size.width - 32,
                    child: GoogleMap(
                      onMapCreated: (controller) => _mapController = controller,
                      initialCameraPosition: CameraPosition(
                        target: _selectedPosition!,
                        zoom: 15,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: true,
                      markers: {
                        Marker(
                          markerId: const MarkerId('current_loc'),
                          position: _selectedPosition!,
                        ),
                      },
                      onCameraMove: (position) {
                         // Optional: Let user drag map to select location
                      },
                      onCameraIdle: () {
                         // Update _selectedPosition when map finishes moving? No, let's keep it simple.
                      }
                    ),
                  ),
                ),
                CommonSpaces.h16,
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onSendLocation(_selectedPosition!.latitude, _selectedPosition!.longitude);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.colors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _searchController.text.isEmpty ? 'Send Current Location' : 'Send Selected Location',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
