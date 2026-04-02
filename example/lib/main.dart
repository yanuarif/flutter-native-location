import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_native_location/flutter_native_location.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Flutter Native Location',
    theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
    home: const TrackerPage(),
  );
}

class TrackerPage extends StatefulWidget {
  const TrackerPage({super.key});
  @override
  State<TrackerPage> createState() => _TrackerPageState();
}

class _TrackerPageState extends State<TrackerPage> {
  static const _config = LocationConfig(accuracy: LocationAccuracy.high);

  StreamSubscription<Position>? _sub;
  bool _isTracking = false;
  Position? _latest;
  final List<Position> _history = [];
  String? _errorMessage;

  // ── Actions ────────────────────────────────────────────────────────────────

  void _startTracking() {
    if (_isTracking) return;
    _sub = FlutterNativeLocation.getLocationStream(_config).listen(
      (point) {
        setState(() {
          _latest = point;
          _history.insert(0, point);
          _errorMessage = null;
        });
      },
      onError: (Object error) {
        final msg = error is PlatformException
            ? '[${error.code}] ${error.message}'
            : error.toString();
        setState(() => _errorMessage = msg);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Location error: $msg'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
    );
    setState(() => _isTracking = true);
  }

  Future<void> _stopTracking() async {
    await _sub?.cancel();
    _sub = null;
    setState(() => _isTracking = false);
  }

  Future<void> _getLastLocation() async {
    try {
      final loc = await FlutterNativeLocation.getLastLocation();
      if (loc != null) {
        setState(() {
          _latest = loc;
          _history.insert(0, loc);
          _errorMessage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Got last known location')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No cached location available')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      final loc = await FlutterNativeLocation.getCurrentLocation();
      if (loc != null) {
        setState(() {
          _latest = loc;
          _history.insert(0, loc);
          _errorMessage = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Got current location')));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  // ── UI ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Native Location'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.location_on), text: 'Live'),
              Tab(icon: Icon(Icons.list), text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _LiveTab(
              isTracking: _isTracking,
              config: _config,
              latest: _latest,
              errorMessage: _errorMessage,
              onStart: _startTracking,
              onStop: _stopTracking,
              onGetLastLocation: _getLastLocation,
              onGetCurrentLocation: _getCurrentLocation,
            ),
            _HistoryTab(history: _history),
          ],
        ),
      ),
    );
  }
}

// ── Live Tab ──────────────────────────────────────────────────────────────────

class _LiveTab extends StatelessWidget {
  final bool isTracking;
  final LocationConfig config;
  final Position? latest;
  final String? errorMessage;
  final VoidCallback onStart;
  final Future<void> Function() onStop;
  final VoidCallback onGetLastLocation;
  final VoidCallback onGetCurrentLocation;

  const _LiveTab({
    required this.isTracking,
    required this.config,
    required this.latest,
    required this.errorMessage,
    required this.onStart,
    required this.onStop,
    required this.onGetLastLocation,
    required this.onGetCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatusCard(isTracking: isTracking, config: config),
          if (errorMessage != null) ...[
            const SizedBox(height: 8),
            _ErrorBanner(message: errorMessage!),
          ],
          const SizedBox(height: 12),
          if (latest != null) _LocationCard(point: latest!),
          const SizedBox(height: 12),
          _TrackingButton(
            isTracking: isTracking,
            onStart: onStart,
            onStop: onStop,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGetLastLocation,
                  icon: const Icon(Icons.history, size: 18),
                  label: const Text('Last Known'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onGetCurrentLocation,
                  icon: const Icon(Icons.gps_fixed, size: 18),
                  label: const Text('Current Fix'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final bool isTracking;
  final LocationConfig config;
  const _StatusCard({required this.isTracking, required this.config});

  @override
  Widget build(BuildContext context) {
    final color = isTracking ? Colors.green : Colors.grey;
    return Card(
      child: ListTile(
        leading: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: isTracking
                ? [
                    BoxShadow(
                      color: Colors.green.withAlpha(120),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
        ),
        title: Text(
          isTracking ? 'Tracking' : 'Idle',
          style: TextStyle(color: color, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${config.accuracy.name} accuracy${config.timeLimit != null ? '  •  timeout ${config.timeLimit!.inSeconds}s' : ''}',
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _TrackingButton extends StatelessWidget {
  final bool isTracking;
  final VoidCallback onStart;
  final Future<void> Function() onStop;
  const _TrackingButton({
    required this.isTracking,
    required this.onStart,
    required this.onStop,
  });
  @override
  Widget build(BuildContext context) {
    if (isTracking) {
      return FilledButton.icon(
        onPressed: onStop,
        icon: const Icon(Icons.stop_circle_outlined),
        label: const Text('Stop Tracking'),
        style: FilledButton.styleFrom(backgroundColor: Colors.red),
      );
    }
    return FilledButton.icon(
      onPressed: onStart,
      icon: const Icon(Icons.location_on),
      label: const Text('Start Tracking'),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final Position point;
  const _LocationCard({required this.point});

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Latest Position', style: tt.titleMedium),
            const Divider(),
            _Row('Latitude', '${(point.latitude ?? 0).toStringAsFixed(6)}°'),
            _Row('Longitude', '${(point.longitude ?? 0).toStringAsFixed(6)}°'),
            _Row('Accuracy', '±${(point.accuracy ?? 0).toStringAsFixed(1)} m'),
            _Row('Altitude', '${(point.altitude ?? 0).toStringAsFixed(1)} m'),
            _Row(
              'Alt. Accuracy',
              '±${(point.altitudeAccuracy ?? 0).toStringAsFixed(1)} m',
            ),
            _Row(
              'Heading',
              point.heading != null && point.heading! >= 0
                  ? '${point.heading!.toStringAsFixed(1)}°'
                  : 'N/A',
            ),
            _Row(
              'Heading Acc.',
              point.headingAccuracy != null && point.headingAccuracy! >= 0
                  ? '±${point.headingAccuracy!.toStringAsFixed(1)}°'
                  : 'N/A',
            ),
            _Row('Speed', '${(point.speedKmh ?? 0).toStringAsFixed(1)} km/h'),
            _Row(
              'Speed Acc.',
              point.speedAccuracy != null && point.speedAccuracy! >= 0
                  ? '±${point.speedAccuracy!.toStringAsFixed(1)} m/s'
                  : 'N/A',
            ),
            _Row(
              'Timestamp',
              point.timestamp != null
                  ? point.timestamp!.toLocal().toString().substring(0, 19)
                  : 'N/A',
            ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label, value;
  const _Row(this.label, this.value);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontFamily: 'monospace',
          ),
        ),
      ],
    ),
  );
}

// ── History Tab ───────────────────────────────────────────────────────────────

class _HistoryTab extends StatelessWidget {
  final List<Position> history;
  const _HistoryTab({required this.history});

  @override
  Widget build(BuildContext context) {
    if (history.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 12),
            Text(
              'No location history yet',
              style: TextStyle(color: Colors.grey),
            ),
            SizedBox(height: 4),
            Text(
              'Start tracking to collect points',
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: history.length,
      itemBuilder: (_, i) {
        final p = history[i];
        return ListTile(
          leading: const Icon(Icons.location_pin, color: Colors.indigo),
          title: Text(
            '${(p.latitude ?? 0).toStringAsFixed(5)},  ${(p.longitude ?? 0).toStringAsFixed(5)}',
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
          ),
          subtitle: Text(
            '±${(p.accuracy ?? 0).toStringAsFixed(0)} m  •  '
            '${(p.speedKmh ?? 0).toStringAsFixed(1)} km/h  •  '
            '${p.timestamp?.toLocal().toIso8601String().substring(11, 19) ?? '--'}',
          ),
        );
      },
    );
  }
}
