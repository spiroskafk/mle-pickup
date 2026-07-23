import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../models/sport.dart';
import '../repositories/match_repository.dart';
import '../services/auth_service.dart';
import 'venue_picker_screen.dart';

/// Form to create a new match. The organizer is taken from the authenticated
/// caller server-side, so this screen only collects sport, venue, time,
/// player count, and an optional chat link.
class CreateMatchScreen extends StatefulWidget {
  const CreateMatchScreen({super.key});

  @override
  State<CreateMatchScreen> createState() => _CreateMatchScreenState();
}

class _CreateMatchScreenState extends State<CreateMatchScreen> {
  final _formKey = GlobalKey<FormState>();
  final _chatLinkController = TextEditingController();
  final _repo = MatchRepository();

  Sport _sport = Sport.football;
  int _totalPlayers = 10;
  DateTime? _startAt;
  ({String name, GeoPoint geo})? _venue;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _chatLinkController.dispose();
    super.dispose();
  }

  Future<void> _pickVenue() async {
    final result =
        await Navigator.of(context).push<({String name, GeoPoint geo})>(
      MaterialPageRoute(builder: (_) => const VenuePickerScreen()),
    );
    if (result != null) setState(() => _venue = result);
  }

  Future<void> _pickDateTime() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      firstDate: now,
      lastDate: now.add(const Duration(days: 90)),
      initialDate: _startAt ?? now,
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_startAt ?? now),
    );
    if (time == null) return;
    setState(() {
      _startAt =
          DateTime(date.year, date.month, date.day, time.hour, time.minute);
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_venue == null) {
      setState(() => _error = 'Pick a venue on the map.');
      return;
    }
    if (_startAt == null) {
      setState(() => _error = 'Pick a date and time.');
      return;
    }

    final uid = context.read<AuthService>().currentUser?.uid;
    if (uid == null) {
      setState(() => _error = 'You need to be signed in.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    // organizerId/status/playerIds are set server-side; we pass placeholders
    // that toCreateMap() doesn't serialize anyway.
    final match = Match(
      id: '',
      sport: _sport,
      organizerId: uid,
      venue: Venue(name: _venue!.name, geo: _venue!.geo),
      startAt: _startAt!,
      totalPlayers: _totalPlayers,
      status: MatchStatus.open,
      playerIds: const [],
      chatLink: _chatLinkController.text.trim().isEmpty
          ? null
          : _chatLinkController.text.trim(),
    );

    try {
      await _repo.create(match);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not create the match. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('New match')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Sport>(
              initialValue: _sport,
              decoration: const InputDecoration(
                labelText: 'Sport',
                border: OutlineInputBorder(),
              ),
              items: [
                for (final s in Sport.values)
                  DropdownMenuItem(
                    value: s,
                    child: Text('${s.emoji}  ${s.label}'),
                  ),
              ],
              onChanged: (v) => setState(() => _sport = v ?? Sport.football),
            ),
            const SizedBox(height: 16),
            _PickerTile(
              icon: Icons.place_outlined,
              label: 'Venue',
              value: _venue?.name ?? 'Pick on map',
              onTap: _pickVenue,
            ),
            const SizedBox(height: 8),
            _PickerTile(
              icon: Icons.schedule,
              label: 'When',
              value: _startAt == null
                  ? 'Pick date & time'
                  : _formatDate(_startAt!),
              onTap: _pickDateTime,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Total players'),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  onPressed: _totalPlayers > 2
                      ? () => setState(() => _totalPlayers--)
                      : null,
                ),
                Text('$_totalPlayers',
                    style: Theme.of(context).textTheme.titleMedium),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: _totalPlayers < 30
                      ? () => setState(() => _totalPlayers++)
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _chatLinkController,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'Chat link (optional)',
                hintText: 'WhatsApp/Viber group invite',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 24),
            FilledButton(
              onPressed: _busy ? null : _submit,
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Create match'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(value),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
