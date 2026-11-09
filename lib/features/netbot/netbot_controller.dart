import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'netbot_models.dart';
import 'netbot_service.dart';

class NetBotState {
  final List<NetBotMessage> messages;
  final bool isStreaming;
  final String? errorMessage;
  final String? currentProviderName;

  const NetBotState({
    this.messages = const [],
    this.isStreaming = false,
    this.errorMessage,
    this.currentProviderName,
  });

  NetBotState copyWith({
    List<NetBotMessage>? messages,
    bool? isStreaming,
    String? errorMessage,
    String? currentProviderName,
  }) {
    return NetBotState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: errorMessage,
      currentProviderName: currentProviderName ?? this.currentProviderName,
    );
  }
}

class NetBotNotifier extends Notifier<NetBotState> {
  @override
  NetBotState build() {
    return const NetBotState();
  }

  void clearConversation() {
    state = const NetBotState();
  }

  Future<void> sendMessage({
    required String text,
    required NetBotContext context,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final now = DateTime.now();
    final userMsg = NetBotMessage(
      id: 'user_${now.millisecondsSinceEpoch}',
      text: trimmed,
      isUser: true,
      timestamp: now,
    );

    final botMsgId = 'bot_${now.millisecondsSinceEpoch}';
    final initialBotMsg = NetBotMessage(
      id: botMsgId,
      text: '',
      isUser: false,
      timestamp: now,
    );

    final currentHistory = state.messages;
    final updatedMessages = [...currentHistory, userMsg, initialBotMsg];

    state = state.copyWith(
      messages: updatedMessages,
      isStreaming: true,
      errorMessage: null,
    );

    final responseBuffer = StringBuffer();
    String? usedProvider;

    try {
      final stream = NetBotService.sendMessageStream(
        userMessage: trimmed,
        context: context,
        history: currentHistory,
        onProviderConnected: (providerName) {
          usedProvider = providerName;
          state = state.copyWith(currentProviderName: providerName);
        },
      );

      await for (final chunk in stream) {
        responseBuffer.write(chunk);

        final botText = responseBuffer.toString();
        final msgs = state.messages.map((m) {
          if (m.id == botMsgId) {
            return m.copyWith(
              text: botText,
              providerName: usedProvider,
            );
          }
          return m;
        }).toList();

        state = state.copyWith(messages: msgs);
      }
    } catch (e) {
      final errorText = context.languageCode == 'id'
          ? 'Terjadi kendala saat memproses jawaban ($e). Silakan coba lagi.'
          : 'An error occurred while generating the answer ($e). Please try again.';

      final msgs = state.messages.map((m) {
        if (m.id == botMsgId) {
          return m.copyWith(
            text: responseBuffer.isNotEmpty ? responseBuffer.toString() : errorText,
            isError: true,
            providerName: usedProvider,
          );
        }
        return m;
      }).toList();

      state = state.copyWith(
        messages: msgs,
        errorMessage: e.toString(),
      );
    } finally {
      state = state.copyWith(isStreaming: false);
    }
  }
}

final netBotProvider = NotifierProvider<NetBotNotifier, NetBotState>(
  NetBotNotifier.new,
);

