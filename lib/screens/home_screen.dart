import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../services/auth_service.dart';
import 'create_match_screen.dart';
import 'match_detail_screen.dart';

/// Discover screen: a live list of open matches. Map view and the sport filter
/// are follow-ups (SPEC §10); this establishes the read path and the join flow.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = MatchRepository();
    final auth = context.read<AuthService>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open matches'),
        actions: [
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: auth.signOut,
          ),
        ],
      ),
      body: StreamBuilder<List<Match>>(
        stream: repo.watchOpen(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load matches.'));
          }
          final matches = snapshot.data ?? const [];
          if (matches.isEmpty) {
            return const _EmptyState();
          }
          return ListView.separated(
            itemCount: matches.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, i) => _MatchTile(match: matches[i]),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CreateMatchScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New match'),
      ),
    );
  }
}

class _MatchTile extends StatelessWidget {
  const _MatchTile({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final missing = match.spotsMissing;
    return ListTile(
      leading: Text(match.sport.emoji,
          style: const TextStyle(fontSize: 28)),
      title: Text('${match.sport.label} · ${match.venue.name}'),
      subtitle: Text(_subtitle()),
      trailing: missing > 0
          ? Chip(label: Text('$missing missing'))
          : const Chip(label: Text('Full')),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => MatchDetailScreen(matchId: match.id),
          ),
        );
      },
    );
  }

  String _subtitle() {
    final d = match.startAt;
    final two = (int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}'
        ' · ${match.playerIds.length}/${match.totalPlayers} in';
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚽', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            Text(
              'No open matches nearby',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first — create a match and fill your spots.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
