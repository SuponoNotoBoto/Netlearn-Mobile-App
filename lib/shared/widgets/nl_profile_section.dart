import 'package:flutter/material.dart';

import '../../core/avatar/nl_avatar_models.dart';
import '../../core/avatar/nl_avatar_widget.dart';
import '../../core/theme/app_theme.dart';
import '../../l10n/app_localizations.dart';

/// Profile building blocks shared by the student and lecturer profile pages.
///
/// Both roles show the same information architecture — identity header,
/// Academic Information, Profile, Settings — so the pieces live here instead
/// of being copied per feature. Only the data source differs: the student page
/// reads a raw map from `profiles`, the lecturer page reads `LecturerProfile`.

/// Identity card at the top of the page — `.unified-profile-hero`.
///
/// Gradien ungu `115deg`, avatar bulat 58px, lalu nama, identitas, dan keterangan
/// akademik. [initial] diteruskan, bukan diturunkan di sini, supaya tiap role
/// tetap memakai sumber huruf avatar-nya sendiri (model profil lecturer memiliki
/// `initial` yang juga dipakai header dashboard).
class NlProfileHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final String initial;
  final String? userId;

  /// Label peran di dalam pil transparan (`.unified-role`), mis. "Mahasiswa".
  /// Kosongkan bila halaman memang tidak punya label peran.
  final String? roleLabel;

  /// Teks label akademik di bawah identity chip (`.unified-academic-tag`).
  /// Dipakai kedua peran: student dan lecturer kini sama-sama menampilkan nama
  /// program studi ("Information Technology Education") di sini.
  final String? academicTag;

  /// Konfigurasi avatar kartun lucu pengguna (opsional).
  final AvatarConfig? avatarConfig;

  /// Bio / status singkat profil sosial (opsional).
  final String? bio;

  /// Callback untuk membuka Studio Kustomisasi Avatar.
  final VoidCallback? onEditAvatar;

  /// Key opsional untuk menyorot tombol Kustomisasi Avatar saat walkthrough.
  final Key? customizeAvatarKey;

  const NlProfileHeader({
    super.key,
    required this.name,
    required this.subtitle,
    required this.initial,
    this.userId,
    this.roleLabel,
    this.academicTag,
    this.avatarConfig,
    this.bio,
    this.onEditAvatar,
    this.customizeAvatarKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final effectiveSeed = (userId != null && userId!.isNotEmpty)
        ? userId!
        : name;
    final effectiveAvatar = avatarConfig ?? AvatarConfig.defaultFor(effectiveSeed);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: NetLearnGradients.hero,
        borderRadius: BorderRadius.circular(NetLearnRadius.cardLg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar kartun konsisten 62px + badge edit saat onEditAvatar aktif
              NlAvatarWidget(
                key: const Key('profile_header_cartoon_avatar'),
                config: effectiveAvatar,
                size: 62,
                borderWidth: 3,
                borderColor: NetLearnColors.white,
                onTap: onEditAvatar,
                badgeOverlay: onEditAvatar != null
                    ? Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFCA28),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        child: const Icon(
                          Icons.auto_fix_high_rounded,
                          size: 13,
                          color: Color(0xFF2B253A),
                        ),
                      )
                    : null,
              ),

              const SizedBox(width: 12),

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
                        color: NetLearnColors.white.withValues(alpha: 0.09),
                        borderRadius: BorderRadius.circular(
                          NetLearnRadius.pill,
                        ),
                        border: Border.all(
                          color: NetLearnColors.white.withValues(alpha: 0.16),
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
            style: theme.textTheme.headlineSmall?.copyWith(
              color: NetLearnColors.white,
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
              // `.unified-identity` — chip berkilau dengan identitas akademik.
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: NetLearnColors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: NetLearnColors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: NetLearnColors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (onEditAvatar != null)
                InkWell(
                  key: customizeAvatarKey ??
                      const Key('profile_customize_avatar_btn'),
                  onTap: onEditAvatar,
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFCA28).withValues(alpha: 0.22),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: const Color(0xFFFFCA28).withValues(alpha: 0.65),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.face_retouching_natural_rounded,
                          size: 14,
                          color: Color(0xFFFFE082),
                        ),
                        const SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            isId ? 'Kustomisasi Avatar' : 'Customize Avatar',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // `.unified-academic-tag` — label akademik di bawah identity chip.
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

/// A titled card that stacks [children] as full-width rows.
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
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            letterSpacing: 1.2,
          ),
        ),

        const SizedBox(height: NetLearnSpace.s8),

        Container(
          decoration: BoxDecoration(
            color: context.surface,
            borderRadius: BorderRadius.circular(NetLearnRadius.card),
            border: Border.all(color: context.border),
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

  /// Rendered instead of [value] when set, for rows whose value is not plain
  /// text (the account status badge). [value] is still required so the row keeps
  /// a non-visual fallback and callers cannot forget what the row means.
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
          Icon(icon, size: 21, color: context.accent),

          const SizedBox(width: NetLearnSpace.s12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                if (valueWidget != null)
                  valueWidget!
                else
                  Text(value, style: _valueStyle(context)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Below this width the language dropdown cannot share a line with its label, so
/// [NlLanguageRow] stacks it instead of overflowing. Derived from the measured
/// intrinsic widths: 282px for the dropdown plus ~120px for the icon and a
/// readable label.
const double _inlineBreakpoint = 420;

/// Language dropdown row for the Settings section.
class NlLanguageRow extends StatelessWidget {
  final Locale locale;
  final ValueChanged<String> onChanged;

  const NlLanguageRow({
    super.key,
    required this.locale,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final isIndonesian = locale.languageCode == 'id';

    final label = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.language,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 3),

        Text(
          isIndonesian ? l10n.indonesian : l10n.english,
          style: _valueStyle(context),
        ),
      ],
    );

    // A DropdownButton is a non-flex child, so it takes its full intrinsic width
    // and pushes the row over instead of shrinking. Measured in a 290dp row:
    // 282px for "Bahasa Indonesia", and the label plus icon need ~120px more,
    // so the two can never share a line on a 360dp screen.
    //
    // Two mitigations, in order of how visible they are:
    //  * below _inlineBreakpoint the dropdown drops to its own full-width line,
    //    which is a reflow rather than a clipped control;
    //  * its text is pinned against the platform scale, the same trick the
    //    raised AR label uses in the bottom bars, because "Bahasa Indonesia" at
    //    1.3x is another ~120px wider and a dropdown that ellipsizes is useless
    //    when the two choices are "English" and "Indonesian".
    final dropdown = MediaQuery.withNoTextScaling(
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: locale.languageCode,
          borderRadius: BorderRadius.circular(NetLearnRadius.card),
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            color: context.accent,
          ),
          items: [
            DropdownMenuItem<String>(
              value: 'en',
              child: Text(l10n.english),
            ),
            DropdownMenuItem<String>(
              value: 'id',
              child: Text(l10n.indonesian),
            ),
          ],
          onChanged: (value) {
            if (value == null) {
              return;
            }

            onChanged(value);
          },
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.all(15),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < _inlineBreakpoint) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.language_rounded,
                      size: 21,
                      color: context.accent,
                    ),

                    const SizedBox(width: NetLearnSpace.s12),

                    Expanded(child: label),
                  ],
                ),

                const SizedBox(height: NetLearnSpace.s8),

                dropdown,
              ],
            );
          }

          return Row(
            children: [
              Icon(
                Icons.language_rounded,
                size: 21,
                color: context.accent,
              ),

              const SizedBox(width: NetLearnSpace.s12),

              Expanded(child: label),

              const SizedBox(width: NetLearnSpace.s8),

              dropdown,
            ],
          );
        },
      ),
    );
  }
}

/// Dark mode switch row for the Settings section.
class NlDarkModeRow extends StatelessWidget {
  final bool isDark;
  final ValueChanged<bool> onChanged;

  const NlDarkModeRow({
    super.key,
    required this.isDark,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Icon(
            Icons.dark_mode_outlined,
            size: 21,
            color: context.accent,
          ),

          const SizedBox(width: NetLearnSpace.s12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.darkMode,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 3),

                Text(isDark ? l10n.on : l10n.off, style: _valueStyle(context)),
              ],
            ),
          ),

          const SizedBox(width: NetLearnSpace.s8),

          // `.theme-switch` —ON = ungu brand.
          Switch(
            value: isDark,
            activeThumbColor: context.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

TextStyle? _valueStyle(BuildContext context) {
  return Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12);
}

/// Variant tipe baris menu profil terpadu.
enum NlProfileMenuRowType {
  /// Navigasi ke sub-halaman (Profil, Akademik, Keamanan).
  navigation,
  /// Sakelar tema (Tema Terang/Gelap).
  themeSwitch,
  /// Pilihan bahasa (EN/ID pills).
  language,
}

/// Kartu menu profil terpadu (`Settings & activity`) yang membungkus beberapa
/// [NlProfileMenuRow] dengan pemisah di antaranya.
///
/// Student dan lecturer memakai kartu yang sama persis — urutan baris itulah
/// yang menentukan alurnya, dan kedua peran menuntut urutan yang identik:
/// Profile Information → Academic Information → Assessment History → Security &
/// Password → Theme → Language. Payload tiap baris tetap milik halaman masing-
/// masing (tujuan sub-halaman dan data berbeda), hanya wadah visualnya yang
/// dibagi supaya halaman tidak saling meniru dekorasi kartu dan tabrakan.
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
        color: context.surface,
        borderRadius: BorderRadius.circular(NetLearnRadius.card),
        border: Border.all(color: context.border),
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) _menuDivider(context),
            rows[i],
          ],
        ],
      ),
    );
  }

  static Widget _menuDivider(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NetLearnSpace.s13),
      child: Divider(
        height: 1,
        thickness: 1,
        color: context.border,
      ),
    );
  }
}

/// Baris menu terpadu untuk halaman profil (`.unified-menu-row`).
///
/// Mendukung tiga varian visual sesuai desain Figma:
/// 1. Navigation: ikon + judul + subtitle + chevron → push ke sub-halaman.
/// 2. ThemeSwitch: ikon + judul + subtitle + custom switch → toggle tema.
/// 3. Language: ikon + judul + subtitle + EN/ID pills → ganti bahasa.
class NlProfileMenuRow extends StatelessWidget {
  final NlProfileMenuRowType type;
  final int tintIndex; // Indeks ke NetLearnAccents.tintBackgrounds/Foregrounds
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap; // Untuk navigation
  final bool? switchValue; // Untuk themeSwitch
  final ValueChanged<bool>? onSwitchChanged; // Untuk themeSwitch
  final Locale? locale; // Untuk language
  final ValueChanged<String>? onLanguageChanged; // Untuk language

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
  }) : assert(
         type != NlProfileMenuRowType.navigation || onTap != null,
         'Navigation row requires onTap',
       ),
       assert(
         type != NlProfileMenuRowType.themeSwitch ||
             (switchValue != null && onSwitchChanged != null),
         'ThemeSwitch row requires switchValue and onSwitchChanged',
       ),
       assert(
         type != NlProfileMenuRowType.language ||
             (locale != null && onLanguageChanged != null),
         'Language row requires locale and onLanguageChanged',
       );

  @override
  Widget build(BuildContext context) {
    final bgColor = NetLearnAccents.tintBackgrounds[tintIndex];
    final fgColor = NetLearnAccents.tintForegrounds[tintIndex];

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

// Judul + subtitle — constrained to prevent overflow at 360dp + 1.3x.
              // Available width in menu card: 360 - 40 (page) - 26 (row padding)
              // - 36 (icon) - 12 (gap) - 8 (gap) - 86 (language trailing) = ~112dp.
              // Use 110 to leave margin for text scaling.
              Expanded(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        softWrap: false,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: context.mutedText,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
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
        return Icon(
          Icons.chevron_right_rounded,
          size: 20,
          color: context.mutedText,
        );

      case NlProfileMenuRowType.themeSwitch:
        return _ThemeSwitchTrack(
          value: switchValue!,
          onChanged: onSwitchChanged!,
        );

      case NlProfileMenuRowType.language:
        return _LanguagePills(
          locale: locale!,
          onChanged: onLanguageChanged!,
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
          color: selected ? NetLearnColors.primary : context.raisedSurface,
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
            color: selected
                ? NetLearnColors.white
                : context.mutedText,
          ),
        ),
      ),
    );
  }
}
