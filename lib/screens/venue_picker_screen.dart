import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Lets the organizer set the venue and returns `(name, GeoPoint)`.
///
/// On a device with a configured Google Maps key, this shows an interactive
/// map and you drop a pin. Where the map isn't available yet — web, or before
/// a Maps API key is set up — it falls back to a manual form (name + optional
/// coordinates), so the create-match flow is never blocked on Maps setup.
class VenuePickerScreen extends StatelessWidget {
  const VenuePickerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // The web build has no Maps key wired up in index.html yet, so use the
    // manual fallback there. Native builds use the map.
    return kIsWeb ? const _ManualVenueForm() : const _MapVenuePicker();
  }
}

// ---------------------------------------------------------------------------
// Manual fallback (no map)
// ---------------------------------------------------------------------------

class _ManualVenueForm extends StatefulWidget {
  const _ManualVenueForm();

  @override
  State<_ManualVenueForm> createState() => _ManualVenueFormState();
}

class _ManualVenueFormState extends State<_ManualVenueForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  // Default coordinates: Patra, Greece. Fine for local testing; on device the
  // map picker sets real coordinates.
  final _latController = TextEditingController(text: '38.2466');
  final _lngController = TextEditingController(text: '21.7346');

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _confirm() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((
      name: _nameController.text.trim(),
      geo: GeoPoint(
        double.parse(_latController.text),
        double.parse(_lngController.text),
      ),
    ));
  }

  String? _coord(String? v, double min, double max) {
    final n = double.tryParse(v ?? '');
    if (n == null) return 'Enter a number';
    if (n < min || n > max) return 'Out of range';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Venue')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Map picker is available on the mobile app. For now, enter the '
              'venue name (and optionally adjust coordinates).',
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Venue name',
                hintText: 'e.g. Athlopolis, Patra',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _latController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _coord(v, -90, 90),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _lngController,
                    keyboardType: const TextInputType.numberWithOptions(
                        decimal: true, signed: true),
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => _coord(v, -180, 180),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _confirm,
              child: const Text('Use this venue'),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Map picker (native)
// ---------------------------------------------------------------------------

class _MapVenuePicker extends StatefulWidget {
  const _MapVenuePicker();

  @override
  State<_MapVenuePicker> createState() => _MapVenuePickerState();
}

class _MapVenuePickerState extends State<_MapVenuePicker> {
  static const _initial = CameraPosition(
    target: LatLng(38.2466, 21.7346), // Patra
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
