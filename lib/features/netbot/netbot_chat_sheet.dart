import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import 'netbot_controller.dart';
import 'netbot_models.dart';

/// Shows the NetBot AI Tutor chat bottom sheet.
Future<void> showNetBotChatSheet(
  BuildContext context, {
  NetBotContext? netBotContext,
}) async {
  final isDark = Theme.of(context).brightness == Brightness.dark;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: isDark ? const Color(0xFF16151D) : Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (ctx) {
      return NetBotChatSheet(
        netBotContext: netBotContext ??
            NetBotContext(
              languageCode: Localizations.localeOf(context).languageCode,
            ),
      );
    },
  );
}

class NetBotChatSheet extends ConsumerStatefulWidget {
  final NetBotContext netBotContext;

  const NetBotChatSheet({
    super.key,
    required this.netBotContext,
  });

  @override
  ConsumerState<NetBotChatSheet> createState() => _NetBotChatSheetState();
}

class _NetBotChatSheetState extends ConsumerState<NetBotChatSheet> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  bool _hasText = false;
  late final stt.SpeechToText _speech;
  bool _speechAvailable = false;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _textController.addListener(() {
      final has = _textController.text.trim().isNotEmpty;
      if (has != _hasText) {
        setState(() {
          _hasText = has;
        });
      }
    });
  }

  @override
  void dispose() {
    if (_isListening) {
      _speech.stop();
    }
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() => _isListening = false);
      }
      return;
    }

    try {
      if (!_speechAvailable) {
        _speechAvailable = await _speech.initialize(
          onError: (_) {
            if (mounted) setState(() => _isListening = false);
          },
          onStatus: (status) {
            if (mounted && (status == 'done' || status == 'notListening')) {
              setState(() => _isListening = false);
            }
          },
        );
      }

      if (!_speechAvailable) {
        if (!mounted) return;
        final isId = widget.netBotContext.languageCode == 'id';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isId
                  ? 'Mikrofon tidak tersedia atau izin belum diberikan.'
                  : 'Microphone unavailable or permission denied.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      if (!mounted) return;
      setState(() => _isListening = true);

      await _speech.listen(
        onResult: (result) {
          if (!mounted) return;
          setState(() {
            _textController.text = result.recognizedWords;
            _textController.selection = TextSelection.fromPosition(
              TextPosition(offset: _textController.text.length),
            );
          });
        },
      );
    } catch (_) {
      if (mounted) {
        setState(() => _isListening = false);
      }
    }
  }

  void _submitMessage(String text) {
    if (text.trim().isEmpty) return;
    _textController.clear();
    ref.read(netBotProvider.notifier).sendMessage(
          text: text,
          context: widget.netBotContext,
        );
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final botState = ref.watch(netBotProvider);
    final isId = widget.netBotContext.languageCode == 'id';

    ref.listen(netBotProvider, (_, next) {
      if (next.isStreaming) {
        _scrollToBottom();
      }
    });

    final quickPrompts = isId
        ? [
            '💡 Jelaskan konsep ini dengan analogi sederhana',
            '🔍 Berikan contoh di dunia nyata',
            '❓ Buatkan 1 soal latihan singkat untuk saya',
            if (widget.netBotContext.materialTitle?.toLowerCase().contains('subnet') == true ||
                widget.netBotContext.materialTitle?.toLowerCase().contains('ip') == true)
              '📐 Tunjukkan rumus & cara hitung subnetting',
            if (widget.netBotContext.topologySnippet != null)
              '🛠️ Bantu periksa konektivitas topologi lab saya',
          ]
        : [
            '💡 Explain this concept with a simple analogy',
            '🔍 Give a real-world networking example',
            '❓ Quiz me with one practice question',
            if (widget.netBotContext.materialTitle?.toLowerCase().contains('subnet') == true ||
                widget.netBotContext.materialTitle?.toLowerCase().contains('ip') == true)
              '📐 Show step-by-step subnet calculation',
            if (widget.netBotContext.topologySnippet != null)
              '🛠️ Help check my virtual lab topology setup',
          ];

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final hasKeyboard = bottomInset > 0;

    return SizedBox(
      height: MediaQuery.of(context).size.height * (hasKeyboard ? 0.90 : 0.82),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? const Color(0xFF2C283E) : const Color(0xFFEDEAF6),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8C52FF), Color(0xFF6C2CE2)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'NetBot',
                                style: TextStyle(
                                  fontFamily: 'PlusJakartaSans',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF1D1C21),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1ECFF),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'AI TUTOR',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF6C2CE2),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF1EA95B),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  botState.currentProviderName != null
                                      ? (isId ? 'Didukung ${botState.currentProviderName}' : 'Powered by ${botState.currentProviderName}')
                                      : (isId ? 'Didukung Multi-Provider AI' : 'Powered by Multi-Provider AI'),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF7E7B8F),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (botState.messages.isNotEmpty)
                      IconButton(
                        tooltip: isId ? 'Hapus Chat' : 'Clear Chat',
                        icon: const Icon(Icons.delete_outline_rounded, size: 20),
                        onPressed: () {
                          ref.read(netBotProvider.notifier).clearConversation();
                        },
                      ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              // Active Context Grounding Pill (Material or Lab)
              if (widget.netBotContext.materialTitle != null &&
                  widget.netBotContext.materialTitle!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  color: isDark ? const Color(0x228C52FF) : const Color(0xFFF6F3FF),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.menu_book_rounded,
                        size: 14,
                        color: Color(0xFF8C52FF),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${isId ? 'Membahas' : 'Context'}: ${widget.netBotContext.materialTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6C2CE2),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else if (widget.netBotContext.topologySnippet != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                  color: isDark ? const Color(0x221EA95B) : const Color(0xFFE8F8F0),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.hub_rounded,
                        size: 14,
                        color: Color(0xFF1EA95B),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          isId
                              ? 'Konteks Aktif: Topologi Virtual Lab Terhubung'
                              : 'Active Context: Virtual Lab Topology Connected',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF147A40),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Messages List or Welcome
              Expanded(
                child: botState.messages.isEmpty
                    ? _buildEmptyWelcome(context, isDark, isId, quickPrompts)
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        itemCount: botState.messages.length,
                        itemBuilder: (ctx, i) {
                          return _buildMessageBubble(
                            botState.messages[i],
                            isDark,
                            isId,
                          );
                        },
                      ),
              ),

              // Quick Prompts Horizontal Scroll (if conversation has messages)
              if (botState.messages.isNotEmpty)
                Container(
                  height: 38,
                  margin: const EdgeInsets.only(bottom: 6),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    scrollDirection: Axis.horizontal,
                    itemCount: quickPrompts.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 6),
                    itemBuilder: (ctx, idx) {
                      final prompt = quickPrompts[idx];
                      return ActionChip(
                        label: Text(
                          prompt,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFFC7BFF5) : const Color(0xFF5E27C9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        backgroundColor: isDark ? const Color(0xFF28233C) : const Color(0xFFF4F0FC),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(
                            color: isDark ? const Color(0xFF3D375B) : const Color(0xFFE4DCF9),
                          ),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        onPressed: botState.isStreaming ? null : () => _submitMessage(prompt),
                      );
                    },
                  ),
                ),

              // Chat Input Bar
              Container(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1A1822) : Colors.white,
                  border: Border(
                    top: BorderSide(
                      color: isDark ? const Color(0xFF2C283E) : const Color(0xFFEDEAF6),
                    ),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF23202E) : const Color(0xFFF7F6FA),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? const Color(0xFF3A354C) : const Color(0xFFE5E1EE),
                          ),
                        ),
                        child: TextField(
                          controller: _textController,
                          enabled: !botState.isStreaming,
                          minLines: 1,
                          maxLines: 4,
                          textInputAction: TextInputAction.send,
                          onSubmitted: _submitMessage,
                          decoration: InputDecoration(
                            hintText: isId
                                ? 'Tanyakan seputar jaringan komputer...'
                                : 'Ask about computer networking...',
                            hintStyle: TextStyle(
                              fontSize: 13,
                              color: isDark ? const Color(0xFF888499) : const Color(0xFF8E8B9D),
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Voice Input Button
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: botState.isStreaming ? null : _toggleListening,
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening
                                ? const Color(0x22FF5252)
                                : Colors.transparent,
                            border: _isListening
                                ? Border.all(color: Colors.redAccent, width: 1.5)
                                : null,
                          ),
                          child: Icon(
                            _isListening ? Icons.mic_rounded : Icons.mic_none_rounded,
                            size: 20,
                            color: _isListening
                                ? Colors.redAccent
                                : (isDark ? const Color(0xFF9E9AAF) : const Color(0xFF7E7B8F)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    // Send Button
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF8C52FF), Color(0xFF6C2CE2)],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: botState.isStreaming
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send_rounded, color: Colors.white, size: 18),
                        onPressed: _hasText && !botState.isStreaming
                            ? () => _submitMessage(_textController.text)
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyWelcome(
    BuildContext context,
    bool isDark,
    bool isId,
    List<String> quickPrompts,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF8C52FF), Color(0xFF6C2CE2)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              isId ? 'Halo, Saya NetBot! 👋' : 'Hello, I am NetBot! 👋',
              style: TextStyle(
                fontFamily: 'PlusJakartaSans',
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF1D1C21),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isId
                  ? 'Asisten AI cerdas untuk belajar Jaringan Komputer. Tanyakan konsep subnetting, perangkat router/switch, atau troubleshooting lab.'
                  : 'Your intelligent AI tutor for Computer Networking. Ask about subnetting, router/switch configurations, or lab troubleshooting.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? const Color(0xFF9E9AAF) : const Color(0xFF7E7B8F),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 18),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: quickPrompts.map((prompt) {
                return ActionChip(
                  label: Text(
                    prompt,
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: isDark ? const Color(0xFFC7BFF5) : const Color(0xFF5E27C9),
                    ),
                  ),
                  backgroundColor: isDark ? const Color(0xFF28233C) : const Color(0xFFF4F0FC),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF3D375B) : const Color(0xFFE4DCF9),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  onPressed: () => _submitMessage(prompt),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(
    NetBotMessage message,
    bool isDark,
    bool isId,
  ) {
    if (message.isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10, left: 48),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF8C52FF),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
              bottomLeft: Radius.circular(16),
              bottomRight: Radius.circular(4),
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x228C52FF),
                blurRadius: 8,
                offset: Offset(0, 3),
              ),
            ],
          ),
          child: Text(
            message.text,
            style: const TextStyle(
              fontSize: 13.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ),
      );
    }

    // Bot message bubble
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12, right: 32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: message.isError
              ? (isDark ? const Color(0x2BFF5252) : const Color(0xFFFFECEC))
              : (isDark ? const Color(0xFF23202E) : const Color(0xFFFAF9FD)),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(16),
            bottomLeft: Radius.circular(16),
            bottomRight: Radius.circular(16),
          ),
          border: Border.all(
            color: message.isError
                ? const Color(0xFFFF8A80)
                : (isDark ? const Color(0xFF332D48) : const Color(0xFFEBE7F4)),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      message.isError ? Icons.error_outline_rounded : Icons.auto_awesome_rounded,
                      size: 14,
                      color: message.isError ? const Color(0xFFD32F2F) : const Color(0xFF8C52FF),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'NetBot',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: message.isError ? const Color(0xFFD32F2F) : const Color(0xFF8C52FF),
                      ),
                    ),
                    if (message.providerName != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${message.providerName})',
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: Color(0xFF9E9AAF),
                        ),
                      ),
                    ],
                  ],
                ),
                if (message.text.isNotEmpty)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: message.text));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isId ? 'Jawaban disalin ke clipboard' : 'Answer copied to clipboard',
                          ),
                          duration: const Duration(seconds: 1),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(2.0),
                      child: Icon(
                        Icons.copy_rounded,
                        size: 14,
                        color: Color(0xFF9E9AAF),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (message.text.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              )
            else
              SelectableText(
                message.text,
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.45,
                  color: message.isError
                      ? const Color(0xFFC62828)
                      : (isDark ? Colors.white : const Color(0xFF23202E)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
