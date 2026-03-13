import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/nearby_company.dart';
import '../../models/recycler_company.dart';
import '../../services/company_data_service.dart';
import '../../services/location_search_service.dart';
import '../../services/realtime_company_service.dart';
import '../../providers/auth_provider.dart';
import 'dashboard_screen.dart';

enum _LocationRecoveryAction {
  requestPermission,
  openAppSettings,
  openLocationSettings,
}

class LogisticsScreen extends ConsumerStatefulWidget {
  const LogisticsScreen({super.key});

  @override
  ConsumerState<LogisticsScreen> createState() => _LogisticsScreenState();
}

class _LogisticsScreenState extends ConsumerState<LogisticsScreen>
    with WidgetsBindingObserver {
  static const LatLng _fallbackCenter = LatLng(20.5937, 78.9629);
  static const int _searchRadiusMeters = 15000;
  static const String _streetTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
  static const String _satelliteTileUrl =
      'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';

  final MapController _mapController = MapController();
  final RealtimeCompanyService _realtimeCompanyService =
      RealtimeCompanyService();
  final TextEditingController _locationSearchController =
      TextEditingController();
  final TextEditingController _companyFilterController =
      TextEditingController();

  /// local cache fallback when realtime feed is empty / unavailable
  // CompanyDataService is used only via its static API; no instance needed.

  LatLng? _currentPosition;
  LatLng? _lastSearchCenter;
  LatLng? _searchedLocation;
  List<List<LatLng>> _searchedLocationOutlines = const [];
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<NearbyCompanyFeed>? _nearbyCompaniesSubscription;
  Timer? _nearbyRefreshDebounce;

  List<NearbyCompany> _nearbyCompanies = const [];
  NearbyCompany? _selectedCompany;

  bool _shareLiveLocation = true;
  bool _showNearbyCompanies = true;
  bool _showAllCompanies = false;
  bool _isSatelliteView = false;
  bool _isMapReady = false;
  bool _hasCenteredOnUser = false;
  bool _isLoadingNearbyCompanies = false;
  bool _isSearchingLocation = false;
  String _searchQuery = '';
  int _nearbyRequestId = 0;
  int _locationSearchRequestId = 0;

  String? _nearbyCompaniesError;
  String? _nearbyCompaniesSourceMessage;
  String? _searchedLocationLabel;
  _LocationRecoveryAction? _locationRecoveryAction;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startLocationSharing();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _locationSearchController.dispose();
    _companyFilterController.dispose();
    _nearbyRefreshDebounce?.cancel();
    _nearbyCompaniesSubscription?.cancel();
    _positionStream?.cancel();
    super.dispose();
  }

  List<NearbyCompany> get _filteredCompanies {
    return _nearbyCompanies
        .where((company) => company.matchesSearch(_searchQuery))
        .toList(growable: false);
  }

  Future<void> _startLocationSharing() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _setLocationUnavailable(
          'Turn on location services to find nearby buyers and recyclers.',
          recoveryAction: _LocationRecoveryAction.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        _setLocationUnavailable(
          permission == LocationPermission.deniedForever
              ? 'Location permission is permanently denied. Open app settings to enable nearby buyer discovery again.'
              : 'Location permission is needed to show nearby buyers around the user.',
          recoveryAction: permission == LocationPermission.deniedForever
              ? _LocationRecoveryAction.openAppSettings
              : _LocationRecoveryAction.requestPermission,
        );
        return;
      }

      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );

      _updateCurrentPosition(
        LatLng(initialPosition.latitude, initialPosition.longitude),
        centerOnUser: true,
      );

      await _positionStream?.cancel();
      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 20,
            ),
          ).listen((position) {
            _updateCurrentPosition(
              LatLng(position.latitude, position.longitude),
            );
          });
    } catch (_) {
      _setLocationUnavailable('Could not access the user location right now.');
    }
  }

  void _setLocationUnavailable(
    String message, {
    _LocationRecoveryAction? recoveryAction,
  }) {
    _nearbyRequestId++;
    _nearbyCompaniesSubscription?.cancel();
    _nearbyCompaniesSubscription = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _currentPosition = null;
      _nearbyCompanies = const [];
      _selectedCompany = null;
      _isLoadingNearbyCompanies = false;
      _nearbyCompaniesError = message;
      _nearbyCompaniesSourceMessage = null;
      _lastSearchCenter = null;
      _locationRecoveryAction = recoveryAction;
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // If the user returns and location was previously unavailable, retry.
      if (_locationRecoveryAction != null) {
        _startLocationSharing();
      }

      // If we are showing the map but still have no nearby companies, refresh.
      if (_currentPosition != null && _nearbyCompanies.isEmpty) {
        _refreshNearbyCompanies(force: true);
      }
    }
  }

  void _updateCurrentPosition(
    LatLng nextPosition, {
    bool centerOnUser = false,
  }) {
    if (!mounted) {
      return;
    }

    setState(() {
      _currentPosition = nextPosition;
      if (_shareLiveLocation) {
        _nearbyCompaniesError = null;
        _locationRecoveryAction = null;
      }
    });

    if (_isMapReady && (centerOnUser || !_hasCenteredOnUser)) {
      _mapController.move(nextPosition, 14.5);
      _hasCenteredOnUser = true;
    }
    if (_showNearbyCompanies) {
      _scheduleNearbyCompaniesRefresh(force: centerOnUser);
    }
  }

  void _scheduleNearbyCompaniesRefresh({bool force = false}) {
    final position = _currentPosition;
    if (!_shareLiveLocation || !_showNearbyCompanies || position == null) {
      return;
    }

    if (!force &&
        _lastSearchCenter != null &&
        _nearbyCompanies.isNotEmpty &&
        Geolocator.distanceBetween(
              _lastSearchCenter!.latitude,
              _lastSearchCenter!.longitude,
              position.latitude,
              position.longitude,
            ) <
            250) {
      return;
    }

    _nearbyRefreshDebounce?.cancel();
    _nearbyRefreshDebounce = Timer(
      const Duration(milliseconds: 700),
      () => _refreshNearbyCompanies(force: force),
    );
  }

  Future<void> _refreshNearbyCompanies({bool force = false}) async {
    final position = _currentPosition;
    if (!_shareLiveLocation || !_showNearbyCompanies || position == null) {
      return;
    }

    final requestId = ++_nearbyRequestId;

    if (!force &&
        _lastSearchCenter != null &&
        _nearbyCompanies.isNotEmpty &&
        Geolocator.distanceBetween(
              _lastSearchCenter!.latitude,
              _lastSearchCenter!.longitude,
              position.latitude,
              position.longitude,
            ) <
            250) {
      return;
    }

    await _nearbyCompaniesSubscription?.cancel();
    _nearbyCompaniesSubscription = null;

    if (mounted) {
      setState(() {
        _isLoadingNearbyCompanies = true;
        _nearbyCompaniesError = null;
        _nearbyCompaniesSourceMessage =
            'Connecting to the realtime company feed...';
      });
    }

    final radiusMeters = _showAllCompanies ? 1000000 : _searchRadiusMeters;

    _nearbyCompaniesSubscription = _realtimeCompanyService
        .watchNearbyCompanies(
          center: position,
          radiusMeters: radiusMeters,
        )
        .listen(
          (feed) async {
            if (!mounted || requestId != _nearbyRequestId) {
              return;
            }

            // Use realtime results if available, otherwise fall back to local data.
            final reportedCompanies =
                feed.companies.isNotEmpty
                    ? feed.companies
                    : await CompanyDataService.loadNearbyFromAsset(center: position);

            NearbyCompany? selectedCompany = _selectedCompany;
            if (selectedCompany == null && reportedCompanies.isNotEmpty) {
              selectedCompany = reportedCompanies.first;
            }

            setState(() {
              _nearbyCompanies = reportedCompanies;
              _selectedCompany = selectedCompany;
              _isLoadingNearbyCompanies = false;
              _nearbyCompaniesError = reportedCompanies.isEmpty
                  ? feed.message ??
                        'No nearby buyers or recycling companies were found in this area yet.'
                  : null;
              _nearbyCompaniesSourceMessage = feed.message;
              _lastSearchCenter = position;
              _locationRecoveryAction = null;
            });

            if (_isMapReady && selectedCompany != null) {
              _mapController.move(selectedCompany.latLng, 14.0);
            }
          },
          onError: (_) async {
            if (!mounted || requestId != _nearbyRequestId) {
              return;
            }

            // Fallback to local company list on error.
            final local = await CompanyDataService.loadNearbyFromAsset(center: position);
            setState(() {
              _nearbyCompanies = local;
              _selectedCompany = local.isNotEmpty ? local.first : null;
              _isLoadingNearbyCompanies = false;
              _nearbyCompaniesError = local.isEmpty
                  ? 'Could not load nearby buyers right now. Try refreshing in a moment.'
                  : null;
              _nearbyCompaniesSourceMessage = null;
              _locationRecoveryAction = null;
            });
          },
        );
  }



  Future<void> _toggleLocationSharing(bool enabled) async {
    if (enabled == _shareLiveLocation) {
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _shareLiveLocation = enabled;
      _hasCenteredOnUser = false;
      _selectedCompany = null;
    });

    if (enabled) {
      await _startLocationSharing();
      if (_showNearbyCompanies) {
        await _refreshNearbyCompanies(force: true);
      }
      return;
    }

    _nearbyRequestId++;
    _nearbyRefreshDebounce?.cancel();
    await _nearbyCompaniesSubscription?.cancel();
    _nearbyCompaniesSubscription = null;
    await _positionStream?.cancel();
    _positionStream = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _nearbyCompanies = const [];
      _selectedCompany = null;
      _isLoadingNearbyCompanies = false;
      _nearbyCompaniesError =
          'Live location sharing is off. The last known location stays on the map until sharing resumes.';
      _nearbyCompaniesSourceMessage = null;
      _lastSearchCenter = null;
      _locationRecoveryAction = null;
    });
  }

  void _toggleNearbyCompanies(bool enabled) {
    setState(() {
      _showNearbyCompanies = enabled;
      if (!enabled) {
        _nearbyRequestId++;
        _nearbyCompaniesSubscription?.cancel();
        _nearbyCompaniesSubscription = null;
        _selectedCompany = null;
        _nearbyCompaniesError = null;
        _nearbyCompaniesSourceMessage = null;
        _isLoadingNearbyCompanies = false;
      }
    });

    if (enabled) {
      _refreshNearbyCompanies(force: true);
    }
  }

  void _toggleShowAllCompanies(bool enabled) {
    setState(() {
      _showAllCompanies = enabled;
      // Always show nearby companies when showing all.
      _showNearbyCompanies = true;
    });

    _refreshNearbyCompanies(force: true);
  }

  void _focusOnCompany(NearbyCompany company) {
    setState(() {
      _selectedCompany = company;
    });

    if (_isMapReady) {
      _mapController.move(company.latLng, 14.0);
    }
  }

  Future<void> _openCompanyOnGoogleMaps(NearbyCompany company) async {
    final googleNavigationUri = Uri.parse(
      'google.navigation:q=${company.latitude},${company.longitude}',
    );
    final geoUri = Uri.parse(
      'geo:${company.latitude},${company.longitude}?q=${company.latitude},${company.longitude}',
    );
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${company.latitude},${company.longitude}',
    );

    final openedGoogleNavigation = await launchUrl(
      googleNavigationUri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (openedGoogleNavigation) {
      return;
    }

    final openedGeoUri = await launchUrl(
      geoUri,
      mode: LaunchMode.externalNonBrowserApplication,
    );
    if (openedGeoUri) {
      return;
    }

    final openedWebUri = await launchUrl(
      webUri,
      mode: LaunchMode.externalApplication,
    );
    if (openedWebUri) {
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not open Google Maps for this place.'),
      ),
    );
  }

  Future<void> _openCompanyWebsite(NearbyCompany company) async {
    final website = company.website;
    if (website == null) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This company has no website listed.')),
      );
      return;
    }

    final uri = Uri.parse(website);
    final openedExternally = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );
    if (openedExternally) {
      return;
    }

    final openedInApp = await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    if (openedInApp) {
      return;
    }

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open the company website.')),
    );
  }

  Future<void> _openLocationSettings() async {
    final opened = await Geolocator.openLocationSettings();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Enable location services, then return to refresh nearby buyers.'
              : 'Could not open location settings on this device.',
        ),
      ),
    );
  }

  Future<void> _openAppSettings() async {
    final opened = await Geolocator.openAppSettings();
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Grant location permission in app settings, then return to resume nearby search.'
              : 'Could not open app settings on this device.',
        ),
      ),
    );
  }

  Widget? _buildLocationRecoveryAction() {
    switch (_locationRecoveryAction) {
      case _LocationRecoveryAction.requestPermission:
        return ElevatedButton.icon(
          onPressed: _startLocationSharing,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A699),
          ),
          icon: const Icon(Icons.gps_fixed),
          label: const Text('Grant permission'),
        );
      case _LocationRecoveryAction.openAppSettings:
        return ElevatedButton.icon(
          onPressed: _openAppSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A699),
          ),
          icon: const Icon(Icons.settings),
          label: const Text('Open app settings'),
        );
      case _LocationRecoveryAction.openLocationSettings:
        return ElevatedButton.icon(
          onPressed: _openLocationSettings,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF00A699),
          ),
          icon: const Icon(Icons.location_searching),
          label: const Text('Open location settings'),
        );
      case null:
        return null;
    }
  }

  void _clearLocationSearch() {
    _locationSearchRequestId++;
    _locationSearchController.clear();
    setState(() {
      _searchedLocation = null;
      _searchedLocationLabel = null;
      _searchedLocationOutlines = const [];
      _isSearchingLocation = false;
    });
  }

  void _clearCompanyFilter() {
    _companyFilterController.clear();
    setState(() {
      _searchQuery = '';
    });
  }

  Future<void> _submitMapSearch() async {
    final query = _locationSearchController.text.trim();
    if (query.isEmpty) {
      _clearLocationSearch();
      return;
    }

    final requestId = ++_locationSearchRequestId;

    setState(() {
      _isSearchingLocation = true;
    });

    try {
      final locationResult = await LocationSearchService.search(query);
      if (!mounted || requestId != _locationSearchRequestId) {
        return;
      }

      if (locationResult != null) {
        setState(() {
          _searchedLocation = locationResult.position;
          _searchedLocationLabel = locationResult.displayName;
          _searchedLocationOutlines = locationResult.outlines;
          _selectedCompany = null;
          _isSearchingLocation = false;
        });

        if (_isMapReady) {
          _mapController.move(locationResult.position, 13.5);
        }
        return;
      }

      setState(() {
        _isSearchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No matching location was found for that search.'),
        ),
      );
    } catch (_) {
      if (!mounted || requestId != _locationSearchRequestId) {
        return;
      }

      setState(() {
        _isSearchingLocation = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location search is unavailable right now.'),
        ),
      );
    }
  }

  Widget _buildMapSearchBar() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      elevation: 4,
      child: TextField(
        controller: _locationSearchController,
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submitMapSearch(),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Search city or place on the map',
          prefixIcon: const Icon(Icons.search),
          suffixIconConstraints: const BoxConstraints(minWidth: 96),
          suffixIcon: _isSearchingLocation
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: _submitMapSearch,
                      icon: const Icon(Icons.north_east),
                    ),
                    if (_locationSearchController.text.trim().isNotEmpty ||
                        _searchedLocation != null)
                      IconButton(
                        onPressed: _clearLocationSearch,
                        icon: const Icon(Icons.close),
                      ),
                  ],
                ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCompanyFilterField() {
    return TextField(
      controller: _companyFilterController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
          if (_selectedCompany != null &&
              !_selectedCompany!.matchesSearch(value)) {
            _selectedCompany = null;
          }
        });
      },
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Filter nearby buyers by company, city, or waste type',
        prefixIcon: const Icon(Icons.manage_search),
        suffixIcon: _searchQuery.trim().isEmpty
            ? null
            : IconButton(
                onPressed: _clearCompanyFilter,
                icon: const Icon(Icons.close),
              ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }

  String get _bottomSheetSummary {
    final filteredCompanies = _filteredCompanies;

    if (!_shareLiveLocation) {
      return 'Live location is off. The last known location remains pinned on the map until sharing resumes.';
    }
    if (!_showNearbyCompanies) {
      return 'Nearby company markers are hidden from the map.';
    }
    if (_isLoadingNearbyCompanies && _nearbyCompanies.isEmpty) {
      return 'Searching nearby buyers and recycling companies around the user...';
    }
    if (_nearbyCompaniesError != null && _nearbyCompanies.isEmpty) {
      return _nearbyCompaniesError!;
    }
    if (_currentPosition == null) {
      return 'Waiting for the current location...';
    }

    if (_searchedLocation != null) {
      if (_searchedLocationOutlines.isNotEmpty) {
        return 'Showing the exact boundary returned for the searched place.';
      }

      return 'Showing the searched place marker. Exact boundary data is not available for this result.';
    }

    if (_searchQuery.trim().isNotEmpty) {
      final base =
          '${filteredCompanies.length} nearby buyers match the current filter.';
      if (_nearbyCompaniesSourceMessage == null) {
        return base;
      }

      return '$base ${_nearbyCompaniesSourceMessage!}';
    }

    if (_showAllCompanies) {
      final base =
          '${_nearbyCompanies.length} companies (showing all, regardless of distance).';
      if (_nearbyCompaniesSourceMessage == null) {
        return base;
      }
      return '$base ${_nearbyCompaniesSourceMessage!}';
    }

    final radiusKm = (_searchRadiusMeters / 1000).round();
    final base =
        '${_nearbyCompanies.length} nearby buyers and recyclers within $radiusKm km of the shared location.';
    if (_nearbyCompaniesSourceMessage == null) {
      return base;
    }

    return '$base ${_nearbyCompaniesSourceMessage!}';
  }

  List<Marker> _buildCompanyMarkers() {
    if (!_showNearbyCompanies || _searchedLocation != null) {
      return const [];
    }

    return _filteredCompanies
        .map((company) {
          final isSelected = _selectedCompany?.id == company.id;

          return Marker(
            point: company.latLng,
            width: isSelected ? 150 : 44,
            height: isSelected ? 78 : 44,
            child: GestureDetector(
              onTap: () => _focusOnCompany(company),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF00A699),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.14),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Text(
                        company.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  Icon(
                    Icons.location_on,
                    size: isSelected ? 34 : 28,
                    color: isSelected
                        ? const Color(0xFF00A699)
                        : const Color(0xFFEF6C00),
                  ),
                ],
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  List<Polyline> _buildSearchedAreaPolylines() {
    if (_searchedLocationOutlines.isEmpty) {
      return const [];
    }

    return _searchedLocationOutlines
        .map(
          (outline) => Polyline(
            points: outline,
            strokeWidth: 5,
            color: const Color(0xFF00A699).withValues(alpha: 0.75),
            borderStrokeWidth: 2,
            borderColor: Colors.white.withValues(alpha: 0.9),
          ),
        )
        .toList(growable: false);
  }

  List<Widget> _buildNearbyCompanyCards() {
    return _filteredCompanies
        .map((company) {
          final isSelected = _selectedCompany?.id == company.id;

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            elevation: isSelected ? 4 : 1,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFF00A699)
                    : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => _focusOnCompany(company),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00A699,
                            ).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.recycling,
                            color: Color(0xFF00A699),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                company.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                company.category,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                company.wasteTypesLabel,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(
                              0xFF00A699,
                            ).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            company.distanceLabel,
                            style: const TextStyle(
                              color: Color(0xFF00A699),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.place_outlined,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            company.locationLabel,
                            style: TextStyle(
                              color: Colors.grey[700],
                              height: 1.35,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if ((company.phone ?? '').isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            Icons.phone_outlined,
                            size: 18,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 6),
                          Text(
                            company.phone!,
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => _focusOnCompany(company),
                          icon: const Icon(Icons.center_focus_strong),
                          label: const Text('Focus'),
                        ),
                        ElevatedButton.icon(
                          onPressed: () => _openCompanyOnGoogleMaps(company),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF00A699),
                          ),
                          icon: const Icon(Icons.map_outlined),
                          label: const Text('Google Maps'),
                        ),
                        if (company.website != null)
                          OutlinedButton.icon(
                            onPressed: () => _openCompanyWebsite(company),
                            icon: const Icon(Icons.language),
                            label: const Text('Website'),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        })
        .toList(growable: false);
  }

  Widget _buildSelectedCompanyPanel() {
    final company = _selectedCompany;
    if (company == null) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A699).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00A699).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, color: Color(0xFF00A699)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  company.name,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    _selectedCompany = null;
                  });
                },
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Text(
            company.category,
            style: TextStyle(
              color: Colors.grey[700],
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            company.locationLabel,
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Accepts: ${company.wasteTypesLabel}',
            style: TextStyle(color: Colors.grey[700]),
          ),
          const SizedBox(height: 8),
          Text(
            'Distance from user: ${company.distanceLabel}',
            style: const TextStyle(
              color: Color(0xFF00A699),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openCompanyOnGoogleMaps(company),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00A699),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text('Open in Google'),
                ),
              ),
              if (company.website != null) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _openCompanyWebsite(company),
                    icon: const Icon(Icons.language),
                    label: const Text('Website'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchedLocationPanel() {
    final searchedLocation = _searchedLocation;
    if (searchedLocation == null) {
      return const SizedBox.shrink();
    }

    final hasExactBoundary = _searchedLocationOutlines.isNotEmpty;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00A699).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF00A699).withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.polyline, color: Color(0xFF00A699)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _searchedLocationLabel ?? 'Searched location',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                onPressed: _clearLocationSearch,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasExactBoundary
                ? 'Exact area boundary is highlighted on the map.'
                : 'The searched place is pinned on the map, but the data source did not return an exact boundary shape.',
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
          const SizedBox(height: 10),
          Text(
            'Latitude: ${searchedLocation.latitude.toStringAsFixed(5)}  Longitude: ${searchedLocation.longitude.toStringAsFixed(5)}',
            style: TextStyle(color: Colors.grey[700]),
          ),
        ],
      ),
    );
  }

  Widget _buildSheetBody() {
    if (_searchedLocation != null) {
      return _buildSearchedLocationPanel();
    }

    if (!_shareLiveLocation) {
      return _buildEmptyState(
        icon: Icons.location_off,
        title: 'Live location is off',
        message:
            'Turn on live location to share the user location and discover nearby buyers in real time.',
      );
    }

    if (!_showNearbyCompanies) {
      return _buildEmptyState(
        icon: Icons.visibility_off,
        title: 'Nearby buyers are hidden',
        message:
            'Turn the nearby buyers option back on to show companies on the map and in this sheet.',
      );
    }

    if (_isLoadingNearbyCompanies && _nearbyCompanies.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_nearbyCompaniesError != null && _nearbyCompanies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.wifi_tethering_error_rounded,
        title: 'Nearby search unavailable',
        message: _nearbyCompaniesError!,
        action:
            _buildLocationRecoveryAction() ??
            ElevatedButton.icon(
              onPressed: () => _refreshNearbyCompanies(force: true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00A699),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
      );
    }

    if (_nearbyCompanies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.search_off,
        title: 'No nearby buyers found',
        message:
            'Move the map or refresh after the location updates to search a wider nearby area.',
      );
    }

    if (_filteredCompanies.isEmpty) {
      return _buildEmptyState(
        icon: Icons.manage_search,
        title: 'No search matches',
        message:
            'Try a different city, company name, or waste type like plastic, paper, metal, glass, or e-waste.',
      );
    }

    return Column(
      children: [_buildSelectedCompanyPanel(), ..._buildNearbyCompanyCards()],
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 36, color: const Color(0xFF00A699)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey[700], height: 1.4),
          ),
          if (action != null) ...[const SizedBox(height: 16), action],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // restrict to buyers only
    final role = ref.watch(userRoleProvider);
    // Allow null role in tests (no auth context), but enforce buyer vs seller in real usage.
    if (role != null && role != 'buyer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      });
      return const SizedBox.shrink();
    }

    final markers = <Marker>[
      ..._buildCompanyMarkers(),
      if (_searchedLocation != null)
        Marker(
          point: _searchedLocation!,
          width: 52,
          height: 64,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if ((_searchedLocationLabel ?? '').isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.14),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _searchedLocationLabel!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              const Icon(Icons.place, size: 34, color: Colors.red),
            ],
          ),
        ),
      if (_currentPosition != null)
        Marker(
          point: _currentPosition!,
          width: 48,
          height: 48,
          child: Icon(
            _shareLiveLocation ? Icons.my_location : Icons.location_history,
            color: _shareLiveLocation ? Colors.blue : Colors.blueGrey,
            size: 32,
          ),
        ),
    ];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Smart Logistics'),
        backgroundColor: const Color(0xFF00A699),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              _showBookingHistory(context);
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _currentPosition ?? _fallbackCenter,
                    initialZoom: _currentPosition == null ? 5.0 : 14.0,
                    onTap: (tapPosition, point) {
                      if (_selectedCompany != null) {
                        setState(() {
                          _selectedCompany = null;
                        });
                      }
                    },
                    onMapReady: () {
                      _isMapReady = true;
                      if (_currentPosition != null && !_hasCenteredOnUser) {
                        _mapController.move(_currentPosition!, 14.5);
                        _hasCenteredOnUser = true;
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: _isSatelliteView
                          ? _satelliteTileUrl
                          : _streetTileUrl,
                      userAgentPackageName: 'com.example.reworth',
                    ),
                    PolylineLayer(polylines: _buildSearchedAreaPolylines()),
                    MarkerLayer(markers: markers),
                  ],
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  top: 16,
                  child: _buildMapSearchBar(),
                ),
                Positioned(
                  left: 16,
                  top: 82,
                  child: Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    elevation: 3,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: () {
                        setState(() {
                          _isSatelliteView = !_isSatelliteView;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _isSatelliteView
                                  ? Icons.map_outlined
                                  : Icons.satellite_alt,
                              size: 18,
                              color: const Color(0xFF00A699),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isSatelliteView ? 'Map' : 'Satellite',
                              style: const TextStyle(
                                color: Color(0xFF00A699),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  top: 82,
                  child: FloatingActionButton.small(
                    heroTag: 'logistics_location_button',
                    onPressed: () {
                      if (_currentPosition != null && _isMapReady) {
                        _mapController.move(_currentPosition!, 14.5);
                      }
                    },
                    backgroundColor: Colors.white,
                    child: const Icon(
                      Icons.my_location,
                      color: Color(0xFF00A699),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.88,
            builder: (context, scrollController) {
              return Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(20),
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Nearby Buyers & Recyclers',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _bottomSheetSummary,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildCompanyFilterField(),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        FilterChip(
                          selected: _shareLiveLocation,
                          label: const Text('Live Location'),
                          avatar: Icon(
                            _shareLiveLocation
                                ? Icons.gps_fixed
                                : Icons.gps_off,
                            size: 18,
                          ),
                          onSelected: (selected) {
                            _toggleLocationSharing(selected);
                          },
                        ),
                        FilterChip(
                          selected: _showNearbyCompanies,
                          label: const Text('Nearby Buyers'),
                          avatar: const Icon(Icons.recycling, size: 18),
                          onSelected: (selected) {
                            _toggleNearbyCompanies(selected);
                          },
                        ),
                        FilterChip(
                          selected: _showAllCompanies,
                          label: const Text('All'),
                          avatar: const Icon(Icons.list, size: 18),
                          onSelected: (selected) {
                            _toggleShowAllCompanies(selected);
                          },
                        ),
                        ActionChip(
                          avatar: _isLoadingNearbyCompanies
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: const Text('Refresh'),
                          onPressed: _isLoadingNearbyCompanies
                              ? null
                              : () => _refreshNearbyCompanies(force: true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSheetBody(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showBookingHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.5,
          maxChildSize: 0.9,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Booking History Preview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF00A699).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Text(
                    'Live pickup history is not connected yet. These entries are sample records to preview the layout.',
                    style: TextStyle(height: 1.4),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: 3,
                    itemBuilder: (context, index) {
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.check_circle,
                              color: Colors.green,
                            ),
                          ),
                          title: Text('Sample booking #${1000 + index}'),
                          subtitle: Text(
                            'Preview item · ${index + 1} days ago',
                          ),
                          trailing: const Text(
                            '₹250',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
