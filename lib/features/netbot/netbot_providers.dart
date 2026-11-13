// ============================================================================
// MODULE: AI Provider Registry & Priority Configuration
// DESCRIPTION: Mendefinisikan daftar penyedia layanan LLM beserta urutan
//              prioritas failover dan model kandidat untuk asisten AI NetBot.
// ============================================================================

import '../../core/constants/env.dart';
import 'netbot_models.dart';

/// [NetBotProviders]
///
/// Mengelola registrasi dan pemfilteran penyedia AI yang aktif berdasarkan
/// ketersediaan API key pada konfigurasi [Env].
class NetBotProviders {
  NetBotProviders._();

  /// [getAvailableProviders]
  ///
  /// Mengembalikan daftar penyedia AI yang telah memiliki API key valid,
  /// diurutkan berdasarkan tingkat prioritas eksekusi:
  /// 1. **Groq LPU** (Prioritas 1 — Latensi ultra-rendah untuk respons real-time).
  /// 2. **OpenRouter** (Prioritas 2 — Agregator model cadangan gratis/terbuka).
  /// 3. **Google Gemini** (Prioritas 3 — Cadangan akhir dengan stabilitas tinggi).
  static List<AiProviderConfig> getAvailableProviders() {
    final all = <AiProviderConfig>[
      AiProviderConfig(
        id: 'groq',
        name: 'Groq LPU',
        endpoint: 'https://api.groq.com/openai/v1/chat/completions',
        apiKey: Env.groqApiKey,
        candidateModels: const [
          'openai/gpt-oss-20b',
          'openai/gpt-oss-120b',
          'qwen/qwen3.8-27b',
          'allam-2-7b',
        ],
        priority: 1,
      ),
      AiProviderConfig(
        id: 'openrouter',
        name: 'OpenRouter',
        endpoint: 'https://openrouter.ai/api/v1/chat/completions',
        apiKey: Env.openrouterApiKey,
        candidateModels: const [
          'nvidia/nemotron-3.5-lightning:free',
          'google/gemma-4-31b-it:free',
          'nvidia/nemotron-3-nano-omni-30b-a3b-reasoning:free',
          'liquid/lfm-2.5-2.6b:free',
        ],
        priority: 2,
      ),
      AiProviderConfig(
        id: 'gemini',
        name: 'Google Gemini',
        endpoint: 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
        apiKey: Env.geminiApiKey,
        candidateModels: const [
          'gemini-3.5-flash-lite',
          'gemini-3.8-flash',
          'gemini-2.5-flash',
        ],
        priority: 3,
      ),
    ];

    return all.where((p) => p.isValid).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
}


