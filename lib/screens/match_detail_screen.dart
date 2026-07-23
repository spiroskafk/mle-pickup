import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../services/auth_service.dart';

/// Match detail with join / leave / cancel. All mutations go through the
/// repository (Cloud Functions); this screen only reflects state and surfaces
/// errors returned by the server.
class MatchDetailScreen extends StatefulWidget {
  const MatchDetailScreen({super.key, required this.matchId});

  final String matchId;

  @override
  State<MatchDetailScreen> createState() => _MatchDetailScreenState();
}

class _MatchDetailScreenState extends State<MatchDetailScreen> {
  final _repo = MatchRepository();
  bool _busy = false;

  Future<void> _action(Future<void> Function() fn, String failMsg) async {
    setState(() => _busy = true);
    try {
      await fn();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failMsg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Match')),
      body: StreamBuilder<Match?>(
        stream: _repo.watch(widget.matchId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final match = snapshot.data;
          if (match == null) {
            return const Center(child: Text('This match no longer exists.'));
          }

          final isOrganizer = uid != null && match.organizerId == uid;
          final isIn = uid != null && match.containsPlayer(uid);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Text(match.sport.emoji,
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.sport.label,
                            style:
                                Theme.of(context).textTheme.headlineSmall),
                        Text(match.venue.name),
                      ],
                    ),
                  ),
                  _StatusChip(status: match.status),
                ],
              ),
              const SizedBox(height: 24),
              _InfoRow(
                icon: Icons.schedule,
                text: _formatDate(match.startAt),
              ),
              _InfoRow(
                icon: Icons.groups,
                text: '${match.playerIds.length} / ${match.totalPlayers} in'
                    '${match.spotsMissing > 0 ? ' · ${match.spotsMissing} missing' : ''}',
              ),
              if (match.chatLink != null)
                _InfoRow(icon: Icons.chat, text: match.chatLink!),
              const SizedBox(height: 32),
              _actionButton(match, isOrganizer, isIn),
            ],
          );
        },
      ),
    );
  }

  Widget _actionButton(Match match, bool isOrganizer, bool isIn) {
    if (match.status == MatchStatus.cancelled) {
      return const _DisabledNote('This match was cancelled.');
    }
    if (isOrganizer) {
      return OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => _action(
                () => _repo.cancel(match.id), 'Could not cancel.'),
        icon: const Icon(Icons.close),
        label: const Text('Cancel match'),
      );
    }
    if (isIn) {
      return OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () => _action(
                () => _repo.leave(match.id), 'Could not leave.'),
        icon: const Icon(Icons.exit_to_app),
        label: const Text('Leave match'),
      );
    }
    if (match.isFull) {
      return const _DisabledNote('This match is full.');
    }
    return FilledButton.icon(
      onPressed: _busy
          ? null
          : () => _action(() => _repo.join(match.id), 'Could not join.'),
      icon: const Icon(Icons.check),
      label: Text(_busy ? 'Joining…' : "I'm in"),
    );
  }

  String _formatDate(DateTime d) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year} · ${two(d.hour)}:${two(d.minute)}';
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final MatchStatus status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MatchStatus.open => ('Open', Colors.green),
      MatchStatus.full => ('Full', Colors.orange),
      MatchStatus.cancelled => ('Cancelled', Colors.red),
      MatchStatus.finished => ('Finished', Colors.grey),
    };
    return Chip(
      label: Text(label),
      backgroundColor: color.withOpacity(0.15),
    );
  }
}

class _DisabledNote extends StatelessWidget {
  const _DisabledNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
