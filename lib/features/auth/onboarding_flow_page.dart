import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/localization/language_controller.dart';
import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_netlearn_logo.dart';
import '../../shared/widgets/nl_snack_bar.dart';
import 'language_onboarding_page.dart';
import 'onboarding_scenes.dart';
import 'onboarding_status.dart';

/// SharedPreferences flag that the language step of this flow was confirmed.
/// Kept apart from the account-scoped completion status
/// ([onboardingCompleteMetadataKey], see `onboarding_status.dart`): a user who
/// confirmed the language but closed the app before finishing the journey
/// resumes on the journey instead of seeing the language step again — the same
/// behaviour the Figma Make flow gets from its persisted language selection.
const String _languageSelectedKey = 'netlearn_onboarding_language_selected';

/// Three-screen onboarding flow (Make `OnboardingFlow.tsx` + `onboarding.css`).
///
/// Stage 1 embeds [LanguageOnboardingForm]; stages 2–4 are the journey pages
/// (welcome, modules, practice). Finish (or Skip) persists
/// [onboardingCompleteKey] and returns to `/`, where the existing guard owns
/// the role-based redirect — exactly like the previous language page did, so
/// authentication routing is untouched.
///
/// Palette/spacing mirrors `onboarding.css` tokens: primary #543CD1,
/// ink #29213F, muted #6C727F, border #ECEEF2, soft #F0EDFB (primary 9% on
/// white), background #F7F5FC on a light scaffold. The Make design's dark
/// variant is intentionally not implemented yet — the previous language
/// onboarding page was light-only as well; no dark behavior is regressed.
class OnboardingFlowPage extends ConsumerStatefulWidget {
  const OnboardingFlowPage({super.key});

  @override
  ConsumerState<OnboardingFlowPage> createState() => _OnboardingFlowPageState();
}

class _OnboardingFlowPageState extends ConsumerState<OnboardingFlowPage> {
  static const _ink = Color(0xFF29213F);
  static const _muted = Color(0xFF6C727F);
  static const _border = Color(0xFFECEEF2);
  static const _soft = Color(0xFFF0EDFB);
  static const _paper = Color(0xFFFFFFFF);
  static const _primary = Color(0xFF543CD1);

  bool _flagsLoaded = false;
  bool _selectingLanguage = true;
  int _page = 0;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _loadFlags();
  }

  Future<void> _loadFlags() async {
    final preferences = await SharedPreferences.getInstance();
    final languageSelected =
        preferences.getBool(_languageSelectedKey) ?? false;

    if (!mounted) {
      return;
    }
    setState(() {
      _flagsLoaded = true;
      _selectingLanguage = !languageSelected;
    });
  }

  Future<void> _confirmLanguage(String languageCode) async {
    // Single source of truth for language persistence: setLanguage applies
    // the locale (and mirrors it to profiles.language for signed-in users —
    // the previous language page wrote the same pair of values).
    await ref.read(languageProvider.notifier).setLanguage(languageCode);

    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_languageSelectedKey, true);

    if (!mounted) {
      return;
    }
    setState(() => _selectingLanguage = false);
  }

  void _changePage(int page) {
    setState(() => _page = page);
  }

  Future<void> _finish() async {
    if (_finished) {
      return;
    }
    // Guard against double-Go while the flag write awaits.
    _finished = true;

    // The router gate reads the account-scoped status, so completion is saved
    // on the signed-in account first. The same helper also writes the legacy
    // device-local flag its offline fallback reads, keeping the previous
    // local behaviour intact.
    final persisted = await markOnboardingCompleteForCurrentUser();

    if (!mounted) {
      return;
    }

    // Unsaved account status must not be reported as done: on a sign-in on
    // some other device (or a fresh install) the flow would legitimately
    // appear again because the account never recorded it. The user is still
    // let through — being asked once more on the next sign-in beats trapping
    // them here — but honestly labelled.
    if (!persisted) {
      final l10n = AppLocalizations.of(context)!;
      NlSnackBar.show(
        context,
        l10n.onboardingPersistFailed,
        tone: NlSnackTone.error,
      );
    }

    // The redirect (lib/core/router/app_router.dart) owns role-based routing
    // now that onboarding is complete: go to the root and let the guard pick
    // the lecturer/student area from the signed-in profile.
    context.go('/');
  }

  void _reopenLanguageStep() {
    setState(() => _selectingLanguage = true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final height = MediaQuery.sizeOf(context).height;
    // Matches the css height breaks: ≤760 → compact paddings/art, ≤620 →
    // tighter art and hidden compact scenes.
    final compact = height <= 760;
    final tight = height <= 620;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F5FC),
      body: SafeArea(
        // Hold the bare scaffold until the flags resolve so a resumed user
        // does not see a flash of the language step.
        child: !_flagsLoaded
            ? const SizedBox.expand()
            : _selectingLanguage
                ? _buildLanguageStage(l10n, theme, compact)
                : _buildJourneyStage(l10n, theme, compact, tight),
      ),
    );
  }

  Widget _buildLogoBar(
    AppLocalizations l10n,
    ThemeData theme, {
    required bool showLanguageAction,
    required bool compact,
  }) {
    // Watch (not read) so the chip reflects the language the user just
    // confirmed in the language step.
    final languageCode = ref.watch(languageProvider).languageCode;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: compact ? 8 : 16),
      child: Row(
        children: [
          const NlNetLearnLogo(size: 32),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              l10n.appName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w800,
                fontSize: 20,
                letterSpacing: -0.5,
                color: _ink,
              ),
            ),
          ),
          if (showLanguageAction)
            Semantics(
              container: true,
              button: true,
              label: l10n.chooseYourLanguage,
              child: TextButton(
                onPressed: _reopenLanguageStep,
                style: TextButton.styleFrom(
                  minimumSize: const Size(56, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  foregroundColor: _primary,
                  textStyle: theme.textTheme.labelMedium?.copyWith(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.translate_rounded, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      languageCode.toUpperCase(),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Language stage ────────────────────────────────────────────────────────

  Widget _buildLanguageStage(
    AppLocalizations l10n,
    ThemeData theme,
    bool compact,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLogoBar(l10n, theme,
            showLanguageAction: false, compact: compact),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: SizedBox(
                          // css: onboarding-language-art w-48 (≤760: w-32).
                          width: compact ? 128 : 192,
                          child: OnboardingSceneView(
                            variant: OnboardingSceneVariant.student,
                            semanticLabel: l10n.onboardingSceneStudentLabel,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LanguageOnboardingForm(
                        onConfirmed: _confirmLanguage,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ── Journey stages ────────────────────────────────────────────────────────

  Widget _buildJourneyStage(
    AppLocalizations l10n,
    ThemeData theme,
    bool compact,
    bool tight,
  ) {
    final page = _page;
    final titles = <String, String>{
      'title': switch (page) {
        0 => l10n.onboardingIntroTitle,
        1 => l10n.onboardingModulesTitle,
        _ => l10n.onboardingPracticeTitle,
      },
      'body': switch (page) {
        0 => l10n.onboardingIntroBody,
        1 => l10n.onboardingModulesBody,
        _ => l10n.onboardingPracticeBody,
      },
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildLogoBar(l10n, theme,
            showLanguageAction: true, compact: compact),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                l10n.onboardingJourneyLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                  color: _muted,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    (page + 1).toString().padLeft(2, '0'),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: _primary,
                    ),
                  ),
                  Text(
                    l10n.onboardingPageNumberSuffix,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: _primary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildArt(l10n, page, compact, tight),
                      _buildCopy(l10n, theme, titles, page, compact),
                      if (page == 1) _buildModuleCards(l10n, theme),
                      if (page == 2) _buildJourneyCards(l10n, theme),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        _buildFooter(l10n, theme, page, compact),
      ],
    );
  }

  Widget _buildArt(AppLocalizations l10n, int page, bool compact, bool tight) {
    // css: ≤620 the fixed-width scenes of pages 2–3 are hidden.
    if (page != 0 && tight) {
      return const SizedBox.shrink();
    }
    final label = switch (page) {
      0 => l10n.onboardingSceneStudentLabel,
      1 => l10n.onboardingSceneNetworkLabel,
      _ => l10n.onboardingSceneJourneyLabel,
    };
    final variant = switch (page) {
      0 => OnboardingSceneVariant.student,
      1 => OnboardingSceneVariant.network,
      _ => OnboardingSceneVariant.journey,
    };
    final scene = OnboardingSceneView(
      variant: variant,
      semanticLabel: label,
    );
    if (page == 0) {
      // css: w-full max-w-96 — fills the column up to 384px wide.
      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 384),
          child: scene,
        ),
      );
    }
    // css: pages 2–3 art fixed to w-44 (≤760: w-28).
    return Center(
      child: SizedBox(
        width: compact ? 112 : 176,
        child: scene,
      ),
    );
  }

  Widget _buildCopy(
    AppLocalizations l10n,
    ThemeData theme,
    Map<String, String> titles,
    int page,
    bool compact,
  ) {
    // css: h1 text-3xl (pages: text-2xl; ≤760: text-2xl) tracking-tight; p
    // mt-4 text-sm (pages ≤760: mt-2 text-xs).
    final headingSize = page == 0 && !compact ? 30.0 : 24.0;
    final bodySize = page == 0 && !compact ? 14.0 : 12.0;
    final bodyTop = page == 0 && !compact ? 16.0 : 8.0;

    return Padding(
      // The module/journey grids carry their own mt-5; keep the art block
      // breathing here through a bottom spacer instead.
      padding: const EdgeInsets.only(top: 8, bottom: 12),
      child: Column(
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              titles['title']!,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontFamily: 'PlusJakartaSans',
                fontWeight: FontWeight.w800,
                fontSize: headingSize,
                height: 1.25,
                letterSpacing: headingSize > 24 ? -0.75 : -0.6,
                color: _ink,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(top: bodyTop),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                titles['body']!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'DMSans',
                  fontSize: bodySize,
                  height: 1.625,
                  color: _muted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCards(AppLocalizations l10n, ThemeData theme) {
    final titles = [
      l10n.onboardingModuleFundamentals,
      l10n.onboardingModuleDevices,
      l10n.onboardingModuleTopologies,
      l10n.onboardingModuleIpAddress,
    ];
    final modules = [
      OnboardingModuleArt.fundamentals,
      OnboardingModuleArt.devices,
      OnboardingModuleArt.topology,
      OnboardingModuleArt.ipAddress,
    ];

    const gap = 12.0;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final pair in [[0, 1], [2, 3]])
            Padding(
              padding: const EdgeInsets.only(top: gap),
              // IntrinsicHeight gives the two cards equal row height even
              // though this Column offers no bounded height to stretch into.
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _moduleCard(
                      theme,
                      title: titles[pair[0]],
                      number: '${pair[0] + 1}'.padLeft(2, '0'),
                      art: modules[pair[0]],
                    ),
                    const SizedBox(width: gap),
                    _moduleCard(
                      theme,
                      title: titles[pair[1]],
                      number: '${pair[1] + 1}'.padLeft(2, '0'),
                      art: modules[pair[1]],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _moduleCard(
    ThemeData theme, {
    required String title,
    required String number,
    required OnboardingModuleArt art,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _paper,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: const [
            BoxShadow(
              color: Color(0x08543CD1),
              offset: Offset(0, 3),
              blurRadius: 10,
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 40,
                  width: 64,
                  child: OnboardingModuleIllustration(module: art),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    height: 1.375,
                    letterSpacing: -0.25,
                    color: _ink,
                  ),
                ),
              ],
            ),
            Positioned(
              right: 0,
              top: 0,
              child: Text(
                number,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  color: _muted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyCards(AppLocalizations l10n, ThemeData theme) {
    final steps = <(String, String, IconData)>[
      (
        l10n.journeyStudyTitle,
        l10n.journeyStudySubtitle,
        Icons.menu_book_outlined,
      ),
      (
        l10n.journeyVideosTitle,
        l10n.journeyVideosSubtitle,
        Icons.play_circle_outline,
      ),
      (
        l10n.journeyAssessmentsTitle,
        l10n.journeyAssessmentsSubtitle,
        Icons.fact_check_outlined,
      ),
      (
        l10n.journeyReviewTitle,
        l10n.journeyReviewSubtitle,
        Icons.check_circle_outline,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Stack(
        children: [
          // The ol::before connector line, inset 24 top and bottom.
          Positioned(
            left: 24,
            top: 24,
            bottom: 24,
            width: 1,
            child: ColoredBox(
              color: _primary.withValues(alpha: 0.2),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, step) in steps.indexed)
                // css gap-2: the first row owns no top gap.
                Padding(
                  padding: EdgeInsets.only(top: index == 0 ? 0 : 8),
                  child: _journeyRow(
                    theme,
                    title: step.$1,
                    subtitle: step.$2,
                    icon: step.$3,
                    isReview: index == 3,
                    number: '${index + 1}'.padLeft(2, '0'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _journeyRow(
    ThemeData theme, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isReview,
    required String number,
  }) {
    Widget tile = Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: Icon(
        icon,
        size: 20,
        color: _primary,
      ),
    );
    if (isReview) {
      // The review tile adds the small progress bar under its icon
      // (.onboarding-review-icon::after): primary 70%, then 30% at 20%.
      tile = Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: _primary,
            ),
            const SizedBox(height: 3),
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  colors: [
                    _primary.withValues(alpha: 0.7),
                    _primary.withValues(alpha: 0.7),
                    _primary.withValues(alpha: 0.2),
                  ],
                  stops: const [0.0, 0.7, 0.7],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: _paper,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          tile,
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    color: _muted,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              number,
              style: theme.textTheme.bodySmall?.copyWith(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 12,
                color: _primary.withValues(alpha: 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(
    AppLocalizations l10n,
    ThemeData theme,
    int page,
    bool compact,
  ) {
    return Padding(
      padding:
          EdgeInsets.fromLTRB(24, compact ? 8 : 20, 24, compact ? 8 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: compact ? 8 : 16),
            child: SizedBox(
              height: 36,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Semantics(
                    container: true,
                    label: l10n.onboardingProgressLabel,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var index = 0; index < 3; index++)
                          Padding(
                            padding: EdgeInsets.only(
                              left: index == 0 ? 0 : 6,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: page == index ? 24 : 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: page == index
                                    ? _primary
                                    : _primary.withValues(alpha: 0.35),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (page < 2)
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        minimumSize: const Size(64, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        foregroundColor: _muted,
                        textStyle: theme.textTheme.labelMedium?.copyWith(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      child: Text(l10n.onboardingSkip),
                    ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              if (page > 0)
                Semantics(
                  container: true,
                  button: true,
                  label: l10n.back,
                  child: Container(
                    width: 56,
                    height: 48,
                    margin: const EdgeInsets.only(right: 12),
                    child: TextButton(
                      onPressed: () => _changePage(page - 1),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        backgroundColor: const Color(0xFFF0ECFB),
                        foregroundColor: _primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, size: 20),
                    ),
                  ),
                ),
              Expanded(
                child: TextButton(
                  onPressed: page < 2 ? () => _changePage(page + 1) : _finish,
                  style: TextButton.styleFrom(
                    minimumSize: const Size(0, 48),
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        page < 2
                            ? l10n.continueButton
                            : l10n.onboardingGetStarted,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
