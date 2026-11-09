import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'netbot_models.dart';
import 'netbot_providers.dart';

class NetBotException implements Exception {
  final String message;
  final bool isApiKeyMissing;
  final bool isRateLimit;

  const NetBotException(
    this.message, {
    this.isApiKeyMissing = false,
    this.isRateLimit = false,
  });

  @override
  String toString() => message;
}

class NetBotService {
  NetBotService._();

  /// Creates tailored system instructions based on language and learning context.
  static String buildSystemPrompt(NetBotContext context) {
    final isId = context.languageCode == 'id';
    final buffer = StringBuffer();

    if (isId) {
      buffer.writeln(
        'Anda adalah NetBot, asisten dan tutor AI cerdas, ramah, dan edukatif '
        'untuk mata kuliah Jaringan Komputer di aplikasi NetLearn.',
      );
      buffer.writeln(
        'Tugas Anda adalah membantu mahasiswa memahami konsep jaringan komputer secara interaktif, runtut, dan mudah dipahami.',
      );

      if (context.moduleTitle != null && context.moduleTitle!.trim().isNotEmpty) {
        buffer.writeln('Modul pembelajaran aktif: ${context.moduleTitle}');
      }
      if (context.materialTitle != null && context.materialTitle!.trim().isNotEmpty) {
        buffer.writeln('Materi yang sedang dibaca mahasiswa: ${context.materialTitle}');
      }
      if (context.materialBodySnippet != null && context.materialBodySnippet!.trim().isNotEmpty) {
        buffer.writeln('Ringkasan/Kutipan isi materi:');
        buffer.writeln(context.materialBodySnippet);
      }
      if (context.topologySnippet != null && context.topologySnippet!.trim().isNotEmpty) {
        buffer.writeln('Kondisi Topologi Virtual Lab Mahasiswa:');
        buffer.writeln(context.topologySnippet);
      }

      buffer.writeln('\nAturan dan pedoman menjawab:');
      buffer.writeln('1. Berikan jawaban yang tepat, to-the-point, dan berbobot akademis.');
      buffer.writeln('2. Jika menjelaskan konsep rumit (misal OSI Model, TCP Handshake, Subnetting), gunakan analogi dunia nyata.');
      buffer.writeln('3. Untuk perhitungan IP Address atau Subnetting, tuliskan langkah perhitungan biner/rumus secara terstruktur dan mudah diikuti.');
      buffer.writeln('4. Untuk konfigurasi perangkat (Router, Switch, PC), sertakan sintaks perintah terminal dalam blok kode Markdown.');
      buffer.writeln('5. Gunakan Bahasa Indonesia yang santun, memotivasi, dan bersemangat membimbing mahasiswa.');
      buffer.writeln('6. Jangan berhalusinasi atau memberikan informasi teknis jaringan yang menyesatkan.');
    } else {
      buffer.writeln(
        'You are NetBot, an intelligent, friendly, and educational AI tutor '
        'for Computer Networking coursework in the NetLearn application.',
      );
      buffer.writeln(
        'Your mission is to help students master computer networking concepts clearly, interactively, and step-by-step.',
      );

      if (context.moduleTitle != null && context.moduleTitle!.trim().isNotEmpty) {
        buffer.writeln('Active module: ${context.moduleTitle}');
      }
      if (context.materialTitle != null && context.materialTitle!.trim().isNotEmpty) {
        buffer.writeln('Current material being read: ${context.materialTitle}');
      }
      if (context.materialBodySnippet != null && context.materialBodySnippet!.trim().isNotEmpty) {
        buffer.writeln('Content snippet:');
        buffer.writeln(context.materialBodySnippet);
      }
      if (context.topologySnippet != null && context.topologySnippet!.trim().isNotEmpty) {
        buffer.writeln('Virtual Lab Topology State:');
        buffer.writeln(context.topologySnippet);
      }

      buffer.writeln('\nGuidelines:');
      buffer.writeln('1. Provide precise, relevant, and conceptually sound answers.');
      buffer.writeln('2. Use helpful analogies for complex concepts (e.g. OSI model, TCP 3-way handshake, routing).');
      buffer.writeln('3. For IP and subnetting calculations, show step-by-step workings.');
      buffer.writeln('4. When suggesting CLI commands (Cisco IOS, Linux, Mikrotik), use markdown code blocks.');
      buffer.writeln('5. Maintain a friendly, supportive, and encouraging educational tone in English.');
    }

    return buffer.toString();
  }

  /// Sends a chat message with multi-provider failover.
  /// Automatically tries available providers (Groq -> SambaNova -> OpenRouter -> Gemini)
  /// until one succeeds, ensuring high resilience during concurrent class usage.
  static Stream<String> sendMessageStream({
    required String userMessage,
    required NetBotContext context,
    List<NetBotMessage> history = const [],
    void Function(String providerName)? onProviderConnected,
    http.Client? httpClient,
  }) async* {
    final providers = NetBotProviders.getAvailableProviders();

    if (providers.isEmpty) {
      yield context.languageCode == 'id'
          ? 'Kunci API AI belum dikonfigurasi di sistem. Silakan hubungi administrator.'
          : 'AI API keys are not configured in the system. Please contact the administrator.';
      return;
    }

    final systemPrompt = buildSystemPrompt(context);

    // Build standard OpenAI-compatible messages array
    final messages = <Map<String, String>>[
      {'role': 'system', 'content': systemPrompt},
    ];

    for (final msg in history) {
      if (msg.isError || msg.text.trim().isEmpty) continue;
      messages.add({
        'role': msg.isUser ? 'user' : 'assistant',
        'content': msg.text,
      });
    }

    messages.add({'role': 'user', 'content': userMessage});

    final client = httpClient ?? http.Client();
    final shouldCloseClient = httpClient == null;

    var yieldedAny = false;
    Object? lastError;

    try {
      // Loop through available providers in priority order
      for (final provider in providers) {
        for (final model in provider.candidateModels) {
          try {
            final request = http.Request('POST', Uri.parse(provider.endpoint));
            final headers = <String, String>{
              'Authorization': 'Bearer ${provider.apiKey}',
              'Content-Type': 'application/json',
              'User-Agent': 'NetLearn/1.0 (Android)',
            };

            // OpenRouter specific optional headers
            if (provider.id == 'openrouter') {
              headers['HTTP-Referer'] = 'https://netlearn.app';
              headers['X-Title'] = 'NetLearn AI Tutor';
            }

            request.headers.addAll(headers);
            request.body = jsonEncode({
              'model': model,
              'messages': messages,
              'temperature': 0.6,
              'stream': true,
            });

            final streamedResponse = await client.send(request).timeout(
              const Duration(seconds: 12),
            );

            if (streamedResponse.statusCode != 200) {
              final errorBody = await streamedResponse.stream.bytesToString();
              debugPrint(
                '[NetBot] Provider ${provider.name} ($model) returned ${streamedResponse.statusCode}: $errorBody',
              );
              lastError = 'HTTP ${streamedResponse.statusCode}: $errorBody';
              // Failover to next model or next provider
              continue;
            }

            // Connection established with this provider!
            onProviderConnected?.call(provider.name);

            // Read SSE stream
            await for (final line in streamedResponse.stream
                .transform(utf8.decoder)
                .transform(const LineSplitter())) {
              final trimmed = line.trim();
              if (trimmed.isEmpty) continue;
              if (trimmed == 'data: [DONE]') break;

              if (trimmed.startsWith('data: ')) {
                final jsonStr = trimmed.substring(6).trim();
                try {
                  final dynamic decoded = jsonDecode(jsonStr);
                  if (decoded is Map<String, dynamic>) {
                    final choices = decoded['choices'] as List<dynamic>?;
                    if (choices != null && choices.isNotEmpty) {
                      final delta = choices[0]['delta'] as Map<String, dynamic>?;
                      final chunk = delta?['content'] as String?;
                      if (chunk != null && chunk.isNotEmpty) {
                        yield chunk;
                        yieldedAny = true;
                      }
                    }
                  }
                } catch (_) {
                  // Silently ignore malformed SSE lines
                }
              }
            }

            if (yieldedAny) {
              // Successfully delivered full streaming response!
              return;
            }
          } catch (e) {
            debugPrint('[NetBot] Error connecting to ${provider.name} ($model): $e');
            lastError = e;
            // Continue failover loop
          }
        }
      }
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }

    // If we reach here and nothing was yielded, all providers failed
    if (!yieldedAny) {
      debugPrint('[NetBot] All AI providers exhausted. Last error: $lastError');
      yield context.languageCode == 'id'
          ? 'Mohon maaf, server AI sedang mengalami antrean tinggi. Silakan coba kirim ulang pertanyaan Anda dalam beberapa saat.'
          : 'Sorry, AI servers are experiencing high traffic. Please try resending your message in a moment.';
    }
  }
}

