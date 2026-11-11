import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import 'ar_marker_catalog.dart';

/// Full learning information for a recognized Modul 1–3 object, opened by
/// tapping the 3D model (AR_PRD AR-10).
///
/// The scanner keeps showing the compact summary card while the marker is
/// detected; tapping the model opens this "more detailed" layer on top of it.
/// The content is static localized copy (en/id), deliberately not read from
/// Supabase: the AR feature stays a read-only learning aid and a scan must
/// never depend on the network.
///
/// The widget is controlled exactly like [ArLabPanel] is — the scanner decides
/// when it is visible, and dismissing it never touches the AR session or the
/// placed model, so the scene does not blink empty.
class ArObjectDetailPanel extends StatelessWidget {
  const ArObjectDetailPanel({
    super.key,
    required this.marker,
    required this.onClose,
  });

  /// Key for the close button, so widget tests can tap it without depending on
  /// localized copy.
  static const Key closeButtonKey = Key('arDetailClose');

  /// The recognized object the panel describes.
  final ArMarker marker;

  /// Dismisses the panel while keeping the model and the summary card on screen.
  final VoidCallback onClose;

  String _title(AppLocalizations l10n) {
    switch (marker.id) {
      case ArMarkerId.komputer:
        return l10n.arObjKomputerName;
      case ArMarkerId.switchDevice:
        return l10n.arObjSwitchName;
      case ArMarkerId.hub:
        return l10n.arObjHubName;
      case ArMarkerId.router:
        return l10n.arObjRouterName;
      case ArMarkerId.topologi:
        return l10n.arObjTopologiName;
      case ArMarkerId.ipAddress:
        return l10n.arObjIpAddressName;
    }
  }

  String _definition(AppLocalizations l10n) {
    switch (marker.id) {
      case ArMarkerId.komputer:
        return l10n.arObjKomputerDetailDef;
      case ArMarkerId.switchDevice:
        return l10n.arObjSwitchDetailDef;
      case ArMarkerId.hub:
        return l10n.arObjHubDetailDef;
      case ArMarkerId.router:
        return l10n.arObjRouterDetailDef;
      case ArMarkerId.topologi:
        return l10n.arObjTopologiDetailDef;
      case ArMarkerId.ipAddress:
        return ''; // The panel is never shown for Modul 4.
    }
  }

  String _function(AppLocalizations l10n) {
    switch (marker.id) {
      case ArMarkerId.komputer:
        return l10n.arObjKomputerDetailFunction;
      case ArMarkerId.switchDevice:
        return l10n.arObjSwitchDetailFunction;
      case ArMarkerId.hub:
        return l10n.arObjHubDetailFunction;
      case ArMarkerId.router:
        return l10n.arObjRouterDetailFunction;
      case ArMarkerId.topologi:
        return l10n.arObjTopologiDetailFunction;
      case ArMarkerId.ipAddress:
        return '';
    }
  }

  String _extraLabel(AppLocalizations l10n) {
    switch (marker.id) {
      case ArMarkerId.komputer:
        return l10n.arDetailExtraKomputer;
      case ArMarkerId.switchDevice:
        return l10n.arDetailExtraSwitch;
      case ArMarkerId.hub:
        return l10n.arDetailExtraHub;
      case ArMarkerId.router:
        return l10n.arDetailExtraRouter;
      case ArMarkerId.topologi:
        return l10n.arDetailExtraTopologi;
      case ArMarkerId.ipAddress:
        return '';
    }
  }

  String _extra(AppLocalizations l10n) {
    switch (marker.id) {
      case ArMarkerId.komputer:
        return l10n.arObjKomputerDetailExtra;
      case ArMarkerId.switchDevice:
        return l10n.arObjSwitchDetailExtra;
      case ArMarkerId.hub:
        return l10n.arObjHubDetailExtra;
      case ArMarkerId.router:
        return l10n.arObjRouterDetailExtra;
      case ArMarkerId.topologi:
        return l10n.arObjTopologiDetailExtra;
      case ArMarkerId.ipAddress:
        return '';
    }
  }

  /// Small labelled paragraph inside the panel. Body copy is dense, so the
  /// label is a primary-coloured heading and the paragraph gets breathing room.
  Widget _section(ThemeData theme, String label, String body) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.45),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Cap the panel height so a tall object's copy never covers the reticle
    // area entirely; the content scrolls inside the card instead.
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.6;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                l10n.arDetailHeaderLabel,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _title(l10n),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              l10n.arModuleBadge(marker.moduleNumber),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onPrimaryContainer,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      key: closeButtonKey,
                      icon: const Icon(Icons.close_rounded),
                      tooltip: l10n.close,
                      onPressed: onClose,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _section(theme, l10n.arDetailSectionDefinition, _definition(l10n)),
                const SizedBox(height: 12),
                _section(theme, l10n.arDetailSectionFunction, _function(l10n)),
                const SizedBox(height: 12),
                _section(theme, _extraLabel(l10n), _extra(l10n)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}