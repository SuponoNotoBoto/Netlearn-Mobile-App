import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NlStatsStripItem {
  final String value;
  final String label;

  const NlStatsStripItem({
    required this.value,
    required this.label,
  });
}

class NlStatsStrip extends StatelessWidget {
  final List<NlStatsStripItem> items;

  const NlStatsStrip({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: NetLearnColors.border),
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
      ),
      padding: const EdgeInsets.symmetric(
        vertical: NetLearnSpace.s19,
        horizontal: 5,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < items.length; i++)
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  border: i != items.length - 1
                      ? Border(right: BorderSide(color: NetLearnColors.border))
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      items[i].value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: NetLearnColors.primary,
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.8,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: NetLearnSpace.s6),
                    Text(
                      items[i].label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF6C727F),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
