import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/audio/sfx_service.dart';
import 'virtual_lab_model.dart';
import 'virtual_lab_network.dart';

/// Engine logika eksekusi perintah terminal (CLI) virtual PC.
class VirtualLabTerminalEngine {
  static const String banner = 
      'NetLearn OS [Version 2.0.1]\n'
      '(c) NetLearn Corporation. All rights reserved.\n'
      'Ketik "help" untuk panduan perintah atau "ipconfig" untuk info jaringan.\n';

  static List<String> execute({
    required String command,
    required VirtualLabSession session,
    required VirtualLabDevice currentDevice,
    required void Function(VirtualLabConnectivityResult result)? onPingResult,
  }) {
    final raw = command.trim();
    if (raw.isEmpty) return const [];

    final parts = raw.split(RegExp(r'\s+'));
    final cmd = parts[0].toLowerCase();
    final args = parts.sublist(1);

    switch (cmd) {
      case 'help':
      case '?':
        return [
          'Daftar Perintah Terminal NetLearn:',
          '  ipconfig           Menampilkan konfigurasi IP, subnet, dan gateway PC ini',
          '  ping <IP_Tujuan>   Menguji konektivitas ICMP ke host tujuan',
          '  tracert <IP_Tujuan> Melacak jalur hop menuju host tujuan',
          '  cls / clear        Membersihkan layar terminal',
          '  help               Menampilkan panduan perintah ini',
        ];

      case 'ipconfig':
      case 'ifconfig':
        final cabled = session.cables.any((c) => c.involves(currentDevice.id));
        final ip = (currentDevice.ipAddress ?? '').trim();
        final mask = (currentDevice.subnetMask ?? '').trim();
        final gw = (currentDevice.defaultGateway ?? '').trim();
        return [
          'NetLearn Virtual Ethernet Adapter:',
          '',
          '   Connection-specific DNS Suffix  . : netlearn.edu',
          '   Link Status . . . . . . . . . . . : ${cabled ? "Connected (100 Mbps Full Duplex)" : "Media disconnected (Kabel belum terpasang)"}',
          '   IPv4 Address. . . . . . . . . . . : ${ip.isNotEmpty ? ip : "(Belum dikonfigurasi)"}',
          '   Subnet Mask . . . . . . . . . . . : ${mask.isNotEmpty ? mask : "(Belum dikonfigurasi)"}',
          '   Default Gateway . . . . . . . . . : ${gw.isNotEmpty ? gw : "(None)"}',
        ];

      case 'ping':
        if (args.isEmpty) {
          return [
            'Usage: ping [-t] <target_ip>',
            'Contoh: ping 192.168.1.20',
          ];
        }
        final targetIpStr = args[0].trim();
        final parsedTargetIp = VirtualLabIpv4.parse(targetIpStr);
        if (parsedTargetIp == null) {
          return [
            'Ping request could not find host $targetIpStr.',
            'Please check the name and try again.',
          ];
        }

        final myIp = (currentDevice.ipAddress ?? '').trim();
        if (myIp.isEmpty || (currentDevice.subnetMask ?? '').trim().isEmpty) {
          return [
            'Pinging $targetIpStr with 32 bytes of data:',
            'Transmit failed: General failure (IP address tidak dikonfigurasi pada PC ini).',
          ];
        }

        final isCabled = session.cables.any((c) => c.involves(currentDevice.id));
        if (!isCabled) {
          return [
            'Pinging $targetIpStr with 32 bytes of data:',
            'Transmit failed: Media disconnected (Kabel PC belum tersambung ke jaringan).',
          ];
        }

        // Cari perangkat di kanvas yang memiliki target IP ini
        final targetDevice = session.devices.cast<VirtualLabDevice?>().firstWhere(
              (d) => d != null && d.ipAddress?.trim() == targetIpStr,
              orElse: () => null,
            );

        if (targetDevice == null) {
          return [
            'Pinging $targetIpStr with 32 bytes of data:',
            'Request timed out.',
            'Request timed out.',
            'Request timed out.',
            'Request timed out.',
            '',
            'Ping statistics for $targetIpStr:',
            '    Packets: Sent = 4, Received = 0, Lost = 4 (100% loss)',
          ];
        }

        // Lakukan pengujian konektivitas menggunakan engine yang telah terverifikasi
        final result = VirtualLabConnectivityEngine.ping(
          session,
          sourceId: currentDevice.id,
          targetId: targetDevice.id,
        );

        if (onPingResult != null) {
          onPingResult(result);
        }

        if (result.success) {
          final isRouted = result.reason == 'routed_success';
          final baseLatency = isRouted ? 6 : 2;
          final rng = math.Random();
          final r1 = baseLatency + rng.nextInt(3);
          final r2 = baseLatency + rng.nextInt(3);
          final r3 = baseLatency + rng.nextInt(3);
          final r4 = baseLatency + rng.nextInt(3);

          return [
            'Pinging $targetIpStr with 32 bytes of data:',
            'Reply from $targetIpStr: bytes=32 time=${r1}ms TTL=64',
            'Reply from $targetIpStr: bytes=32 time=${r2}ms TTL=64',
            'Reply from $targetIpStr: bytes=32 time=${r3}ms TTL=64',
            'Reply from $targetIpStr: bytes=32 time=${r4}ms TTL=64',
            '',
            'Ping statistics for $targetIpStr:',
            '    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),',
            'Approximate round trip times in milli-seconds:',
            '    Minimum = ${[r1, r2, r3, r4].reduce(math.min)}ms, Maximum = ${[r1, r2, r3, r4].reduce(math.max)}ms, Average = ${((r1 + r2 + r3 + r4) / 4).round()}ms',
            if (isRouted) 'Note: Paket berhasil diteruskan melalui Router Gateway.',
          ];
        } else {
          // Gagal
          final reasonMsg = switch (result.reason) {
            'source_missing_gateway' =>
              'Destination host unreachable: PC sumber butuh Default Gateway untuk subnet lain.',
            'target_missing_gateway' =>
              'Request timed out (PC tujuan tidak memiliki Gateway untuk membalas).',
            'different_subnet_no_router' =>
              'Destination host unreachable: Tidak ada Router yang menghubungkan kedua subnet.',
            'gateway_unreachable' =>
              'Destination host unreachable: Gateway tidak dapat dijangkau.',
            'gateway_subnet_mismatch' =>
              'Destination host unreachable: Gateway tidak berada di subnet yang sama.',
            'no_path' => 'Request timed out (Jalur kabel tidak tersambung).',
            _ => 'Request timed out.',
          };

          return [
            'Pinging $targetIpStr with 32 bytes of data:',
            'Reply from $myIp: $reasonMsg',
            'Reply from $myIp: $reasonMsg',
            'Request timed out.',
            'Request timed out.',
            '',
            'Ping statistics for $targetIpStr:',
            '    Packets: Sent = 4, Received = 0, Lost = 4 (100% loss)',
          ];
        }

      case 'tracert':
      case 'traceroute':
        if (args.isEmpty) {
          return ['Usage: tracert <target_ip>'];
        }
        final targetIpStr = args[0].trim();
        final targetDevice = session.devices.cast<VirtualLabDevice?>().firstWhere(
              (d) => d != null && d.ipAddress?.trim() == targetIpStr,
              orElse: () => null,
            );

        if (targetDevice == null) {
          return [
            'Tracing route to $targetIpStr over a maximum of 30 hops:',
            '  1     *        *        *     Request timed out.',
            'Trace complete.',
          ];
        }

        final result = VirtualLabConnectivityEngine.ping(
          session,
          sourceId: currentDevice.id,
          targetId: targetDevice.id,
        );

        if (onPingResult != null) {
          onPingResult(result);
        }

        if (!result.success) {
          return [
            'Tracing route to $targetIpStr over a maximum of 30 hops:',
            '  1     *        *        *     Destination host unreachable.',
            'Trace complete.',
          ];
        }

        // Bangun urutan hop dari result.details
        final lines = <String>[
          'Tracing route to $targetIpStr [${targetDevice.displayName}] over a maximum of 30 hops:',
          '',
        ];

        int hopNumber = 1;
        for (final id in result.details) {
          final node = session.deviceById(id);
          if (node == null || node.id == currentDevice.id) continue;
          if (node.kind == VirtualLabDeviceKind.switch_) {
            // Switch beroperasi di Layer 2 dan transparan bagi tracert
            continue;
          }
          final ipDisplay = node.ipAddress ?? targetIpStr;
          lines.add('  $hopNumber     2 ms     2 ms     3 ms   $ipDisplay [${node.displayName}]');
          hopNumber++;
        }
        lines.add('');
        lines.add('Trace complete.');
        return lines;

      default:
        return [
          '\'$cmd\' is not recognized as an internal or external command,',
          'operable program or batch file. Ketik "help" untuk panduan.',
        ];
    }
  }
}

/// Widget Tampilan Terminal CLI Gelap ala Windows Command Prompt.
class VirtualLabTerminalWidget extends StatefulWidget {
  const VirtualLabTerminalWidget({
    super.key,
    required this.device,
    required this.session,
    required this.accent,
    this.onPingResult,
  });

  final VirtualLabDevice device;
  final VirtualLabSession session;
  final Color accent;
  final void Function(VirtualLabConnectivityResult result)? onPingResult;

  @override
  State<VirtualLabTerminalWidget> createState() => _VirtualLabTerminalWidgetState();
}

class _VirtualLabTerminalWidgetState extends State<VirtualLabTerminalWidget> {
  final List<String> _history = [];
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _history.addAll(VirtualLabTerminalEngine.banner.trim().split('\n'));
    _history.add('');
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitCommand(String text) {
    final cmd = text.trim();
    if (cmd.isEmpty) return;

    _inputController.clear();

    if (cmd.toLowerCase() == 'cls' || cmd.toLowerCase() == 'clear') {
      setState(() {
        _history.clear();
      });
      return;
    }

    HapticFeedback.lightImpact();

    setState(() {
      _history.add('C:\\${widget.device.displayName}> $cmd');
      final output = VirtualLabTerminalEngine.execute(
        command: cmd,
        session: widget.session,
        currentDevice: widget.device,
        onPingResult: (result) {
          if (widget.onPingResult != null) {
            widget.onPingResult!(result);
          }
          if (result.success) {
            SfxService.instance.playConnect();
          } else {
            SfxService.instance.playError();
          }
        },
      );
      _history.addAll(output);
      _history.add('');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final otherPcs = widget.session.devices
        .where((d) => d.kind == VirtualLabDeviceKind.pc && d.id != widget.device.id && (d.ipAddress ?? '').isNotEmpty)
        .toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F141C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF232B38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Bar Terminal
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            color: const Color(0xFF192231),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                const Icon(Icons.terminal_rounded, size: 14, color: Color(0xFF94A3B8)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'cmd.exe — [${widget.device.displayName}]',
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFCBD5E1),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.clear_all_rounded, size: 16, color: Color(0xFF94A3B8)),
                  tooltip: 'Clear Screen (cls)',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _history.clear()),
                ),
              ],
            ),
          ),

          // Output Teks Konsol
          Container(
            height: 200,
            padding: const EdgeInsets.all(12),
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final line = _history[index];
                final isPrompt = line.startsWith('C:\\');
                final isError = line.contains('unreachable') || line.contains('timed out') || line.contains('failed');
                final isSuccess = line.contains('Reply from') && !isError;

                Color textColor = const Color(0xFFE2E8F0);
                if (isPrompt) {
                  textColor = const Color(0xFF38BDF8); // Cyan
                } else if (isSuccess) {
                  textColor = const Color(0xFF4ADE80); // Green
                } else if (isError) {
                  textColor = const Color(0xFFF87171); // Red
                }

                return Text(
                  line,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11,
                    height: 1.35,
                    color: textColor,
                  ),
                );
              },
            ),
          ),

          // Quick Command Chips
          Container(
            padding: const EdgeInsets.fromLTRB(10, 6, 10, 6),
            color: const Color(0xFF141B26),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildQuickChip('ipconfig', () => _submitCommand('ipconfig')),
                  const SizedBox(width: 6),
                  _buildQuickChip('help', () => _submitCommand('help')),
                  const SizedBox(width: 6),
                  _buildQuickChip('cls', () => _submitCommand('cls')),
                  if (otherPcs.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    for (final other in otherPcs) ...[
                      _buildQuickChip('ping ${other.ipAddress}', () => _submitCommand('ping ${other.ipAddress}')),
                      const SizedBox(width: 6),
                      _buildQuickChip('tracert ${other.ipAddress}', () => _submitCommand('tracert ${other.ipAddress}')),
                      const SizedBox(width: 6),
                    ],
                  ],
                ],
              ),
            ),
          ),

          // Baris Input Perintah
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: Color(0xFF0F141C),
              border: Border(top: BorderSide(color: Color(0xFF232B38))),
            ),
            child: Row(
              children: [
                Text(
                  'C:\\${widget.device.displayName}> ',
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF38BDF8),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _inputController,
                    focusNode: _focusNode,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11.5,
                      color: Colors.white,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ketik perintah...',
                      hintStyle: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 11.5,
                        color: Color(0xFF64748B),
                      ),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 4),
                      border: InputBorder.none,
                    ),
                    onSubmitted: _submitCommand,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send_rounded, size: 16, color: Color(0xFF38BDF8)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _submitCommand(_inputController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: const Color(0xFF334155)),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF94A3B8),
          ),
        ),
      ),
    );
  }
}

