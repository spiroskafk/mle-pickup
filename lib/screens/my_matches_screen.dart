import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/match.dart';
import '../repositories/match_repository.dart';
import '../services/auth_service.dart';
import '../theme/app_colors.dart';
import 'match_detail_screen.dart';

class MyMatchesScreen extends StatelessWidget {
  const MyMatchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthService>().currentUser!.uid;
    final repo = MatchRepository();

    return Scaffold(
      appBar: AppBar(title: const Text('My Matches')),
      body: StreamBuilder<List<Match>>(
        stream: repo.watchForPlayer(uid),
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
          return RefreshIndicator(
            onRefresh: () async {},
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: matches.length,
              itemBuilder: (context, i) => _MatchCard(match: matches[i]),
            ),
          );
        },
      ),
    );
  }
}

class _MatchCard extends StatelessWidget {
  const _MatchCard({required this.match});

  final Match match;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sportColor = AppColors.sportColor(match.sport.id);
    final d = match.startAt;
    String two(int n) => n.toString().padLeft(2, '0');
    final dateTime =
        '${two(d.day)}/${two(d.month)} ${two(d.hour)}:${two(d.minute)}';
    final playerCount = '${match.playerIds.length}/${match.totalPlayers}';
    final missing = match.spotsMissing;
    final fillRatio = match.totalPlayers > 0
        ? match.playerIds.length / match.totalPlayers
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => MatchDetailScreen(matchId: match.id),
            ),
          );
        },
        child: Row(
          children: [
            Container(
              width: 4,
              height: 72,
              decoration: BoxDecoration(
                color: sportColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: sportColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        match.sport.emoji,
                        style: const TextStyle(fontSize: 28),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            match.venue.name,
                            style: theme.textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$dateTime  ·  $playerCount in',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fillRatio,
                              minHeight: 4,
                              backgroundColor:
                                  theme.colorScheme.surfaceContainerHighest,
                              color: sportColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: missing > 0
                            ? sportColor.withValues(alpha: 0.12)
                            : theme.colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        missing > 0 ? '$missing open' : 'Full',
                        style: TextStyle(
                          color: missing > 0
                              ? sportColor
                              : theme.colorScheme.error,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏟️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No matches yet',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Join or create a match to get started.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
