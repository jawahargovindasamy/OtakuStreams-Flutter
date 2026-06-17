import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme.dart';

class SectionHeader extends StatefulWidget {
  final String title;
  final bool showTime;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;

  const SectionHeader({
    super.key,
    required this.title,
    this.showTime = false,
    this.onTap,
    this.padding = const EdgeInsets.fromLTRB(16, 24, 16, 12),
  });

  @override
  State<SectionHeader> createState() => _SectionHeaderState();
}

class _SectionHeaderState extends State<SectionHeader> {
  Timer? _clockTimer;
  String _formattedLocalTime = '';

  @override
  void initState() {
    super.initState();
    if (widget.showTime) {
      _updateClock();
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        _updateClock();
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _updateClock() {
    if (!mounted) return;
    final now = DateTime.now();
    final offset = now.timeZoneOffset;
    final hours = offset.inHours.abs().toString().padLeft(2, '0');
    final minutes = (offset.inMinutes.abs() % 60).toString().padLeft(2, '0');
    final sign = offset.isNegative ? '-' : '+';
    final gmtStr = 'GMT$sign$hours:$minutes';

    final hour24 = now.hour;
    final period = hour24 >= 12 ? 'PM' : 'AM';
    final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
    final minStr = now.minute.toString().padLeft(2, '0');
    final secStr = now.second.toString().padLeft(2, '0');
    final timeStr = '$hour12:$minStr:$secStr $period';

    setState(() {
      _formattedLocalTime = '($gmtStr) $timeStr';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: widget.padding,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side title with accent bar
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Row(
                  children: [
                    Container(
                      width: 4,
                      height: 20,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        widget.title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.showTime && _formattedLocalTime.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          _formattedLocalTime,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                );
              }
            ),
          ),
          // View all link
          if (widget.onTap != null)
            TextButton(
              onPressed: widget.onTap,
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('View All', style: TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600)),
                  SizedBox(width: 2),
                  Icon(LucideIcons.chevronRight, size: 14, color: AppTheme.primaryBlue),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
