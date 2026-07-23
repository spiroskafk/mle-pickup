import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Lets the organizer drop a pin on the map to set the venue, then name it.
/// Returns `(name, GeoPoint)` to the caller.
///
/// v1 uses a map pin + free-text name (no Places autocomplete — see SPEC §13).
class VenuePickerScreen extends StatefulWidget {
  const VenuePickerScreen({super.key});

  @override
  State<VenuePickerScreen> createState() => _VenuePickerScreenState();
}

class _VenuePickerScreenState extends State<VenuePickerScreen> {
  // Default camera: Patra, Greece — a sensible starting point for the author's
  // circle. The map recenters on the user's first interaction anyway.
  static const _initial = CameraPosition(
    target: LatLng(38.2466, 21.7346),
    zoom: 13,
  );

  final _nameController = TextEditingController();
  LatLng? _picked;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (_picked == null) return;
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Give the venue a name.')),
      );
      return;
    }
    Navigator.of(context).pop((
      name: name,
      geo: GeoPoint(_picked!.latitude, _picked!.longitude),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pick venue')),
      body: Column(
        children: [
          Expanded(
            child: GoogleMap(
              initialCameraPosition: _initial,
              onTap: (pos) => setState(() => _picked = pos),
              markers: {
                if (_picked != null)
                  Marker(
                    markerId: const MarkerId('venue'),
                    position: _picked!,
                  ),
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Venue name',
                    hintText: 'e.g. Athlopolis, Patra',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _picked == null ? null : _confirm,
                    child: Text(_picked == null
                        ? 'Tap the map to drop a pin'
                        : 'Use this venue'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
