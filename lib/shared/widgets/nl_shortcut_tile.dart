import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NlShortcutTile extends StatelessWidget {
  final IconData icon;
  final Color accentColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  const NlShortcutTile({
    super.key,
    required this.icon,
    required this.accentColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(NetLearnRadius.card),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        child: Container(
          constraints: const BoxConstraints(minHeight: 115),
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: NetLearnColors.border),
            boxShadow: NetLearnShadows.softSm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: NetLearnColors.neutral900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 10,
                  color: NetLearnColors.neutral500,
                ),
              ),
              const Spacer(),
              Align(
                alignment: Alignment.bottomRight,
                child: Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 10,
                  color: NetLearnColors.neutral400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

