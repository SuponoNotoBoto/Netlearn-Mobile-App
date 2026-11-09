import '../../core/constants/env.dart';
import 'netbot_models.dart';

class NetBotProviders {
  NetBotProviders._();

  /// Returns the ordered list of AI providers configured in the system.
  /// Only providers with non-empty API keys are returned.
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
        id: 'sambanova',
        name: 'SambaNova Cloud',
        endpoint: 'https://api.sambanova.ai/v1/chat/completions',
        apiKey: Env.sambanovaApiKey,
        candidateModels: const [
          'Meta-Llama-3.3-70B-Instruct',
        ],
        priority: 3,
      ),
      AiProviderConfig(
        id: 'gemini',
        name: 'Google Gemini',
        endpoint: 'https://generativelanguage.googleapis.com/v1beta/openai/chat/completions',
        apiKey: Env.geminiApiKey,
        candidateModels: const [
          'gemini-1.5-flash',
          'gemini-2.0-flash',
        ],
        priority: 4,
      ),
    ];

    return all.where((p) => p.isValid).toList()
      ..sort((a, b) => a.priority.compareTo(b.priority));
  }
}

