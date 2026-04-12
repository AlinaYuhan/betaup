import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../data/models.dart';
import '../session/app_session.dart';
import 'common.dart';

const _chinaCenter = LatLng(35.8617, 104.1954);
const _defaultZoom = 4.2;
const _gymZoom = 12.5;
const _userZoom = 13.5;
const _gpsFenceMeters = 500.0;

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  final MapController _mapController = MapController();
  late final ConfettiController _confettiController;

  List<Gym> _gyms = [];
  bool _loading = true;
  bool _loaded = false;
  bool _mapReady = false;
  String? _error;
  int? _selectedGymId;
  LatLng? _userLocation;

  @override
  void initState() {
    super.initState();
    _confettiController =
        ConfettiController(duration: const Duration(seconds: 3));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) {
      return;
    }
    _loaded = true;
    _loadGyms();
  }

  Future<void> _loadGyms() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final gyms = await SessionScope.of(context).api.fetchGyms();
      if (!mounted) {
        return;
      }

      setState(() {
        _gyms = gyms;
        _selectedGymId = gyms.isEmpty ? null : gyms.first.id;
        _loading = false;
      });
      _fitMapToGyms();
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Gym? get _selectedGym {
    for (final gym in _gyms) {
      if (gym.id == _selectedGymId) {
        return gym;
      }
    }
    return null;
  }

  void _fitMapToGyms() {
    if (!_mapReady || _gyms.isEmpty) {
      return;
    }

    final points = _gyms.map((gym) => LatLng(gym.lat, gym.lng)).toList();
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: const EdgeInsets.all(40),
      ),
    );
  }

  void _focusGym(Gym gym, {bool openSheet = true}) {
    setState(() => _selectedGymId = gym.id);

    if (_mapReady) {
      _mapController.move(LatLng(gym.lat, gym.lng), _gymZoom);
    }

    if (openSheet) {
      _showGymDetail(gym);
    }
  }

  Future<void> _locateUser() async {
    try {
      final position = await _readPosition();
      final userLocation = LatLng(position.latitude, position.longitude);

      if (!mounted) {
        return;
      }

      setState(() => _userLocation = userLocation);
      if (_mapReady) {
        _mapController.move(userLocation, _userZoom);
      }

      showAppSnackBar(ScaffoldMessenger.of(context), "Location updated.");
    } catch (error) {
      if (!mounted) {
        return;
      }
      showAppSnackBar(ScaffoldMessenger.of(context), error.toString());
    }
  }

  void _showGymDetail(Gym gym) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => GymDetailSheet(
        gym: gym,
        onBadgeUnlocked: _onBadgeUnlocked,
      ),
    );
  }

  void _onBadgeUnlocked(List<BadgeProgress> badges) {
    if (badges.isEmpty) return;
    _confettiController.play();
    if (mounted) {
      showBadgeUnlockDialog(context, badges);
    }
  }

  List<Marker> _buildGymMarkers() {
    return _gyms.map((gym) {
      final isSelected = gym.id == _selectedGymId;

      return Marker(
        point: LatLng(gym.lat, gym.lng),
        width: 60,
        height: 60,
        child: GestureDetector(
          onTap: () => _focusGym(gym),
          child: _GymPinMarker(
            selected: isSelected,
            label: gym.name,
          ),
        ),
      );
    }).toList();
  }

  Widget _buildMapCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const SectionLabel("Map"),
              const Spacer(),
              if (_selectedGym != null)
                StatusChip(
                  label: _selectedGym!.city,
                  color: const Color(0xFFFFB26D),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            "Tap a pin to open the gym detail sheet and check in.",
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: SizedBox(
              height: 320,
              child: FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _chinaCenter,
                  initialZoom: _defaultZoom,
                  onMapReady: () {
                    _mapReady = true;
                    _fitMapToGyms();
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                    userAgentPackageName: "com.betaup.mobile",
                  ),
                  MarkerLayer(markers: _buildGymMarkers()),
                  if (_userLocation != null)
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: _userLocation!,
                          width: 36,
                          height: 36,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF7BE0FF),
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x667BE0FF),
                                  blurRadius: 14,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  const RichAttributionWidget(
                    showFlutterMapAttribution: false,
                    attributions: [
                      TextSourceAttribution(
                        "OpenStreetMap contributors",
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGymList() {
    if (_loading) {
      return const LoaderCard(label: "Loading gym map");
    }

    if (_error != null) {
      return ErrorCard(
        message: _error!,
        onRetry: _loadGyms,
      );
    }

    if (_gyms.isEmpty) {
      return const EmptyCard(
        title: "No gyms",
        message: "The backend returned no gyms to display.",
      );
    }

    final theme = Theme.of(context);

    return Column(
      children: _gyms.map((gym) {
        final isSelected = gym.id == _selectedGymId;
        final distance = _userLocation == null
            ? null
            : Geolocator.distanceBetween(
                _userLocation!.latitude,
                _userLocation!.longitude,
                gym.lat,
                gym.lng,
              );

        return GlassCard(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          padding: EdgeInsets.zero,
          backgroundColor: isSelected
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.white.withValues(alpha: 0.10),
          borderColor: isSelected
              ? const Color(0x66FF7A18)
              : Colors.white.withValues(alpha: 0.16),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => _focusGym(gym),
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0x24FF7A18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0x44FF7A18)),
                      ),
                      child: const Icon(
                        Icons.location_on_rounded,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  gym.name,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              if (distance != null)
                                StatusChip(
                                  label: _formatDistance(distance),
                                  color: distance <= _gpsFenceMeters
                                      ? const Color(0xFF5ED9A6)
                                      : const Color(0xFF7BE0FF),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "${gym.city} · ${gym.address}",
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFFD5E0EE),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _typeLabels(gym.types)
                                .map(
                                  (type) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.10,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      type,
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Explore Gyms"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: "Locate me",
            onPressed: _locateUser,
          ),
        ],
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _loadGyms,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 12, 0, 28),
              children: [
                _buildMapCard(),
                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 12, 20, 10),
                  child: SectionLabel("Gym List"),
                ),
                _buildGymList(),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: IgnorePointer(
              child: ConfettiWidget(
                confettiController: _confettiController,
                blastDirectionality: BlastDirectionality.explosive,
                colors: const [
                  Colors.orange,
                  Colors.deepOrange,
                  Colors.amber,
                  Colors.yellow,
                ],
                numberOfParticles: 40,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GymDetailSheet extends StatefulWidget {
  const GymDetailSheet({
    super.key,
    required this.gym,
    required this.onBadgeUnlocked,
  });

  final Gym gym;
  final void Function(List<BadgeProgress> badges) onBadgeUnlocked;

  @override
  State<GymDetailSheet> createState() => _GymDetailSheetState();
}

class _GymDetailSheetState extends State<GymDetailSheet> {
  bool _checkingIn = false;

  Future<void> _checkIn({bool useGps = false}) async {
    setState(() => _checkingIn = true);

    try {
      double? lat;
      double? lng;

      if (useGps) {
        final position = await _readPosition();
        lat = position.latitude;
        lng = position.longitude;
      }

      if (!mounted) {
        return;
      }

      final result = await SessionScope.of(context).api.checkIn(
        gymId: widget.gym.id,
        userLat: lat,
        userLng: lng,
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop();
      widget.onBadgeUnlocked(result.newlyUnlockedBadges);

      showAppSnackBar(
        ScaffoldMessenger.of(context),
        result.gpsVerified
            ? "GPS check-in successful."
            : "Manual check-in recorded.",
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      showAppSnackBar(
        ScaffoldMessenger.of(context),
        error.toString(),
      );
    } finally {
      if (mounted) {
        setState(() => _checkingIn = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;
    final theme = Theme.of(context);
    final typeChips = _typeLabels(gym.types)
        .map(
          (type) => Chip(
            label: Text(type),
            visualDensity: VisualDensity.compact,
          ),
        )
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.58,
      maxChildSize: 0.9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 42,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            gym.name,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            gym.city,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          if (typeChips.isNotEmpty) Wrap(spacing: 8, children: typeChips),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.location_on_outlined, text: gym.address),
          if (gym.phone.isNotEmpty)
            _InfoRow(icon: Icons.phone_outlined, text: gym.phone),
          if (gym.openHours.isNotEmpty)
            _InfoRow(icon: Icons.access_time_outlined, text: gym.openHours),
          if (gym.bookingUrl.isNotEmpty)
            _InfoRow(icon: Icons.link_outlined, text: gym.bookingUrl),
          const SizedBox(height: 16),
          Text(
            "GPS check-in verifies whether you are within ${_gpsFenceMeters.toInt()} meters of this gym.",
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (_checkingIn)
            const Center(child: CircularProgressIndicator())
          else ...[
            ElevatedButton.icon(
              onPressed: () => _checkIn(useGps: true),
              icon: const Icon(Icons.gps_fixed),
              label: const Text("GPS Check-In"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: () => _checkIn(useGps: false),
              icon: const Icon(Icons.edit_location_outlined),
              label: const Text("Manual Check-In"),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(44),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GymPinMarker extends StatelessWidget {
  const _GymPinMarker({
    required this.selected,
    required this.label,
  });

  final bool selected;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x66FF7A18),
                    blurRadius: 14,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Icon(
          Icons.location_on_rounded,
          size: selected ? 34 : 30,
          color: selected ? const Color(0xFFFF7A18) : const Color(0xFF7BE0FF),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

Future<Position> _readPosition() async {
  final locationEnabled = await Geolocator.isLocationServiceEnabled();
  if (!locationEnabled) {
    throw Exception("Location services are disabled.");
  }

  var permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
  }

  if (permission == LocationPermission.denied ||
      permission == LocationPermission.deniedForever) {
    throw Exception("Location permission is required.");
  }

  return Geolocator.getCurrentPosition().timeout(
    const Duration(seconds: 8),
  );
}

List<String> _typeLabels(String rawTypes) {
  return rawTypes
      .split(",")
      .map((type) => type.trim())
      .where((type) => type.isNotEmpty)
      .toList(growable: false);
}

String _formatDistance(double meters) {
  if (meters < 1000) {
    return "${meters.round()} m";
  }

  return "${(meters / 1000).toStringAsFixed(meters < 10000 ? 1 : 0)} km";
}
