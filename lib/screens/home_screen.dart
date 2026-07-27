import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/match.dart';
import '../models/sport.dart';
import '../repositories/match_repository.dart';
import '../theme/app_colors.dart';
import 'create_match_screen.dart';
import 'match_detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Sport? _selectedSport;

  @override
  Widget build(BuildContext context) {
    final repo = MatchRepository();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Open matches'),
      ),
      body: Column(
        children: [
          _SportFilterBar(
            selected: _selectedSport,
            onSelected: (sport) {
              HapticFeedback.lightImpact();
              setState(() => _selectedSport = sport);
            },
          ),
          Expanded(
            child: StreamBuilder<List<Match>>(
              stream: repo.watchOpen(sport: _selectedSport),
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: matches.length,
                    itemBuilder: (context, i) =>
                        _MatchCard(match: matches[i]),
                  ),
                );
              },
            ),
          ),
        ],
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

class _SportFilterBar extends StatelessWidget {
  const _SportFilterBar({required this.selected, required this.onSelected});

  final Sport? selected;
  final ValueChanged<Sport?> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: const Text('All'),
              selected: selected == null,
              onSelected: (_) => onSelected(null),
            ),
          ),
          for (final sport in Sport.values)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                avatar: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: AppColors.sportColor(sport.id),
                    shape: BoxShape.circle,
                  ),
                ),
                label: Text('${sport.emoji} ${sport.label}'),
                selected: selected == sport,
                onSelected: (_) => onSelected(sport),
              ),
            ),
        ],
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
          HapticFeedback.lightImpact();
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
              margin: const EdgeInsets.only(left: 0),
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
                              backgroundColor: theme.colorScheme.surfaceContainerHighest,
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
            const Text('⚽', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No open matches nearby',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Be the first — create a match and fill your spots.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateMatchScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Create a match'),
            ),
          ],
        ),
      ),
    );
  }
}
