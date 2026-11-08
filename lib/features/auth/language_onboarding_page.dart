import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/localization/language_controller.dart';
import '../../l10n/app_localizations.dart';

/// Signature of the confirm callback fired by
/// [LanguageOnboardingForm] when the continue button is pressed.
typedef LanguageOnboardingConfirmed = void Function(String languageCode);

/// Language selection form (Figma `Onboarding Sreen` 45:571, the form part of
/// the Make `onboarding-language-content` step).
///
/// The three-screen onboarding flow (`OnboardingFlowPage`) embeds this form as
/// its first step; on confirm the flow applies the language and persists the
/// selection. The form itself owns no navigation and no state persistence, so
/// language logic lives in exactly one place, but its visuals/sizes are the
/// same as the original route's language cards.
class LanguageOnboardingForm extends ConsumerStatefulWidget {
  const LanguageOnboardingForm({super.key, this.onConfirmed});

  /// Called with the chosen language code ('en' | 'id') when the continue
  /// button is pressed. The flow applies and persists it.
  final LanguageOnboardingConfirmed? onConfirmed;

  @override
  ConsumerState<LanguageOnboardingForm> createState() =>
      _LanguageOnboardingFormState();
}

class _LanguageOnboardingFormState
    extends ConsumerState<LanguageOnboardingForm> {
  String _selectedLanguage = 'en';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    // Preselect the active language so re-entering this step from the flow's
    // language action shows the live preference instead of a stale default.
    final current = ref.read(languageProvider).languageCode;
    _selectedLanguage = current == 'id' ? 'id' : 'en';
  }

  Future<void> _continue() async {
    if (_submitting) {
      return;
    }
    // setLanguage is idempotent, but a double tap would otherwise run the
    // confirm callback twice in quick succession.
    _submitting = true;
    widget.onConfirmed?.call(_selectedLanguage);
    _submitting = false;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Translation icon
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFFF0EEFC),
            borderRadius: BorderRadius.circular(18),
          ),
          alignment: Alignment.center,
          child: Icon(
            Icons.translate_rounded,
            size: 22,
            color: const Color(0xFF543CD1),
          ),
        ),
        const SizedBox(height: 18),

        // Heading
        Text(
          l10n.chooseYourLanguage,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontFamily: 'PlusJakartaSans',
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.45,
            color: const Color(0xFF1A1D26),
          ),
        ),
        const SizedBox(height: 6),

        // Description
        Text(
          l10n.onboardingDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            fontFamily: 'DMSans',
            fontSize: 12,
            color: const Color(0xFF6C727F),
            height: 1.75,
          ),
        ),
        const SizedBox(height: 22),

        // ── Language cards ────────────────────────────────
        _LanguageCard(
          code: 'ID',
          title: l10n.languageIndonesian,
          subtitle: l10n.indonesian,
          isSelected: _selectedLanguage == 'id',
          onTap: () {
            setState(() => _selectedLanguage = 'id');
          },
        ),
        const SizedBox(height: 12),
        _LanguageCard(
          code: 'EN',
          title: l10n.languageEnglish,
          subtitle: l10n.english,
          isSelected: _selectedLanguage == 'en',
          onTap: () {
            setState(() => _selectedLanguage = 'en');
          },
        ),
        const SizedBox(height: 22),

        // ── Continue button ───────────────────────────────
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: _continue,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF543CD1),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.continueButton),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, size: 17),
              ],
            ),
          ),
        ),
        const SizedBox(height: 18),

        // Footer note
        Center(
          child: Text(
            l10n.prototypeMode,
            style: theme.textTheme.bodySmall?.copyWith(
              fontFamily: 'DMSans',
              fontSize: 9,
              color: const Color(0xFF6C727F),
            ),
          ),
        ),
      ],
    );
  }
}

/// A single language option card.
///
/// Selected state: purple-tinted background, purple border, filled badge,
/// checkmark on the right. Unselected: white background, grey border.
class _LanguageCard extends StatelessWidget {
  final String code;
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.code,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFEFEBFC) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? const Color(0xFF7358D8)
                  : const Color(0xFFE3E4ED),
            ),
          ),
          child: Row(
            children: [
              // Language code badge
              Container(
                width: 29,
                height: 29,
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF543CD1) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF543CD1)
                        : const Color(0xFFE6E6EF),
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  code,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                    color: isSelected ? Colors.white : const Color(0xFF1A1D26),
                  ),
                ),
              ),
              const SizedBox(width: 13),

              // Title + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        letterSpacing: -0.25,
                        color: isSelected
                            ? const Color(0xFF543CD1)
                            : const Color(0xFF1A1D26),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        color: const Color(0xFF6C727F),
                      ),
                    ),
                  ],
                ),
              ),

              // Checkmark (selected only)
              if (isSelected)
                Icon(
                  Icons.check_rounded,
                  size: 19,
                  color: const Color(0xFF543CD1),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
