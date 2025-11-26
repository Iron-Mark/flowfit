import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/geofence_mission.dart';
import '../data/geofence_repository.dart';
import '../data/geofence_supabase_repository.dart';
import '../services/geofence_service.dart';

class WellnessMapsPage extends StatefulWidget {
  const WellnessMapsPage({super.key});

  @override
  State<WellnessMapsPage> createState() => _WellnessMapsPageState();
}

class _WellnessMapsPageState extends State<WellnessMapsPage> {
  GoogleMapController? _mapController;
  CameraPosition? _initialCamera;
  StreamSubscription<GeofenceEvent>? _eventsSub;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _initialCamera = CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 16);
      });
      final service = context.read<GeofenceService>();
      await service.startMonitoring();
      _eventsSub = service.events.listen((event) {
        final repo = context.read<GeofenceRepository>();
        final m = repo.getById(event.missionId);
        if (m == null) return;
        final message = _buildEventMessage(m, event);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
      });
    } catch (e) {
      // ignore
    }
  }

  @override
  void dispose() {
    _mapController?.dispose();
    _eventsSub?.cancel();
    super.dispose();
  }

  String _buildEventMessage(GeofenceMission m, GeofenceEvent event) {
    switch (event.type) {
      case GeofenceEventType.entered:
        return '${m.title} - entered';
      case GeofenceEventType.exited:
        return '${m.title} - exited';
      case GeofenceEventType.targetReached:
        return '${m.title} - progress ${ (event.value ?? 0).toStringAsFixed(1)} m';
      case GeofenceEventType.outsideAlert:
        return '${m.title} - outside ${ (event.value ?? 0).toStringAsFixed(1)} m';
    }
  }

  Future<void> _addGeofenceAtLatLng(LatLng latLng) async {
    final mission = await showDialog<GeofenceMission>(
      context: context,
      builder: (ctx) {
        return _AddMissionDialog(latLng: latLng);
      },
    );
    if (mission != null) {
      final repo = context.read<GeofenceRepository>();
      await repo.add(mission);
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<GeofenceRepository>();
    final service = context.watch<GeofenceService>();

    final markers = <Marker>{};
    final circles = <Circle>{};

    for (final m in repo.current) {
      final marker = Marker(
        markerId: MarkerId(m.id),
        position: LatLng(m.center.latitude, m.center.longitude),
        infoWindow: InfoWindow(title: m.title, snippet: m.description ?? ''),
        onTap: () async {
          // center map and open panel
          await _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(m.center.latitude, m.center.longitude)));
          _showMissionActions(m);
        },
          draggable: true,
          onDragEnd: (newPosition) async {
            final updated = m.copyWith(center: LatLngSimple(newPosition.latitude, newPosition.longitude));
            await context.read<GeofenceRepository>().update(updated);
          },
      );
      markers.add(marker);
      final circle = Circle(
        circleId: CircleId(m.id),
        center: LatLng(m.center.latitude, m.center.longitude),
        radius: m.radiusMeters,
        fillColor: (m.isActive ? Colors.greenAccent.withOpacity(0.2) : Colors.redAccent.withOpacity(0.1)),
        strokeColor: m.isActive ? Colors.green : Colors.red,
      );
      circles.add(circle);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Wellness Missions (Geofence Engine)'), actions: [
        IconButton(
          icon: const Icon(Icons.sync),
          tooltip: 'Sync with server',
          onPressed: () async {
            final repoInst = context.read<GeofenceRepository>();
            try {
              if (repoInst is GeofenceSupabaseRepository) {
                await repoInst.sync();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Synced geofences with server')));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sync not available for this repository')));
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to sync with server')));
            }
          },
        ),
      ]) ,
      body: Column(
        children: [
          Flexible(
            flex: 3,
            child: _initialCamera == null
                ? const Center(child: CircularProgressIndicator())
                : GoogleMap(
                    initialCameraPosition: _initialCamera!,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    mapType: MapType.normal,
                    onMapCreated: (c) => _mapController = c,
                    markers: markers,
                    circles: circles,
                    onLongPress: (latLng) => _addGeofenceAtLatLng(latLng),
                  ),
          ),
          Flexible(
            flex: 2,
            child: _buildMissionList(repo, service),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // center to current location
          final pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 16));
        },
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildMissionList(GeofenceRepository repo, GeofenceService service) {
    return Material(
      elevation: 2,
      child: ListView(
        children: repo.current.map((m) {
          return ListTile(
            title: Text(m.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${describeEnum(m.type)} - ${m.radiusMeters.toStringAsFixed(0)} m'),
                    if (m.type == MissionType.target)
                      Padding(
                        padding: const EdgeInsets.only(top: 6.0),
                        child: LinearProgressIndicator(
                          value: (m.targetDistanceMeters == null || m.targetDistanceMeters == 0)
                              ? 0.0
                              : (service.getProgress(m.id) / (m.targetDistanceMeters ?? 1.0)).clamp(0.0, 1.0),
                        ),
                      ),
                  ],
                ),
            trailing: Row(mainAxisSize: MainAxisSize.min, children: [
              Switch(value: m.isActive, onChanged: (v) => v ? service.activateMission(m.id) : service.deactivateMission(m.id)),
              IconButton(
                icon: const Icon(Icons.delete),
                onPressed: () async {
                  await repo.delete(m.id);
                },
              ),
            ]),
            onTap: () async {
              await _mapController?.animateCamera(CameraUpdate.newLatLng(LatLng(m.center.latitude, m.center.longitude)));
            },
          );
        }).toList(),
      ),
    );
  }

  void _showMissionActions(GeofenceMission mission) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(mission.title),
              subtitle: Text(mission.description ?? ''),
            ),
            ListTile(
              leading: const Icon(Icons.play_arrow),
              title: const Text('Activate'),
              onTap: () async {
                final service = context.read<GeofenceService>();
                await service.activateMission(mission.id);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.stop),
              title: const Text('Deactivate'),
              onTap: () async {
                final service = context.read<GeofenceService>();
                await service.deactivateMission(mission.id);
                Navigator.of(context).pop();
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit'),
              onTap: () async {
                final edited = await showDialog<GeofenceMission>(
                  context: context,
                  builder: (_) => _EditMissionDialog(mission: mission),
                );
                if (edited != null) {
                  await context.read<GeofenceRepository>().update(edited);
                }
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }
}

class _AddMissionDialog extends StatefulWidget {
  final LatLng latLng;
  const _AddMissionDialog({required this.latLng});

  @override
  State<_AddMissionDialog> createState() => _AddMissionDialogState();
}

class _EditMissionDialog extends StatefulWidget {
  final GeofenceMission mission;
  const _EditMissionDialog({required this.mission});

  @override
  State<_EditMissionDialog> createState() => _EditMissionDialogState();
}

class _EditMissionDialogState extends State<_EditMissionDialog> {
  late String _title;
  String? _description;
  late MissionType _type;
  late double _radius;
  double? _targetDistance;

  @override
  void initState() {
    super.initState();
    _title = widget.mission.title;
    _description = widget.mission.description;
    _type = widget.mission.type;
    _radius = widget.mission.radiusMeters;
    _targetDistance = widget.mission.targetDistanceMeters;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit Mission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: TextEditingController(text: _title),
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => setState(() => _title = v),
            ),
            TextField(
              controller: TextEditingController(text: _description),
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => _description = v),
            ),
            DropdownButton<MissionType>(
              value: _type,
              items: MissionType.values.map((t) => DropdownMenuItem(value: t, child: Text(describeEnum(t)))).toList(),
              onChanged: (v) => setState(() => _type = v ?? MissionType.sanctuary),
            ),
            Row(children: [
              const Text('Radius (m)'),
              Expanded(
                child: Slider(
                  min: 10,
                  max: 2000,
                  value: _radius,
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ),
              Text('${_radius.toStringAsFixed(0)}'),
            ]),
            if (_type == MissionType.target)
              TextField(
                decoration: const InputDecoration(labelText: 'Target distance (m)'),
                keyboardType: TextInputType.number,
                controller: TextEditingController(text: _targetDistance?.toString()),
                onChanged: (v) => setState(() => _targetDistance = double.tryParse(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final updated = widget.mission.copyWith(
              title: _title,
              description: _description,
              radiusMeters: _radius,
              type: _type,
              targetDistanceMeters: _targetDistance,
            );
            Navigator.of(context).pop(updated);
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _AddMissionDialogState extends State<_AddMissionDialog> {
  String _title = '';
  String? _description;
  MissionType _type = MissionType.sanctuary;
  double _radius = 50.0;
  double? _targetDistance;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Mission'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: const InputDecoration(labelText: 'Title'),
              onChanged: (v) => setState(() => _title = v),
            ),
            TextField(
              decoration: const InputDecoration(labelText: 'Description'),
              onChanged: (v) => setState(() => _description = v),
            ),
            DropdownButton<MissionType>(
              value: _type,
              items: MissionType.values.map((t) => DropdownMenuItem(value: t, child: Text(describeEnum(t)))).toList(),
              onChanged: (v) => setState(() => _type = v ?? MissionType.sanctuary),
            ),
            Row(children: [
              const Text('Radius (m)'),
              Expanded(
                child: Slider(
                  min: 10,
                  max: 1000,
                  value: _radius,
                  onChanged: (v) => setState(() => _radius = v),
                ),
              ),
              Text('${_radius.toStringAsFixed(0)}'),
            ]),
            if (_type == MissionType.target)
              TextField(
                decoration: const InputDecoration(labelText: 'Target distance (m)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _targetDistance = double.tryParse(v)),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        TextButton(
          onPressed: () {
            final id = DateTime.now().millisecondsSinceEpoch.toString();
            final mission = GeofenceMission(
              id: id,
              title: _title.isEmpty ? 'Mission $id' : _title,
              description: _description,
              center: LatLngSimple(widget.latLng.latitude, widget.latLng.longitude),
              radiusMeters: _radius,
              type: _type,
              targetDistanceMeters: _targetDistance,
            );
            Navigator.of(context).pop(mission);
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
