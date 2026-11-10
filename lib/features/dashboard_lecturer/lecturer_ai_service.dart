import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../shared/models/student_model.dart';
import '../netbot/netbot_providers.dart';

class LecturerMaterialTranslation {
  final String title;
  final String summary;
  final String description;
  final String providerName;

  const LecturerMaterialTranslation({
    required this.title,
    required this.summary,
    required this.description,
    required this.providerName,
  });
}

class LecturerAssessmentTranslation {
  final String title;
  final String description;
  final String instructions;
  final String providerName;

  const LecturerAssessmentTranslation({
    required this.title,
    required this.description,
    required this.instructions,
    required this.providerName,
  });
}

class LecturerQuestionTranslation {
  final String questionText;
  final String optionA;
  final String optionB;
  final String optionC;
  final String optionD;
  final String providerName;

  const LecturerQuestionTranslation({
    required this.questionText,
    required this.optionA,
    required this.optionB,
    required this.optionC,
    required this.optionD,
    required this.providerName,
  });
}

class LecturerScoreAnalyticsResult {
  final String markdownInsight;
  final String providerName;

  const LecturerScoreAnalyticsResult({
    required this.markdownInsight,
    required this.providerName,
  });
}

class LecturerAiService {
  LecturerAiService._();

  /// Executes a single-turn AI completion across the resilient multi-provider
  /// gateway (Groq -> OpenRouter -> SambaNova -> Google Gemini).
  static Future<({String content, String providerName})> complete({
    required String systemPrompt,
    required String userPrompt,
    double temperature = 0.3,
    http.Client? httpClient,
  }) async {
    final providers = NetBotProviders.getAvailableProviders();
    if (providers.isEmpty) {
      throw Exception('AI API keys are not configured.');
    }

    final client = httpClient ?? http.Client();
    final shouldCloseClient = httpClient == null;
    Object? lastError;

    try {
      for (final provider in providers) {
        for (final model in provider.candidateModels) {
          try {
            if (provider.id == 'gemini' && provider.apiKey.startsWith('AQ.')) {
              // Native Gemini REST API call for AQ... keys
              final url = Uri.parse(
                'https://generativelanguage.googleapis.com/v1beta/models/$model:generateContent?key=${provider.apiKey}',
              );
              final response = await client
                  .post(
                    url,
                    headers: {'Content-Type': 'application/json'},
                    body: jsonEncode({
                      'systemInstruction': {
                        'parts': [
                          {'text': systemPrompt}
                        ]
                      },
                      'contents': [
                        {
                          'role': 'user',
                          'parts': [
                            {'text': userPrompt}
                          ]
                        }
                      ],
                      'generationConfig': {
                        'temperature': temperature,
                      },
                    }),
                  )
                  .timeout(const Duration(seconds: 20));

              if (response.statusCode == 200) {
                final decodedBody =
                    utf8.decode(response.bodyBytes, allowMalformed: true);
                final data = jsonDecode(decodedBody) as Map<String, dynamic>;
                final candidates = data['candidates'] as List<dynamic>?;
                if (candidates != null && candidates.isNotEmpty) {
                  final content =
                      candidates[0]['content'] as Map<String, dynamic>?;
                  final parts = content?['parts'] as List<dynamic>?;
                  final text = parts?[0]['text'] as String?;
                  if (text != null && text.trim().isNotEmpty) {
                    return (
                      content: text.trim(),
                      providerName: '${provider.name} ($model)'
                    );
                  }
                }
              } else {
                lastError = 'Gemini HTTP ${response.statusCode}: ${response.body}';
                continue;
              }
            } else {
              // OpenAI-compatible chat completions endpoint
              final headers = <String, String>{
                'Authorization': 'Bearer ${provider.apiKey}',
                'Content-Type': 'application/json',
                'User-Agent': 'NetLearn/1.0 (Android)',
              };
              if (provider.id == 'openrouter') {
                headers['HTTP-Referer'] = 'https://netlearn.app';
                headers['X-Title'] = 'NetLearn Lecturer AI';
              }

              final response = await client
                  .post(
                    Uri.parse(provider.endpoint),
                    headers: headers,
                    body: jsonEncode({
                      'model': model,
                      'messages': [
                        {'role': 'system', 'content': systemPrompt},
                        {'role': 'user', 'content': userPrompt},
                      ],
                      'temperature': temperature,
                      'stream': false,
                    }),
                  )
                  .timeout(const Duration(seconds: 20));

              if (response.statusCode == 200) {
                final decodedBody =
                    utf8.decode(response.bodyBytes, allowMalformed: true);
                final data = jsonDecode(decodedBody) as Map<String, dynamic>;
                final choices = data['choices'] as List<dynamic>?;
                if (choices != null && choices.isNotEmpty) {
                  final message =
                      choices[0]['message'] as Map<String, dynamic>?;
                  final text = message?['content'] as String?;
                  if (text != null && text.trim().isNotEmpty) {
                    return (
                      content: text.trim(),
                      providerName: '${provider.name} ($model)'
                    );
                  }
                }
              } else {
                debugPrint(
                  '[LecturerAI] ${provider.name} ($model) HTTP ${response.statusCode}: ${response.body}',
                );
                lastError = 'HTTP ${response.statusCode}';
                continue;
              }
            }
          } catch (e) {
            debugPrint('[LecturerAI] Error on ${provider.name} ($model): $e');
            lastError = e;
          }
        }
      }
    } finally {
      if (shouldCloseClient) {
        client.close();
      }
    }

    throw Exception('All AI providers failed. Last error: $lastError');
  }

  /// Extracts a JSON object from AI output even if wrapped in ```json ... ``` blocks.
  static Map<String, dynamic> extractJsonMap(String raw) {
    var cleaned = raw.trim();
    final codeBlockRegex = RegExp(r'```(?:json)?\s*([\s\S]*?)\s*```');
    final match = codeBlockRegex.firstMatch(cleaned);
    if (match != null && match.group(1) != null) {
      cleaned = match.group(1)!.trim();
    } else {
      final firstBrace = cleaned.indexOf('{');
      final lastBrace = cleaned.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        cleaned = cleaned.substring(firstBrace, lastBrace + 1);
      }
    }
    return jsonDecode(cleaned) as Map<String, dynamic>;
  }

  /// Translates learning material fields (title, summary, description/content)
  /// between Indonesian ('id') and English ('en').
  static Future<LecturerMaterialTranslation> translateMaterial({
    required String title,
    required String summary,
    required String description,
    required String targetLanguageCode, // 'en' or 'id'
    http.Client? httpClient,
  }) async {
    final targetLangName =
        targetLanguageCode == 'en' ? 'English' : 'Indonesian (Bahasa Indonesia)';
    final sourceLangName =
        targetLanguageCode == 'en' ? 'Indonesian' : 'English';

    const systemPrompt =
        'You are an expert Computer Networking academic translator. '
        'Translate the given learning material fields accurately while preserving '
        'standard networking terminology (e.g., OSI Layer, Subnet Mask, Gateway, VLAN, Routing, TCP/IP). '
        'Return ONLY a valid JSON object with keys: "title", "summary", "description". '
        'Do not add extra commentary.';

    final userPrompt = jsonEncode({
      'task': 'Translate from $sourceLangName to $targetLangName',
      'source': {
        'title': title,
        'summary': summary,
        'description': description,
      },
    });

    final result = await complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.2,
      httpClient: httpClient,
    );

    final map = extractJsonMap(result.content);
    return LecturerMaterialTranslation(
      title: (map['title'] ?? '').toString().trim(),
      summary: (map['summary'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      providerName: result.providerName,
    );
  }

  /// Translates assessment task fields (title, description, instructions)
  /// between Indonesian ('id') and English ('en').
  static Future<LecturerAssessmentTranslation> translateAssessment({
    required String title,
    required String description,
    required String instructions,
    required String targetLanguageCode, // 'en' or 'id'
    http.Client? httpClient,
  }) async {
    final targetLangName =
        targetLanguageCode == 'en' ? 'English' : 'Indonesian (Bahasa Indonesia)';
    final sourceLangName =
        targetLanguageCode == 'en' ? 'Indonesian' : 'English';

    const systemPrompt =
        'You are an expert Computer Networking academic translator. '
        'Translate the assessment task title, description, and instructions accurately. '
        'Preserve standard computer networking terms (e.g. Subnetting, OSI Model, Routing, VLAN, IP Address). '
        'Return ONLY a valid JSON object with keys: "title", "description", "instructions". '
        'Do not add markdown code blocks or extra commentary.';

    final userPrompt = jsonEncode({
      'task': 'Translate assessment from $sourceLangName to $targetLangName',
      'source': {
        'title': title,
        'description': description,
        'instructions': instructions,
      },
    });

    final result = await complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.2,
      httpClient: httpClient,
    );

    final map = extractJsonMap(result.content);
    return LecturerAssessmentTranslation(
      title: (map['title'] ?? '').toString().trim(),
      description: (map['description'] ?? '').toString().trim(),
      instructions: (map['instructions'] ?? '').toString().trim(),
      providerName: result.providerName,
    );
  }

  /// Translates an assessment question and its 4 options (A, B, C, D)
  /// between Indonesian ('id') and English ('en').
  static Future<LecturerQuestionTranslation> translateQuestion({
    required String questionText,
    required String optionA,
    required String optionB,
    required String optionC,
    required String optionD,
    required String targetLanguageCode, // 'en' or 'id'
    http.Client? httpClient,
  }) async {
    final targetLangName =
        targetLanguageCode == 'en' ? 'English' : 'Indonesian (Bahasa Indonesia)';
    final sourceLangName =
        targetLanguageCode == 'en' ? 'Indonesian' : 'English';

    const systemPrompt =
        'You are an expert Computer Networking assessment translator. '
        'Translate the multiple-choice question and its four options (A, B, C, D) accurately. '
        'Keep technical networking terms (such as IPv4, CIDR, ARP, ICMP, Switch, Router) natural and accurate. '
        'Return ONLY a valid JSON object with keys: "questionText", "optionA", "optionB", "optionC", "optionD".';

    final userPrompt = jsonEncode({
      'task': 'Translate question from $sourceLangName to $targetLangName',
      'source': {
        'questionText': questionText,
        'optionA': optionA,
        'optionB': optionB,
        'optionC': optionC,
        'optionD': optionD,
      },
    });

    final result = await complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.2,
      httpClient: httpClient,
    );

    final map = extractJsonMap(result.content);
    return LecturerQuestionTranslation(
      questionText: (map['questionText'] ?? '').toString().trim(),
      optionA: (map['optionA'] ?? '').toString().trim(),
      optionB: (map['optionB'] ?? '').toString().trim(),
      optionC: (map['optionC'] ?? '').toString().trim(),
      optionD: (map['optionD'] ?? '').toString().trim(),
      providerName: result.providerName,
    );
  }

  /// Generates pedagogical analytics and actionable recommendations based on
  /// class pretest & posttest scores.
  static Future<LecturerScoreAnalyticsResult> analyzeClassScores({
    required List<StudentModel> students,
    required String languageCode,
    http.Client? httpClient,
  }) async {
    final isId = languageCode == 'id';

    final preScores =
        students.map((s) => s.pretestScore).whereType<double>().toList();
    final postScores =
        students.map((s) => s.posttestScore).whereType<double>().toList();

    final avgPre = preScores.isEmpty
        ? 0.0
        : preScores.reduce((a, b) => a + b) / preScores.length;
    final avgPost = postScores.isEmpty
        ? 0.0
        : postScores.reduce((a, b) => a + b) / postScores.length;

    final remedialStudents = students
        .where((s) =>
            (s.posttestScore != null && s.posttestScore! < 70) ||
            (s.posttestScore == null &&
                s.pretestScore != null &&
                s.pretestScore! < 60))
        .map((s) =>
            '${s.name} (Pre: ${s.pretestScore?.toStringAsFixed(0) ?? "-"}, Post: ${s.posttestScore?.toStringAsFixed(0) ?? "-"})')
        .toList();

    final topStudents = students
        .where((s) => (s.posttestScore ?? 0) >= 85)
        .map((s) =>
            '${s.name} (Post: ${s.posttestScore?.toStringAsFixed(0) ?? "-"})')
        .toList();

    final systemPrompt = isId
        ? 'Anda adalah Konsultan Pedagogis & Analis Akademik AI untuk mata kuliah Jaringan Komputer di NetLearn. '
            'Analisis data performa Pretest dan Posttest kelas berikut dan berikan evaluasi serta rekomendasi tindak lanjut bagi dosen.\n\n'
            'PANDUAN PENULISAN (SANGAT PENTING):\n'
            '1. TULISKAN DALAM TEKS BIASA YANG RAPI DAN TENANG. JANGAN menggunakan tanda bintang ganda (**) berlebihan pada setiap kalimat atau kata. Gunakan teks normal seperti laporan resmi.\n'
            '2. DILARANG KERAS MEMBUAT TABEL TEKS (seperti menggunakan simbol |---|). Seluruh grafik dan tabel angka sudah ditampilkan dalam bentuk visual grafis interaktif di aplikasi. Tugas Anda hanya memberikan narasi penjelasan dan saran pedagogis.\n'
            '3. Gunakan poin-poin sederhana dengan bullet (•) untuk memisahkan ide.\n\n'
            'Struktur laporan:\n'
            '• Evaluasi Performa Kelas: Ulas secara naratif kenaikan rata-rata nilai dan tingkat kelulusan kelas.\n'
            '• Perhatian Khusus: Sebutkan nama-nama mahasiswa yang membutuhkan bantuan tambahan atau belum tuntas.\n'
            '• Rekomendasi Pengajaran: 3 langkah nyata yang dapat dilakukan dosen pada pertemuan berikutnya.'
        : 'You are an AI Pedagogical Consultant & Academic Analyst for a Computer Networking course in NetLearn. '
            'Analyze the following class Pretest and Posttest performance data and provide evaluations and recommendations for the lecturer.\n\n'
            'WRITING GUIDELINES (CRITICAL):\n'
            '1. WRITE IN CLEAN NORMAL TEXT. DO NOT use excessive double asterisks (**) on every sentence or word. Use normal, professional prose like an official academic report.\n'
            '2. STRICTLY DO NOT GENERATE TEXT-BASED MARKDOWN TABLES (such as using |---| symbols). All charts and tables are already rendered visually by the app. Your job is purely narrative insights and pedagogical recommendations.\n'
            '3. Use simple bullet points (•) for distinct ideas.\n\n'
            'Report Structure:\n'
            '• Class Performance Evaluation: Narratively discuss learning gains and class pass rate.\n'
            '• Students Needing Attention: Mention students requiring mentoring or remedial support.\n'
            '• Actionable Teaching Recommendations: 3 concrete steps for the lecturer in upcoming sessions.';

    final summaryPayload = {
      'totalStudents': students.length,
      'pretestCompleted': preScores.length,
      'posttestCompleted': postScores.length,
      'averagePretest': double.parse(avgPre.toStringAsFixed(1)),
      'averagePosttest': double.parse(avgPost.toStringAsFixed(1)),
      'learningGain': double.parse((avgPost - avgPre).toStringAsFixed(1)),
      'studentsNeedingRemedial': remedialStudents.take(10).toList(),
      'topPerformers': topStudents.take(5).toList(),
    };

    final result = await complete(
      systemPrompt: systemPrompt,
      userPrompt: jsonEncode(summaryPayload),
      temperature: 0.4,
      httpClient: httpClient,
    );

    return LecturerScoreAnalyticsResult(
      markdownInsight: sanitizeAiInsight(result.content),
      providerName: result.providerName,
    );
  }

  /// Cleans up raw AI output by removing unnecessary markdown tables,
  /// excessive asterisks (**), and formatting cleanly for mobile readability.
  static String sanitizeAiInsight(String raw) {
    var text = raw.trim();

    // 1. Remove markdown table divider rows like |---|---|
    text = text.replaceAll(RegExp(r'\|(?:\s*-+\s*\|)+'), '');

    // 2. Convert table data rows like | col1 | col2 | into bullet points
    text = text.splitMapJoin(
      RegExp(r'^\|(.+)\|$', multiLine: true),
      onMatch: (m) {
        final cells = m
            .group(1)!
            .split('|')
            .map((c) => c.trim())
            .where((c) => c.isNotEmpty)
            .toList();
        if (cells.isEmpty) return '';
        return '• ${cells.join(" — ")}';
      },
      onNonMatch: (n) => n,
    );

    // 3. Remove excessive bold double asterisks (**) so text looks clean and normal
    text = text.replaceAll('**', '');

    // 4. Remove leading/trailing hash headings (### Heading -> Heading)
    text = text.replaceAll(RegExp(r'^#{1,6}\s*', multiLine: true), '');

    // 5. Clean up redundant empty lines
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');

    return text.trim();
  }

  /// Generates individual student diagnostic insight.
  static Future<LecturerScoreAnalyticsResult> analyzeIndividualStudent({
    required StudentModel student,
    required String languageCode,
    http.Client? httpClient,
  }) async {
    final isId = languageCode == 'id';
    final systemPrompt = isId
        ? 'Anda adalah Asisten Dosen AI NetLearn. Berikan evaluasi singkat dan saran pembimbingan personal untuk mahasiswa berikut berdasarkan nilai Pretest dan Posttest Jaringan Komputer mereka.\n'
            'PANDUAN: Tuliskan dalam teks biasa yang bersih, sopan, dan jelas. Hindari penggunaan bintang ganda (**) berlebihan pada kata-kata. Jangan buat tabel teks.'
        : 'You are a NetLearn AI Teaching Assistant. Provide a brief evaluation and personal mentoring advice for the following student based on their Computer Networking Pretest and Posttest scores.\n'
            'GUIDELINES: Write in clean, professional plain text. Avoid excessive double asterisks (**) on words. Do not generate text tables.';

    final userPrompt = jsonEncode({
      'name': student.name,
      'nim': student.identityNumber ?? '-',
      'pretestScore': student.pretestScore,
      'posttestScore': student.posttestScore,
    });

    final result = await complete(
      systemPrompt: systemPrompt,
      userPrompt: userPrompt,
      temperature: 0.4,
      httpClient: httpClient,
    );

    return LecturerScoreAnalyticsResult(
      markdownInsight: sanitizeAiInsight(result.content),
      providerName: result.providerName,
    );
  }
}
