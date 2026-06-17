import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class EpisodeServer extends StatelessWidget {
  final String episodeNo;
  final List<Map<String, String>> subServers;
  final List<Map<String, String>> dubServers;
  final List<Map<String, String>> rawServers;
  final Map<String, String>? activeSub;
  final Map<String, String>? activeDub;
  final Map<String, String>? activeRaw;
  final void Function(String audioType, Map<String, String> server) onServerSelected;
  final String nextEpisodeTime;

  const EpisodeServer({
    super.key,
    required this.episodeNo,
    this.subServers = const [],
    this.dubServers = const [],
    this.rawServers = const [],
    this.activeSub,
    this.activeDub,
    this.activeRaw,
    required this.onServerSelected,
    this.nextEpisodeTime = '',
  });

  @override
  Widget build(BuildContext context) {
    final bool isWide = MediaQuery.of(context).size.width > 900;
    final theme = Theme.of(context);

    final infoBox = Container(
      width: isWide ? 256 : double.infinity, // 256px matches w-64 in React exactly
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'You are watching',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.textTheme.bodyLarge?.color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Episode $episodeNo',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryBlue,
            ),
          ),
        ],
      ),
    );

    final serverControls = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // SUB servers row
        if (subServers.isNotEmpty) ...[
          _buildServerRow(
            context: context,
            label: 'SUB',
            icon: LucideIcons.subtitles,
            badgeBg: const Color(0xFF10B981).withValues(alpha: 0.1),
            badgeColor: theme.brightness == Brightness.dark ? const Color(0xFF34D399) : const Color(0xFF059669),
            servers: subServers,
            activeServer: activeSub,
            onServerSelected: (s) => onServerSelected('sub', s),
          ),
          if (dubServers.isNotEmpty || rawServers.isNotEmpty) const SizedBox(height: 16),
        ],

        // DUB servers row
        if (dubServers.isNotEmpty) ...[
          _buildServerRow(
            context: context,
            label: 'DUB',
            icon: LucideIcons.mic,
            badgeBg: AppTheme.primaryBlue.withValues(alpha: 0.1),
            badgeColor: theme.brightness == Brightness.dark ? const Color(0xFF60A5FA) : AppTheme.primaryBlue,
            servers: dubServers,
            activeServer: activeDub,
            onServerSelected: (s) => onServerSelected('dub', s),
          ),
          if (rawServers.isNotEmpty) const SizedBox(height: 16),
        ],

        // RAW servers row
        if (rawServers.isNotEmpty) ...[
          _buildServerRow(
            context: context,
            label: 'RAW',
            icon: LucideIcons.mic,
            badgeBg: theme.colorScheme.secondary.withValues(alpha: 0.2),
            badgeColor: theme.brightness == Brightness.dark ? theme.hintColor : Colors.grey[700]!,
            servers: rawServers,
            activeServer: activeRaw,
            onServerSelected: (s) => onServerSelected('raw', s),
          ),
        ],
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Layout main server picker rows
        if (isWide)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              infoBox,
              const SizedBox(width: 16),
              Expanded(child: serverControls),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              infoBox,
              const SizedBox(height: 16),
              serverControls,
            ],
          ),

        // Countdown schedule badge
        if (nextEpisodeTime.isNotEmpty && nextEpisodeTime != '0') ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.secondary.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.clock, size: 14, color: theme.hintColor),
                const SizedBox(width: 6),
                Text(
                  'Estimated next episode at $nextEpisodeTime',
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.textTheme.bodyLarge?.color?.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildServerRow({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color badgeBg,
    required Color badgeColor,
    required List<Map<String, String>> servers,
    required Map<String, String>? activeServer,
    required ValueChanged<Map<String, String>> onServerSelected,
  }) {
    final theme = Theme.of(context);

    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 12,
      runSpacing: 8,
      children: [
        // SUB/DUB/RAW label badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: badgeBg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: badgeColor.withValues(alpha: 0.2)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 13, color: badgeColor),
              const SizedBox(width: 4),
              Text(
                '$label:',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: badgeColor),
              ),
            ],
          ),
        ),

        // Servers solid buttons (React parity)
        ...servers.map((s) {
          final isSelected = activeServer?['serverId'] == s['serverId'];

          return Container(
            height: 32,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withValues(alpha: 0.25),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      )
                    ]
                  : null,
            ),
            child: ElevatedButton(
              onPressed: () => onServerSelected(s),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                backgroundColor: isSelected ? theme.colorScheme.primary : theme.colorScheme.secondary,
                foregroundColor: isSelected ? theme.colorScheme.onPrimary : theme.textTheme.bodyLarge?.color,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: Text(
                s['serverName']?.toUpperCase() ?? '',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
