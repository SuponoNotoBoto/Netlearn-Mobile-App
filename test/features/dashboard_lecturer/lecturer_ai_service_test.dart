import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:netlearn/features/dashboard_lecturer/lecturer_ai_service.dart';
import 'package:netlearn/shared/models/student_model.dart';

class _MockLecturerHttpClient extends http.BaseClient {
  final Future<http.Response> Function(http.BaseRequest request) handler;

  _MockLecturerHttpClient(this.handler);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: {
        'content-type': 'application/json; charset=utf-8',
        ...response.headers,
      },
    );
  }
}

void main() {
  group('LecturerAiService JSON & Translation Tests', () {
    setUp(() {
      dotenv.loadFromString(
        envString: '''
GROQ_API_KEY=test-groq-key
OPENROUTER_API_KEY=test-openrouter-key
GEMINI_API_KEY=test-gemini-key
''',
        isOptional: true,
      );
    });

    tearDown(() => dotenv.clean());

    test('extractJsonMap extracts JSON cleanly from markdown code fences', () {
      const raw = '''
Here is the translated content:
```json
{
  "title": "Introduction to OSI Model",
  "summary": "7 Layers of Computer Networking",
  "description": "Detailed explanation of physical to application layers."
}
```
''';
      final map = LecturerAiService.extractJsonMap(raw);
      expect(map['title'], 'Introduction to OSI Model');
      expect(map['summary'], '7 Layers of Computer Networking');
      expect(
        map['description'],
        'Detailed explanation of physical to application layers.',
      );
    });

    test('translateMaterial parses translated material fields accurately', () async {
      final mockClient = _MockLecturerHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'title': 'Subnetting Fundamentals',
                    'summary': 'Learn CIDR and VLSM',
                    'description': 'How to divide IPv4 networks efficiently.',
                  }),
                },
              },
            ],
          }),
          200,
        );
      });

      final result = await LecturerAiService.translateMaterial(
        title: 'Dasar Subnetting',
        summary: 'Pelajari CIDR dan VLSM',
        description: 'Cara membagi jaringan IPv4 secara efisien.',
        targetLanguageCode: 'en',
        httpClient: mockClient,
      );

      expect(result.title, 'Subnetting Fundamentals');
      expect(result.summary, 'Learn CIDR and VLSM');
      expect(result.description, 'How to divide IPv4 networks efficiently.');
      expect(result.providerName, isNotEmpty);
    });

    test('translateQuestion translates question and options A-D with failover', () async {
      var callCount = 0;
      final mockClient = _MockLecturerHttpClient((request) async {
        callCount++;
        if (callCount == 1) {
          // Simulate rate limit on first model
          return http.Response('{"error": "Rate limit"}', 429);
        }
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'questionText': 'Which layer handles IP routing?',
                    'optionA': 'Physical Layer',
                    'optionB': 'Data Link Layer',
                    'optionC': 'Network Layer',
                    'optionD': 'Transport Layer',
                  }),
                },
              },
            ],
          }),
          200,
        );
      });

      final result = await LecturerAiService.translateQuestion(
        questionText: 'Layer manakah yang menangani routing IP?',
        optionA: 'Physical Layer',
        optionB: 'Data Link Layer',
        optionC: 'Network Layer',
        optionD: 'Transport Layer',
        targetLanguageCode: 'en',
        httpClient: mockClient,
      );

      expect(callCount, 2);
      expect(result.questionText, 'Which layer handles IP routing?');
      expect(result.optionC, 'Network Layer');
    });

    test('analyzeClassScores generates pedagogical analytics report', () async {
      final mockClient = _MockLecturerHttpClient((request) async {
        return http.Response.bytes(
          utf8.encode(
            jsonEncode({
              'choices': [
                {
                  'message': {
                    'content':
                        '📊 **Evaluasi Performa Kelas**: Rata-rata meningkat dari 60.0 ke 82.5.\n'
                        '🎯 **Perlu Perhatian**: Budi (Post: 55).\n'
                        '💡 **Rekomendasi**: Review modul Subnetting.',
                  },
                },
              ],
            }),
          ),
          200,
          headers: {'content-type': 'application/json; charset=utf-8'},
        );
      });

      final students = [
        const StudentModel(
          id: 's1',
          name: 'Andi',
          identityNumber: '101',
          isActive: true,
          pretestScore: 70,
          posttestScore: 90,
        ),
        const StudentModel(
          id: 's2',
          name: 'Budi',
          identityNumber: '102',
          isActive: true,
          pretestScore: 50,
          posttestScore: 55,
        ),
      ];

      final res = await LecturerAiService.analyzeClassScores(
        students: students,
        languageCode: 'id',
        httpClient: mockClient,
      );

      expect(res.markdownInsight, contains('Evaluasi Performa Kelas'));
      expect(res.markdownInsight, contains('Budi'));
      expect(res.markdownInsight, isNot(contains('**')));
    });

    test('translateAssessment translates title, description, and instructions', () async {
      final mockClient = _MockLecturerHttpClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'title': 'Subnetting Quiz',
                    'description': 'Assess CIDR calculation skills',
                    'instructions': 'Answer all 10 questions carefully.',
                  }),
                },
              },
            ],
          }),
          200,
        );
      });

      final result = await LecturerAiService.translateAssessment(
        title: 'Kuis Subnetting',
        description: 'Menilai kemampuan perhitungan CIDR',
        instructions: 'Jawab semua 10 pertanyaan dengan cermat.',
        targetLanguageCode: 'en',
        httpClient: mockClient,
      );

      expect(result.title, 'Subnetting Quiz');
      expect(result.description, 'Assess CIDR calculation skills');
      expect(result.instructions, 'Answer all 10 questions carefully.');
    });

    test('sanitizeAiInsight cleans up markdown tables and excessive asterisks', () {
      const rawWithTableAndStars = '''
Berikut adalah evaluasi kelas:
| Kategori | Jumlah | Keterangan |
|---|---|---|
| Lulus | 20 | **Sangat Baik** |
| Remedial | 5 | **Perlu Bimbingan** |

### **Rekomendasi**:
Dosen **harus** memberikan **latihan** tambahan.
''';

      final cleaned = LecturerAiService.sanitizeAiInsight(rawWithTableAndStars);
      expect(cleaned, isNot(contains('**')));
      expect(cleaned, isNot(contains('|---|')));
      expect(cleaned, contains('• Lulus — 20 — Sangat Baik'));
      expect(cleaned, contains('• Remedial — 5 — Perlu Bimbingan'));
      expect(cleaned, isNot(contains('###')));
    });
  });
}
