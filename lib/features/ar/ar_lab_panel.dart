import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';
import '../../shared/widgets/nl_button.dart';
import '../../shared/widgets/nl_field.dart';
import '../../shared/widgets/status_badge.dart';
import 'ar_lab_scene.dart';
import 'ip_simulation.dart';

/// Compact control overlay for the Modul 4 (marker 6) 3D AR lab.
///
/// Unlike the earlier two-computer form, this does **not** draw the topology:
/// the computers, switch, cables and packet are real 3D nodes in the camera view
/// (see `ar_lab_scene.dart`). The panel only edits one computer's IPv4 address
/// and subnet mask at a time and reports the simulation result, so the 3D lab
/// stays the focus and the card stays small.
///
/// The widget is controlled: the scanner owns which [selectedDevice] is active
/// (so a tap on a 3D computer can select it) and receives the evaluation back
/// via [onTestResult] to start or stop the packet animation. Validation is
/// delegated entirely to the pure engine in `ip_simulation.dart` — the UI never
/// decides connectivity from the text on screen.
class ArLabPanel extends StatefulWidget {
  final ArLabDevice selectedDevice;
  final ValueChanged<ArLabDevice> onSelect;

  /// Fired after every "Test Connection", carrying the engine result so the
  /// scanner can animate the packet only on success.
  final ValueChanged<IpConnectionResult> onTestResult;

  /// Fired on "Reset"; the scanner stops and removes the packet.
  final VoidCallback onReset;

  final VoidCallback onClose;

  const ArLabPanel({
    super.key,
    required this.selectedDevice,
    required this.onSelect,
    required this.onTestResult,
    required this.onReset,
    required this.onClose,
  });

  /// Default example configuration: two hosts in the same `/24` subnet.
  static const String defaultIpA = '192.168.1.10';
  static const String defaultMaskA = '255.255.255.0';
  static const String defaultIpB = '192.168.1.20';
  static const String defaultMaskB = '255.255.255.0';

  static const Key chipAKey = Key('arLabChipA');
  static const Key chipBKey = Key('arLabChipB');
  static const Key ipFieldKey = Key('arLabIpField');
  static const Key maskFieldKey = Key('arLabMaskField');
  static const Key testButtonKey = Key('arLabTestButton');
  static const Key resetButtonKey = Key('arLabResetButton');
  static const Key editButtonKey = Key('arLabEditButton');

  @override
  State<ArLabPanel> createState() => _ArLabPanelState();
}

class _ArLabPanelState extends State<ArLabPanel> {
  final TextEditingController _ipAController =
      TextEditingController(text: ArLabPanel.defaultIpA);
  final TextEditingController _maskAController =
      TextEditingController(text: ArLabPanel.defaultMaskA);
  final TextEditingController _ipBController =
      TextEditingController(text: ArLabPanel.defaultIpB);
  final TextEditingController _maskBController =
      TextEditingController(text: ArLabPanel.defaultMaskB);

  /// Last evaluation result, or `null` before the first "Test Connection".
  IpConnectionResult? _result;

  /// True once a test has run: the editable form is hidden and only the result
  /// plus an "Edit" button remain, so the 3D lab is not covered by the form
  /// after the student has already tested. "Edit" (or "Reset") brings it back.
  bool _formCollapsed = false;

  @override
  void dispose() {
    _ipAController.dispose();
    _maskAController.dispose();
    _ipBController.dispose();
    _maskBController.dispose();
    super.dispose();
  }

  TextEditingController get _selectedIp =>
      widget.selectedDevice == ArLabDevice.pcA ? _ipAController : _ipBController;

  TextEditingController get _selectedMask =>
      widget.selectedDevice == ArLabDevice.pcA ? _maskAController : _maskBController;

  void _testConnection() {
    final IpConnectionResult result = evaluateConnection(
      ipA: _ipAController.text,
      maskA: _maskAController.text,
      ipB: _ipBController.text,
      maskB: _maskBController.text,
    );
    // Collapse the form so the result (and the 3D lab behind it) is visible;
    // the student reopens it with the "Edit" button.
    setState(() {
      _result = result;
      _formCollapsed = true;
    });
    widget.onTestResult(result);
  }

  void _reset() {
    setState(() {
      _ipAController.text = ArLabPanel.defaultIpA;
      _maskAController.text = ArLabPanel.defaultMaskA;
      _ipBController.text = ArLabPanel.defaultIpB;
      _maskBController.text = ArLabPanel.defaultMaskB;
      _result = null;
      _formCollapsed = false;
    });
    widget.onReset();
  }

  void _edit() {
    setState(() => _formCollapsed = false);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    // Keep the card clear of the top controls and the bottom navbar; content
    // beyond that scrolls instead of overflowing on a narrow 360dp phone.
    final double maxHeight = MediaQuery.sizeOf(context).height * 0.5;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 480),
      child: Material(
        color: theme.colorScheme.surface,
        elevation: 8,
        borderRadius: BorderRadius.circular(16),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context, l10n, theme),
                const SizedBox(height: 10),
                if (_formCollapsed)
                  _buildCollapsedControls(l10n)
                else ...[
                  _buildDeviceSelector(l10n),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Column(
                      children: [
                        NlField(
                          key: ArLabPanel.ipFieldKey,
                          label: l10n.arIpAddressLabel,
                          placeholder: '192.168.1.1',
                          controller: _selectedIp,
                        ),
                        const SizedBox(height: 12),
                        NlField(
                          key: ArLabPanel.maskFieldKey,
                          label: l10n.arIpSubnetLabel,
                          placeholder: '255.255.255.0',
                          controller: _selectedMask,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: NlButton(
                            key: ArLabPanel.testButtonKey,
                            label: l10n.arIpTestButton,
                            icon: Icons.play_arrow_rounded,
                            onPressed: _testConnection,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: NlButton(
                            key: ArLabPanel.resetButtonKey,
                            label: l10n.arIpResetButton,
                            variant: NlButtonVariant.outline,
                            icon: Icons.refresh_rounded,
                            onPressed: _reset,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildResult(context, l10n, theme),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.arObjIpAddressName,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  l10n.arModuleBadge(4),
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
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.close,
          onPressed: widget.onClose,
        ),
      ],
    );
  }

  /// Shown after a test: the form is hidden and this single "Edit" button
  /// reopens it, so the result and the 3D lab stay visible until the student
  /// chooses to change the addresses again.
  Widget _buildCollapsedControls(AppLocalizations l10n) {
    return Align(
      alignment: Alignment.centerLeft,
      child: NlButton(
        key: ArLabPanel.editButtonKey,
        label: l10n.edit,
        variant: NlButtonVariant.outline,
        icon: Icons.edit_rounded,
        onPressed: _edit,
      ),
    );
  }

  /// Two labelled buttons that always select a computer, independent of taps on
  /// the 3D objects (the plugin cannot report mesh taps on Android).
  Widget _buildDeviceSelector(AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Row(
        children: [
          Expanded(
            child: _DeviceChip(
              key: ArLabPanel.chipAKey,
              label: l10n.arIpComputerA,
              icon: Icons.computer_rounded,
              selected: widget.selectedDevice == ArLabDevice.pcA,
              onTap: () => widget.onSelect(ArLabDevice.pcA),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _DeviceChip(
              key: ArLabPanel.chipBKey,
              label: l10n.arIpComputerB,
              icon: Icons.computer_rounded,
              selected: widget.selectedDevice == ArLabDevice.pcB,
              onTap: () => widget.onSelect(ArLabDevice.pcB),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(
    BuildContext context,
    AppLocalizations l10n,
    ThemeData theme,
  ) {
    final IpConnectionResult? result = _result;
    if (result == null) {
      return Text(
        l10n.arIpInitialHint,
        style: theme.textTheme.bodySmall?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          height: 1.4,
        ),
      );
    }

    final bool success = result.success;
    final String message = success
        ? l10n.arIpSuccessReason(result.networkAddressLabel ?? '')
        : _failureMessage(l10n, result.failure!);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatusBadge(
          status: success ? NetLearnStatus.linked : NetLearnStatus.down,
          label: success ? l10n.arIpSuccessTitle : l10n.arIpFailureTitle,
        ),
        const SizedBox(height: 8),
        Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
        ),
      ],
    );
  }

  String _failureMessage(AppLocalizations l10n, IpSimulationFailure failure) {
    switch (failure) {
      case IpSimulationFailure.invalidIpA:
        return l10n.arIpErrInvalidIpA;
      case IpSimulationFailure.invalidMaskA:
        return l10n.arIpErrInvalidMaskA;
      case IpSimulationFailure.unusableHostA:
        return l10n.arIpErrUnusableHostA;
      case IpSimulationFailure.invalidIpB:
        return l10n.arIpErrInvalidIpB;
      case IpSimulationFailure.invalidMaskB:
        return l10n.arIpErrInvalidMaskB;
      case IpSimulationFailure.unusableHostB:
        return l10n.arIpErrUnusableHostB;
      case IpSimulationFailure.duplicateAddress:
        return l10n.arIpErrDuplicate;
      case IpSimulationFailure.differentSubnet:
        return l10n.arIpErrDifferentSubnet;
    }
  }
}

/// Segmented button for selecting one of the two computers. Not a `ChoiceChip`
/// so the selection state can use the app's primary container colours directly
/// and stay legible on the dark scanner overlay.
class _DeviceChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DeviceChip({
    super.key,
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Material(
      color: selected ? scheme.primary : scheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: selected ? scheme.onPrimary : scheme.onSurfaceVariant,
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
