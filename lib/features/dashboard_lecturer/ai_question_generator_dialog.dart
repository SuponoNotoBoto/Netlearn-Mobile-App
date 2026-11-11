import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/env.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/widgets/nl_button.dart';
import 'lecturer_assessments_controller.dart';

/// Dialog allowing lecturers to generate draft multiple-choice quiz questions
/// powered by Groq AI API.
class AiQuestionGeneratorDialog extends ConsumerStatefulWidget {
  final String quizId;
  final int currentQuestionCount;

  const AiQuestionGeneratorDialog({
    super.key,
    required this.quizId,
    required this.currentQuestionCount,
  });

  static Future<void> show(
    BuildContext context, {
    required String quizId,
    required int currentQuestionCount,
  }) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AiQuestionGeneratorDialog(
        quizId: quizId,
        currentQuestionCount: currentQuestionCount,
      ),
    );
  }

  @override
  ConsumerState<AiQuestionGeneratorDialog> createState() =>
      _AiQuestionGeneratorDialogState();
}

class _GeneratedQuestionDraft {
  final String questionId;
  final String questionEn;
  final String optionAId;
  final String optionBId;
  final String optionCId;
  final String optionDId;
  final String optionAEn;
  final String optionBEn;
  final String optionCEn;
  final String optionDEn;
  final String correctAnswer;
  final String explanation;
  bool isSelected;

  _GeneratedQuestionDraft({
    required this.questionId,
    required this.questionEn,
    required this.optionAId,
    required this.optionBId,
    required this.optionCId,
    required this.optionDId,
    required this.optionAEn,
    required this.optionBEn,
    required this.optionCEn,
    required this.optionDEn,
    required this.correctAnswer,
    required this.explanation,
    this.isSelected = true,
  });

  factory _GeneratedQuestionDraft.fromJson(Map<String, dynamic> json) {
    String getVal(List<String> keys) {
      for (final k in keys) {
        if (json[k] != null && json[k].toString().trim().isNotEmpty) {
          return json[k].toString().trim();
        }
      }
      return '';
    }

    final qId = getVal(['question_id', 'question_indonesian', 'question_indo', 'pertanyaan_id', 'pertanyaan']);
    final qEn = getVal(['question_en', 'question_english', 'pertanyaan_en', 'question']);

    final optAId = getVal(['option_a_id', 'option_a_indonesian', 'pilihan_a_id', 'option_a']);
    final optBId = getVal(['option_b_id', 'option_b_indonesian', 'pilihan_b_id', 'option_b']);
    final optCId = getVal(['option_c_id', 'option_c_indonesian', 'pilihan_c_id', 'option_c']);
    final optDId = getVal(['option_d_id', 'option_d_indonesian', 'pilihan_d_id', 'option_d']);

    final optAEn = getVal(['option_a_en', 'option_a_english', 'pilihan_a_en', 'option_a']);
    final optBEn = getVal(['option_b_en', 'option_b_english', 'pilihan_b_en', 'option_b']);
    final optCEn = getVal(['option_c_en', 'option_c_english', 'pilihan_c_en', 'option_c']);
    final optDEn = getVal(['option_d_en', 'option_d_english', 'pilihan_d_en', 'option_d']);

    final ans = getVal(['correct_answer', 'jawaban_benar', 'answer', 'key']).toUpperCase();
    final expl = getVal(['explanation', 'penjelasan', 'pembahasan']);

    return _GeneratedQuestionDraft(
      questionId: qId.isNotEmpty ? qId : qEn,
      questionEn: qEn.isNotEmpty ? qEn : qId,
      optionAId: optAId.isNotEmpty ? optAId : optAEn,
      optionBId: optBId.isNotEmpty ? optBId : optBEn,
      optionCId: optCId.isNotEmpty ? optCId : optCEn,
      optionDId: optDId.isNotEmpty ? optDId : optDEn,
      optionAEn: optAEn.isNotEmpty ? optAEn : optAId,
      optionBEn: optBEn.isNotEmpty ? optBEn : optBId,
      optionCEn: optCEn.isNotEmpty ? optCEn : optCId,
      optionDEn: optDEn.isNotEmpty ? optDEn : optDId,
      correctAnswer: RegExp(r'^[A-D]$').hasMatch(ans) ? ans : 'A',
      explanation: expl,
      isSelected: true,
    );
  }
}

class _AiQuestionGeneratorDialogState
    extends ConsumerState<AiQuestionGeneratorDialog> {
  final _topicController = TextEditingController(text: 'Subnetting IPv4 & VLSM');
  int _questionCount = 3;
  String _difficulty = 'Menengah';
  bool _isGenerating = false;
  bool _isInserting = false;
  String? _errorMessage;

  List<_GeneratedQuestionDraft> _drafts = [];

  final List<String> _suggestedTopics = [
    'Subnetting IPv4 & VLSM',
    'OSI Layer & TCP/IP Protocol',
    'Routing Statis & Dinamis',
    'Switching & VLAN',
    'Pengalamatan IP & DHCP',
    'Keamanan Jaringan & Firewall',
  ];

  @override
  void dispose() {
    _topicController.dispose();
    super.dispose();
  }

  Future<String?> _getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('netbot_user_api_key')?.trim();
    if (saved != null && saved.isNotEmpty) {
      return saved;
    }
    if (Env.groqApiKey.isNotEmpty) {
      return Env.groqApiKey;
    }
    return null;
  }

  Future<void> _generateQuestions() async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final topic = _topicController.text.trim();
    if (topic.isEmpty) {
      setState(() => _errorMessage = isId ? 'Topik tidak boleh kosong' : 'Topic cannot be empty');
      return;
    }

    final apiKey = await _getApiKey();
    if (apiKey == null || apiKey.isEmpty) {
      setState(() => _errorMessage = isId ? 'API Key Groq tidak ditemukan' : 'Groq API Key not found');
      return;
    }

    setState(() {
      _isGenerating = true;
      _errorMessage = null;
      _drafts = [];
    });

    try {
      final prompt = '''
Anda adalah pakar jaringan komputer dan dosen universitas.
Buatlah $_questionCount soal pilihan ganda tentang topik: "$topic" dengan tingkat kesulitan "$_difficulty".
Setiap soal harus dwibahasa (Indonesian & English) dan memiliki 4 opsi jawaban (A, B, C, D) serta kunci jawaban yang pasti.

Format respon HARUS berupa array JSON murni (JSON array of objects) tanpa awalan atau akhiran penjelasan teks lain:
[
  {
    "question_id": "Pertanyaan dalam bahasa Indonesia",
    "question_en": "Question in English",
    "option_a_id": "Pilihan A (Indonesia)",
    "option_b_id": "Pilihan B (Indonesia)",
    "option_c_id": "Pilihan C (Indonesia)",
    "option_d_id": "Pilihan D (Indonesia)",
    "option_a_en": "Option A (English)",
    "option_b_en": "Option B (English)",
    "option_c_en": "Option C (English)",
    "option_d_en": "Option D (English)",
    "correct_answer": "A",
    "explanation": "Penjelasan singkat jawaban yang benar"
  }
]
''';

      http.Response? response;
      String? lastError;

      const candidateModels = [
        'openai/gpt-oss-20b',
        'openai/gpt-oss-120b',
        'qwen/qwen3.8-27b',
      ];

      for (final model in candidateModels) {
        try {
          final res = await http.post(
            Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': model,
              'messages': [
                {
                  'role': 'system',
                  'content': 'You are a strict JSON generator. Return only raw JSON arrays without markdown blocks or explanation.',
                },
                {
                  'role': 'user',
                  'content': prompt,
                },
              ],
              'temperature': 0.6,
              'max_tokens': 3000,
            }),
          );

          if (res.statusCode == 200) {
            response = res;
            break;
          } else {
            lastError = 'API error (${res.statusCode}): ${res.body}';
            // Continue fallback if model unavailable or rate limit
            if (res.statusCode == 404 || res.statusCode == 503 || res.statusCode == 429) {
              continue;
            } else {
              break;
            }
          }
        } catch (e) {
          lastError = e.toString();
        }
      }

      if (response == null || response.statusCode != 200) {
        throw Exception(lastError ?? (isId ? 'Respon kosong atau gagal dari Groq API' : 'Empty or failed response from Groq API'));
      }

      final body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      final choices = body['choices'] as List<dynamic>?;
      if (choices == null || choices.isEmpty) {
        throw Exception(isId ? 'Respon kosong dari Groq API' : 'Empty response from Groq API');
      }

      final content = choices[0]['message']['content'].toString().trim();
      
      // Extract JSON array
      String cleaned = content;
      if (cleaned.contains('```json')) {
        cleaned = cleaned.split('```json')[1].split('```')[0].trim();
      } else if (cleaned.contains('```')) {
        cleaned = cleaned.split('```')[1].split('```')[0].trim();
      }

      final startIndex = cleaned.indexOf('[');
      final endIndex = cleaned.lastIndexOf(']');
      List<dynamic> parsed;
      if (startIndex != -1 && endIndex != -1 && endIndex > startIndex) {
        cleaned = cleaned.substring(startIndex, endIndex + 1);
        parsed = jsonDecode(cleaned) as List<dynamic>;
      } else {
        final decoded = jsonDecode(cleaned);
        if (decoded is List) {
          parsed = decoded;
        } else if (decoded is Map<String, dynamic>) {
          final firstList = decoded.values.firstWhere((v) => v is List, orElse: () => null);
          if (firstList != null && firstList is List) {
            parsed = firstList;
          } else {
            throw Exception('Invalid JSON structure: expected array');
          }
        } else {
          throw Exception('Invalid JSON structure');
        }
      }

      final results = parsed
          .map((item) => _GeneratedQuestionDraft.fromJson(item as Map<String, dynamic>))
          .toList();

      if (mounted) {
        HapticFeedback.mediumImpact();
        setState(() {
          _drafts = results;
          _isGenerating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        final isId = Localizations.localeOf(context).languageCode == 'id';
        setState(() {
          _errorMessage = isId ? 'Gagal membuat soal: $e' : 'Failed to generate questions: $e';
          _isGenerating = false;
        });
      }
    }
  }

  Future<void> _insertSelectedQuestions() async {
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final selected = _drafts.where((d) => d.isSelected).toList();
    if (selected.isEmpty) {
      setState(() => _errorMessage = isId ? 'Pilih minimal satu soal untuk ditambahkan' : 'Select at least one question to add');
      return;
    }

    setState(() {
      _isInserting = true;
      _errorMessage = null;
    });

    try {
      int nextOrder = widget.currentQuestionCount;
      for (final item in selected) {
        final q = LecturerQuestion(
          id: '',
          quizId: widget.quizId,
          orderIndex: nextOrder++,
          questionText: item.questionId.isNotEmpty ? item.questionId : item.questionEn,
          questionTextEn: item.questionEn,
          questionTextId: item.questionId,
          optionA: item.optionAId.isNotEmpty ? item.optionAId : item.optionAEn,
          optionB: item.optionBId.isNotEmpty ? item.optionBId : item.optionBEn,
          optionC: item.optionCId.isNotEmpty ? item.optionCId : item.optionCEn,
          optionD: item.optionDId.isNotEmpty ? item.optionDId : item.optionDEn,
          optionAEn: item.optionAEn,
          optionBEn: item.optionBEn,
          optionCEn: item.optionCEn,
          optionDEn: item.optionDEn,
          optionAId: item.optionAId,
          optionBId: item.optionBId,
          optionCId: item.optionCId,
          optionDId: item.optionDId,
          imageUrl: null,
          correctAnswer: item.correctAnswer,
        );

        await createQuestion(ref, widget.quizId, q);
      }

      if (mounted) {
        HapticFeedback.heavyImpact();
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isId
                  ? '${selected.length} soal AI berhasil ditambahkan ke asesmen!'
                  : '${selected.length} AI questions added to assessment!',
            ),
            backgroundColor: const Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isInserting = false;
          _errorMessage = isId ? 'Gagal menyimpan soal: $e' : 'Failed to save questions: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isId = Localizations.localeOf(context).languageCode == 'id';
    final selectedCount = _drafts.where((d) => d.isSelected).length;

    return Dialog(
      backgroundColor: isDark ? NetLearnColors.darkSurface : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580, maxHeight: 720),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF8C52FF).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      color: Color(0xFF8C52FF),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isId ? 'Buat Soal Otomatis (AI)' : 'Auto-Generate Questions (AI)',
                          style: TextStyle(
                            fontFamily: AppTheme.displayFontFamily,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: isDark ? NetLearnColors.darkText : const Color(0xFF1F1D2B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          isId
                              ? 'Ditenagai AI Groq untuk membuat draf soal pilihan ganda cepat'
                              : 'Powered by Groq AI to quickly draft multiple-choice questions',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? NetLearnColors.darkMuted : const Color(0xFF7E7B8F),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20),
                    onPressed: _isGenerating || _isInserting ? null : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Error banner if any
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFFCDD2)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, color: Color(0xFFC62828), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 12, color: Color(0xFFB71C1C)),
                        ),
                      ),
                    ],
                  ),
                ),

              // Content Body
              Expanded(
                child: _drafts.isEmpty
                    ? SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isId ? 'Topik Soal' : 'Question Topic',
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _topicController,
                              enabled: !_isGenerating,
                              decoration: InputDecoration(
                                hintText: isId
                                    ? 'Contoh: Subnetting IPv4 & CIDR /26'
                                    : 'Example: IPv4 Subnetting & CIDR /26',
                                filled: true,
                                fillColor: isDark ? NetLearnColors.darkApp : const Color(0xFFF7F6FA),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: isDark ? NetLearnColors.darkLine : const Color(0xFFE5E2EE),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: _suggestedTopics.map((topic) {
                                return ActionChip(
                                  label: Text(topic, style: const TextStyle(fontSize: 11)),
                                  backgroundColor: isDark ? NetLearnColors.darkApp : const Color(0xFFF0ECF8),
                                  onPressed: () {
                                    setState(() => _topicController.text = topic);
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 18),

                            // Quantity and Difficulty Row (Responsive LayoutBuilder)
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final isNarrow = constraints.maxWidth < 520;

                                final quantityWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isId
                                          ? 'Jumlah Soal: $_questionCount'
                                          : 'Questions: $_questionCount',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                    Slider(
                                      value: _questionCount.toDouble(),
                                      min: 1,
                                      max: 5,
                                      divisions: 4,
                                      activeColor: const Color(0xFF8C52FF),
                                      label: isId ? '$_questionCount Soal' : '$_questionCount Questions',
                                      onChanged: _isGenerating
                                          ? null
                                          : (v) => setState(() => _questionCount = v.round()),
                                    ),
                                  ],
                                );

                                final difficultyWidget = Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      isId ? 'Tingkat Kesulitan' : 'Difficulty Level',
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 8),
                                    DropdownButtonFormField<String>(
                                      initialValue: _difficulty,
                                      isExpanded: true,
                                      isDense: true,
                                      icon: const Icon(Icons.arrow_drop_down, size: 20),
                                      decoration: InputDecoration(
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                        filled: true,
                                        fillColor: isDark ? NetLearnColors.darkApp : const Color(0xFFF7F6FA),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(12),
                                          borderSide: BorderSide(
                                            color: isDark ? NetLearnColors.darkLine : const Color(0xFFE5E2EE),
                                          ),
                                        ),
                                      ),
                                      items: [
                                        DropdownMenuItem(
                                          value: 'Pemula',
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              isId ? 'Pemula' : 'Beginner',
                                              style: const TextStyle(fontSize: 12.5),
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Menengah',
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              isId ? 'Menengah' : 'Intermediate',
                                              style: const TextStyle(fontSize: 12.5),
                                            ),
                                          ),
                                        ),
                                        DropdownMenuItem(
                                          value: 'Lanjutan',
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              isId ? 'Lanjutan' : 'Advanced',
                                              style: const TextStyle(fontSize: 12.5),
                                            ),
                                          ),
                                        ),
                                      ],
                                      onChanged: _isGenerating ? null : (v) => setState(() => _difficulty = v ?? 'Menengah'),
                                    ),
                                  ],
                                );

                                if (isNarrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      quantityWidget,
                                      const SizedBox(height: 12),
                                      difficultyWidget,
                                    ],
                                  );
                                }

                                return Row(
                                  children: [
                                    Expanded(child: quantityWidget),
                                    const SizedBox(width: 14),
                                    Expanded(child: difficultyWidget),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _drafts.length,
                        itemBuilder: (ctx, idx) {
                          final item = _drafts[idx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: item.isSelected
                                    ? const Color(0xFF8C52FF)
                                    : (isDark ? NetLearnColors.darkLine : const Color(0xFFE5E2EE)),
                                width: item.isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: item.isSelected,
                                        activeColor: const Color(0xFF8C52FF),
                                        onChanged: (val) {
                                          setState(() => item.isSelected = val ?? false);
                                        },
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              isId ? 'Soal #${idx + 1}' : 'Question #${idx + 1}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: Color(0xFF8C52FF),
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              item.questionId,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            if (item.questionEn.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.questionEn,
                                                style: TextStyle(
                                                  fontSize: 11.5,
                                                  fontStyle: FontStyle.italic,
                                                  color: isDark ? NetLearnColors.darkMuted : const Color(0xFF7E7B8F),
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 44),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildOptionRow('A', item.optionAId, item.correctAnswer == 'A'),
                                        _buildOptionRow('B', item.optionBId, item.correctAnswer == 'B'),
                                        _buildOptionRow('C', item.optionCId, item.correctAnswer == 'C'),
                                        _buildOptionRow('D', item.optionDId, item.correctAnswer == 'D'),
                                        if (item.explanation.isNotEmpty) ...[
                                          const SizedBox(height: 6),
                                          Text(
                                            isId
                                                ? '💡 Pembahasan: ${item.explanation}'
                                                : '💡 Explanation: ${item.explanation}',
                                            style: const TextStyle(
                                              fontSize: 11,
                                              color: Color(0xFF2E7D32),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 12),
              // Bottom Action Buttons
              if (_drafts.isEmpty)
                NlButton(
                  label: _isGenerating
                      ? (isId ? 'Sedang Merancang Soal...' : 'Drafting Questions...')
                      : (isId ? 'Mulai Buat Soal AI' : 'Start AI Generation'),
                  icon: _isGenerating ? null : Icons.auto_awesome_rounded,
                  loading: _isGenerating,
                  onPressed: _isGenerating ? null : _generateQuestions,
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isInserting
                            ? null
                            : () => setState(() => _drafts = []),
                        child: Text(isId ? 'Buat Ulang' : 'Regenerate'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: NlButton(
                        label: _isInserting
                            ? (isId ? 'Menyimpan...' : 'Saving...')
                            : (isId ? 'Tambahkan ($selectedCount) Soal' : 'Add ($selectedCount) Questions'),
                        icon: Icons.check_circle_outline_rounded,
                        loading: _isInserting,
                        onPressed: selectedCount == 0 || _isInserting
                            ? null
                            : _insertSelectedQuestions,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionRow(String letter, String text, bool isCorrect) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCorrect ? const Color(0xFF2E7D32) : const Color(0xFFEDE9F4),
            ),
            child: Text(
              letter,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: isCorrect ? Colors.white : const Color(0xFF534F63),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isCorrect ? FontWeight.w700 : FontWeight.w400,
                color: isCorrect ? const Color(0xFF2E7D32) : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

