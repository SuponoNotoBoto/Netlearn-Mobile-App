// ============================================================================
// MODULE: NetBot Chat State Controller & Local Persistence
// DESCRIPTION: Mengelola state percakapan asisten AI NetBot menggunakan
//              Riverpod Notifier, mencakup penyimpanan riwayat chat per akun
//              pengguna di SharedPreferences serta pembaruan token streaming.
// ============================================================================

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/supabase/supabase_client.dart';
import 'netbot_models.dart';
import 'netbot_service.dart';

// ---------------------------------------------------------------------------
// SECTION: Immutable Chat State Model
// ---------------------------------------------------------------------------

/// [NetBotState]
///
/// Menyimpan kondisi terkini dari ruang obrolan NetBot, termasuk daftar pesan,
/// status streaming aktif, nama provider AI yang terhubung, dan ID pemilik sesi.
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

// ---------------------------------------------------------------------------
// SECTION: Riverpod Notifier & Conversation Lifecycle
// ---------------------------------------------------------------------------

/// [NetBotNotifier]
///
/// Controller state Riverpod yang mengatur pengiriman pesan ke [NetBotService],
/// mengisolasi riwayat obrolan berdasarkan ID pengguna yang sedang login,
/// dan membersihkan format Markdown berlebih setelah streaming selesai.
class NetBotNotifier extends Notifier<NetBotState> {
  String get _activeUserId => supabase.auth.currentUser?.id ?? 'guest';

  @override
  NetBotState build() {
    final uid = _activeUserId;
    // Memuat riwayat percakapan pengguna secara asinkron dari penyimpanan lokal.
    Future.microtask(() => _loadUserHistory(uid));
    return NetBotState(userId: uid);
  }

  /// Memulihkan riwayat percakapan milik [uid] dari `SharedPreferences`.
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

  /// Menyimpan maksimal 50 pesan terakhir ke `SharedPreferences` agar ukuran
  /// penyimpanan lokal tetap ringan.
  Future<void> _saveUserHistory() async {
    final uid = _activeUserId;
    try {
      final prefs = await SharedPreferences.getInstance();
      final toSave = state.messages.length > 50
          ? state.messages.sublist(state.messages.length - 50)
          : state.messages;
      final raw = jsonEncode(toSave.map((m) => m.toJson()).toList());
      await prefs.setString('netbot_chat_history_$uid', raw);
    } catch (_) {}
  }

  /// Menghapus seluruh riwayat obrolan pada state dan penyimpanan lokal untuk pengguna aktif.
  Future<void> clearConversation() async {
    final uid = _activeUserId;
    state = NetBotState(userId: uid);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('netbot_chat_history_$uid');
    } catch (_) {}
  }

  /// Mengirim pertanyaan [text] beserta [context] pembelajaran ke layanan AI
  /// dan memperbarui gelembung pesan bot secara reaktif setiap kali chunk diterima.
  Future<void> sendMessage({
    required String text,
    required NetBotContext context,
  }) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.isStreaming) return;

    final uid = _activeUserId;
    // Pengaman pergantian akun: muat ulang riwayat jika userId berubah.
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

      // Sanitasi teks akhir untuk membersihkan simbol ** berlebih di luar blok kode.
      final cleanText = NetBotService.cleanResponseText(responseBuffer.toString());
      final finalizedMsgs = state.messages.map((m) {
        if (m.id == botMsgId) {
          return m.copyWith(
            text: cleanText,
            providerName: usedProvider,
          );
        }
        return m;
      }).toList();
      state = state.copyWith(messages: finalizedMsgs);

      // Simpan percakapan yang telah selesai ke penyimpanan lokal pengguna.
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

/// Provider global Riverpod untuk mengakses state dan aksi [NetBotNotifier].
final netBotProvider = NotifierProvider<NetBotNotifier, NetBotState>(
  NetBotNotifier.new,
);
