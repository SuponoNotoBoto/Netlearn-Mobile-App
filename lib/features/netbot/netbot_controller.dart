import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_client.dart';
import 'netbot_models.dart';
import 'netbot_service.dart';

class NetBotState {
  final List<NetBotMessage> messages;
  final bool isStreaming;
  final String? errorMessage;
  final String? currentProviderName;
  final String? userId;

  const NetBotState({
    this.messages = const [],
    this.isStreaming = false,
    this.errorMessage,
    this.currentProviderName,
    this.userId,
  });

  NetBotState copyWith({
    List<NetBotMessage>? messages,
    bool? isStreaming,
    String? errorMessage,
    String? currentProviderName,
    String? userId,
  }) {
    return NetBotState(
      messages: messages ?? this.messages,
      isStreaming: isStreaming ?? this.isStreaming,
      errorMessage: errorMessage,
      currentProviderName: currentProviderName ?? this.currentProviderName,
      userId: userId ?? this.userId,
    );
  }
}

class NetBotNotifier extends Notifier<NetBotState> {
  String get _activeUserId => supabase.auth.currentUser?.id ?? 'guest';

  @override
  NetBotState build() {
    final uid = _activeUserId;
    // Async load user chat history
    Future.microtask(() => _loadUserHistory(uid));
    return NetBotState(userId: uid);
  }

  Future<void> _loadUserHistory(String uid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('netbot_chat_history_$uid');
      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> decoded = jsonDecode(raw);
        final loaded = decoded
            .map((e) => NetBotMessage.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(messages: loaded, userId: uid);
      } else {
        state = state.copyWith(messages: const [], userId: uid);
      }
    } catch (_) {}
  }

  Future<void> _saveUserHistory() async {
    final uid = _activeUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      // Keep up to 50 most recent messages to prevent storage bloat
      final toSave = state.messages.length > 50
          ? state.messages.sublist(state.messages.length - 50)
          : state.messages;
      final raw = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString('netbot_chat_history_$uid', raw);
    } catch (_) {}
  }

  Future<void> clearConversation() async {
    final uid = _activeUserId;
    state = NetBotState(userId: uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('netbot_chat_history_$uid');
    } catch (_) {}
  }

  Future<void> sendMessage({
    required String text,
    required NetBotContext context,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final uid = _activeUserId;
    // Guard: if user changed without build triggering, reload user history first
    if (state.userId != uid) {
      await _loadUserHistory(uid);
    }

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
      userId: uid,
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

      // Persist completed chat to the active user's storage
      await _saveUserHistory();
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

      await _saveUserHistory();
    } finally {
      state = state.copyWith(isStreaming: false);
    }
  }
}

final netBotProvider = NotifierProvider<NetBotNotifier, NetBotState>(
  NetBotNotifier.new,
);
