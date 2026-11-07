import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class NlNotificationBell extends StatelessWidget {
  final VoidCallback onTap;
  final bool hasUnread;

  const NlNotificationBell({
    super.key,
    required this.onTap,
    this.hasUnread = true,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: NetLearnColors.border),
            boxShadow: NetLearnShadows.softSm,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.notifications_outlined,
                size: 20,
                color: NetLearnColors.neutral700,
              ),
              if (hasUnread)
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF7979),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

