import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Identity card at the top of the profile page — `.unified-profile-hero`.
class NlProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String initial;
  final String? roleLabel;
  final String? academicTag;
  final String? bio;

  const NlProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.initial,
    this.roleLabel,
    this.academicTag,
    this.bio,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(NetLearnSpace.s22),
      decoration: BoxDecoration(
        gradient: NetLearnGradients.hero,
        borderRadius: BorderRadius.circular(NetLearnRadius.cardLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar bulat 62px di hero
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: NetLearnColors.heroAvatarBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: NetLearnColors.heroAvatarFg,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: NetLearnSpace.s12),

              // `.unified-role` — pil transparan di atas gradien, rata kanan.
              if (roleLabel != null)
                Expanded(
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(NetLearnRadius.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Text(
                        roleLabel!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFEEEAFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 17),

          Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),

          if (bio != null && bio!.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              '"${bio!.trim()}"',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFE082),
                fontSize: 11.5,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],

          const SizedBox(height: 12),

          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              // `.unified-identity` — chip dengan identitas akademik.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),

          if (academicTag != null) ...[
            const SizedBox(height: 13),
            Text(
              academicTag!,
              style: const TextStyle(
                color: Color(0xFFE1DAFA),
                fontSize: 11,
                height: 1.6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A titled card that stacks children as full-width rows.
class NlProfileSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const NlProfileSection({
    super.key,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: NetLearnColors.neutral500,
          ),
        ),
        const SizedBox(height: NetLearnSpace.s8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: NetLearnColors.border),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

/// Icon + label + value row used inside [NlProfileSection].
class NlProfileRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Widget? valueWidget;

  const NlProfileRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 21, color: NetLearnColors.primary),
          const SizedBox(width: NetLearnSpace.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: NetLearnColors.neutral500,
                  ),
                ),
                const SizedBox(height: 3),
                if (valueWidget != null)
                  valueWidget!
                else
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: NetLearnColors.neutral900,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum NlProfileMenuRowType {
  navigation,
  themeSwitch,
  language,
}

/// Kartu menu profil terpadu (`Settings & activity`) yang membungkus beberapa
/// [NlProfileMenuRow] dengan pemisah di antaranya.
class NlProfileMenuCard extends StatelessWidget {
  final List<NlProfileMenuRow> rows;

  const NlProfileMenuCard({
    super.key,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: NetLearnColors.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: NetLearnSpace.s13),
                child: Divider(
                  height: 1,
                  thickness: 1,
                  color: NetLearnColors.border,
                ),
              ),
            rows[i],
          ],
        ],
      ),
    );
  }
}

/// Baris menu terpadu untuk halaman profil (`.unified-menu-row`).
class NlProfileMenuRow extends StatelessWidget {
  final NlProfileMenuRowType type;
  final int tintIndex;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final Locale? locale;
  final ValueChanged<String>? onLanguageChanged;

  const NlProfileMenuRow({
    super.key,
    required this.type,
    required this.tintIndex,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.switchValue,
    this.onSwitchChanged,
    this.locale,
    this.onLanguageChanged,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = NetLearnAccents.tintBackgrounds[tintIndex % NetLearnAccents.tintBackgrounds.length];
    final fgColor = NetLearnAccents.tintForegrounds[tintIndex % NetLearnAccents.tintForegrounds.length];

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: type == NlProfileMenuRowType.navigation ? onTap : null,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: NetLearnSpace.s13,
            vertical: NetLearnSpace.s17,
          ),
          child: Row(
            children: [
              // Ikon dengan latar tint
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(NetLearnRadius.sm),
                ),
                child: Icon(icon, size: 19, color: fgColor),
              ),

              const SizedBox(width: NetLearnSpace.s12),

              // Judul + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: NetLearnColors.neutral900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      softWrap: false,
                      style: const TextStyle(
                        fontSize: 11,
                        color: NetLearnColors.neutral500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: NetLearnSpace.s8),

              // Trailing: chevron / switch / language pills
              _buildTrailing(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrailing(BuildContext context) {
    switch (type) {
      case NlProfileMenuRowType.navigation:
        return const Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: NetLearnColors.neutral400,
        );

      case NlProfileMenuRowType.themeSwitch:
        return _ThemeSwitchTrack(
          value: switchValue ?? false,
          onChanged: onSwitchChanged ?? (_) {},
        );

      case NlProfileMenuRowType.language:
        return _LanguagePills(
          locale: locale ?? const Locale('id'),
          onChanged: onLanguageChanged ?? (_) {},
        );
    }
  }
}

/// Custom theme switch track (`.theme-switch` 40x24px).
class _ThemeSwitchTrack extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ThemeSwitchTrack({
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 40,
        height: 24,
        decoration: BoxDecoration(
          color: value ? NetLearnColors.primary : NetLearnColors.themeSwitchOff,
          borderRadius: BorderRadius.circular(20),
        ),
        padding: const EdgeInsets.all(3),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18,
            height: 18,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Language pills (EN/ID) untuk baris bahasa.
class _LanguagePills extends StatelessWidget {
  final Locale locale;
  final ValueChanged<String> onChanged;

  const _LanguagePills({
    required this.locale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isEn = locale.languageCode == 'en';

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _LangPill(
          label: 'EN',
          selected: isEn,
          onTap: () => onChanged('en'),
        ),
        const SizedBox(width: 4),
        _LangPill(
          label: 'ID',
          selected: !isEn,
          onTap: () => onChanged('id'),
        ),
      ],
    );
  }
}

class _LangPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LangPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? NetLearnColors.primary : NetLearnColors.purple50,
          borderRadius: BorderRadius.circular(NetLearnRadius.pill),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: NetLearnColors.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : NetLearnColors.neutral500,
          ),
        ),
      ),
    );
  }
}
