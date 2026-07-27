import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';

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
      HapticFeedback.lightImpact();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failMsg)));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<bool> _confirm(String title, String message) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes'),
          ),
        ],
      ),
    );
    return result ?? false;
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
                  Hero(
                    tag: 'match-${match.id}',
                    child: Text(match.sport.emoji,
                        style: const TextStyle(fontSize: 40)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(match.sport.label,
                            style: Theme.of(context).textTheme.headlineSmall),
                        Text(match.venue.name),
                      ],
                    ),
                  ),
                  _StatusChip(status: match.status),
                ],
              ),
              const SizedBox(height: 24),
              _InfoCard(
                icon: Icons.schedule,
                text: _formatDate(match.startAt),
              ),
              const SizedBox(height: 8),
              _InfoCard(
                icon: Icons.groups,
                text: '${match.playerIds.length} / ${match.totalPlayers} in'
                    '${match.spotsMissing > 0 ? ' · ${match.spotsMissing} missing' : ''}',
              ),
              if (match.chatLink != null) ...[
                const SizedBox(height: 8),
                _InfoCard(icon: Icons.chat, text: match.chatLink!),
              ],
              const SizedBox(height: 24),
              _ParticipantsSection(
                playerCount: match.playerIds.length,
                totalPlayers: match.totalPlayers,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: _actionButton(match, isOrganizer, isIn),
              ),
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
            : () async {
                if (await _confirm('Cancel match?',
                    'This will cancel the match for all players.')) {
                  _action(
                      () => _repo.cancel(match.id), 'Could not cancel.');
                }
              },
        icon: const Icon(Icons.close),
        label: const Text('Cancel match'),
      );
    }
    if (isIn) {
      return OutlinedButton.icon(
        onPressed: _busy
            ? null
            : () async {
                if (await _confirm('Leave match?',
                    'Are you sure you want to leave this match?')) {
                  _action(
                      () => _repo.leave(match.id), 'Could not leave.');
                }
              },
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

class _ParticipantsSection extends StatelessWidget {
  const _ParticipantsSection({
    required this.playerCount,
    required this.totalPlayers,
  });

  final int playerCount;
  final int totalPlayers;

  @override
  Widget build(BuildContext context) {
    final displayCount = playerCount.clamp(0, 5);
    final extra = playerCount - 5;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Participants',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (int i = 0; i < displayCount; i++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.pitchGreen.withValues(alpha: 0.15),
                  child: Text(
                    'P${i + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (extra > 0)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey.shade300,
                  child: Text(
                    '+$extra',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            if (playerCount == 0)
              Text(
                'No participants yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
          ],
        ),
      ],
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
      backgroundColor: color.withValues(alpha: 0.15),
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
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, textAlign: TextAlign.center),
    );
  }
}
