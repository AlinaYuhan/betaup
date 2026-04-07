import 'dart:convert';
import 'dart:io';

import 'package:confetti/confetti.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:geolocator/geolocator.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../data/api_client.dart';
import '../data/models.dart';
import '../session/app_session.dart';

// WebView only works on Android and iOS (not Web, not Windows/macOS/Linux)
bool get _webViewSupported =>
    !kIsWeb && (Platform.isAndroid || Platform.isIOS);

class ExploreTab extends StatefulWidget {
  const ExploreTab({super.key});

  @override
  State<ExploreTab> createState() => _ExploreTabState();
}

class _ExploreTabState extends State<ExploreTab> {
  late final WebViewController _webController;
  late final ConfettiController _confettiController;
  List<Gym> _gyms = [];
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    if (_webViewSupported) _initWebView();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _initWebView() {
    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'FlutterChannel',
        onMessageReceived: _onMapMessage,
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) async {
          setState(() => _mapReady = true);
          await _loadGymsIntoMap();
        },
      ));

    rootBundle.loadString('assets/map/map.html').then((html) {
      _webController.loadHtmlString(html, baseUrl: 'https://betaup.app');
    });
  }

  Future<void> _loadGymsIntoMap() async {
    final session = SessionScope.of(context);
    final client = ApiClient(readToken: () => session.token);
    try {
      final gyms = await client.fetchGyms();
      setState(() => _gyms = gyms);
      final jsonStr = jsonEncode(gyms.map((g) => g.toJson()).toList());
      await _webController.runJavaScript('loadGyms(${jsonEncode(jsonStr)})');
    } catch (_) {
      // Silently fail — map still loads, gyms just won't appear
    }
  }

  void _onMapMessage(JavaScriptMessage msg) {
    try {
      final data = jsonDecode(msg.message) as Map<String, dynamic>;
      if (data['action'] == 'gymSelected') {
        final gym = Gym.fromJson(Map<String, dynamic>.from(data['gym'] as Map));
        _showGymDetail(gym);
      }
    } catch (_) {}
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

  void _onBadgeUnlocked(List<String> badgeKeys) {
    if (badgeKeys.isEmpty) return;
    _confettiController.play();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("🏅 解锁了 ${badgeKeys.length} 个新徽章！"),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("探索攀岩馆"),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            tooltip: "定位我",
            onPressed: _locateUser,
          ),
        ],
      ),
      body: _webViewSupported
          ? Stack(
              children: [
                WebViewWidget(controller: _webController),
                if (!_mapReady)
                  const Center(child: CircularProgressIndicator()),
                Align(
                  alignment: Alignment.topCenter,
                  child: ConfettiWidget(
                    confettiController: _confettiController,
                    blastDirectionality: BlastDirectionality.explosive,
                    colors: const [Colors.orange, Colors.deepOrange, Colors.amber, Colors.yellow],
                    numberOfParticles: 40,
                  ),
                ),
              ],
            )
          : _GymListFallback(onBadgeUnlocked: _onBadgeUnlocked),
    );
  }

  Future<void> _locateUser() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      await _webController.runJavaScript('locateUser(${pos.latitude}, ${pos.longitude})');
    } catch (_) {}
  }
}

class _GymListFallback extends StatefulWidget {
  const _GymListFallback({required this.onBadgeUnlocked});
  final void Function(List<String>) onBadgeUnlocked;

  @override
  State<_GymListFallback> createState() => _GymListFallbackState();
}

class _GymListFallbackState extends State<_GymListFallback> {
  List<Gym> _gyms = [];
  bool _loading = true;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final session = SessionScope.of(context);
      final client = ApiClient(readToken: () => session.token);
      final gyms = await client.fetchGyms();
      if (mounted) setState(() { _gyms = gyms; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    return ListView.builder(
      itemCount: _gyms.length,
      itemBuilder: (context, index) {
        final gym = _gyms[index];
        return ListTile(
          leading: const Icon(Icons.location_on, color: Colors.orange),
          title: Text(gym.name),
          subtitle: Text("${gym.city} · ${gym.address}"),
          onTap: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            useSafeArea: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => GymDetailSheet(
              gym: gym,
              onBadgeUnlocked: widget.onBadgeUnlocked,
            ),
          ),
        );
      },
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
  final void Function(List<String> badgeKeys) onBadgeUnlocked;

  @override
  State<GymDetailSheet> createState() => _GymDetailSheetState();
}

class _GymDetailSheetState extends State<GymDetailSheet> {
  bool _checkingIn = false;

  Future<void> _checkIn({bool useGps = false}) async {
    setState(() => _checkingIn = true);
    try {
      double? lat, lng;
      if (useGps) {
        final pos = await Geolocator.getCurrentPosition()
            .timeout(const Duration(seconds: 8));
        lat = pos.latitude;
        lng = pos.longitude;
      }

      final session = SessionScope.of(context);
      final client = ApiClient(readToken: () => session.token);
      final result = await client.checkIn(
        gymId: widget.gym.id,
        userLat: lat,
        userLng: lng,
      );

      if (!mounted) return;
      Navigator.of(context).pop();
      widget.onBadgeUnlocked(result.newBadgeKeys);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.gpsVerified ? "✅ GPS 验证打卡成功！" : "📝 手动打卡已记录"),
          duration: const Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("打卡失败：$e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _checkingIn = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gym = widget.gym;
    final typeChips = gym.types
        .split(',')
        .where((t) => t.isNotEmpty)
        .map((t) => Chip(label: Text(t.trim()), visualDensity: VisualDensity.compact))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.55,
      maxChildSize: 0.9,
      builder: (_, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(gym.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(gym.city, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey)),
          const SizedBox(height: 12),
          if (typeChips.isNotEmpty) Wrap(spacing: 8, children: typeChips),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.location_on_outlined, text: gym.address),
          if (gym.phone.isNotEmpty) _InfoRow(icon: Icons.phone_outlined, text: gym.phone),
          if (gym.openHours.isNotEmpty) _InfoRow(icon: Icons.access_time_outlined, text: gym.openHours),
          const SizedBox(height: 24),
          if (_checkingIn)
            const Center(child: CircularProgressIndicator())
          else ...[
            ElevatedButton.icon(
              onPressed: () => _checkIn(useGps: true),
              icon: const Icon(Icons.gps_fixed),
              label: const Text("GPS 打卡（验证距离）"),
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
              label: const Text("手动打卡"),
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
          Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
