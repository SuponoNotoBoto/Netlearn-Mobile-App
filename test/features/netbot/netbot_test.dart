import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:netlearn/features/netbot/netbot_models.dart';
import 'package:netlearn/features/netbot/netbot_providers.dart';
import 'package:netlearn/features/netbot/netbot_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('NetBot System Prompt & Localization Tests', () {
    test('buildSystemPrompt builds correct Indonesian prompt with full context', () {
      const context = NetBotContext(
        materialTitle: 'Subnetting IPv4',
        moduleTitle: 'Modul 2: IP Addressing',
        materialBodySnippet: 'Subnetting adalah teknik memecah jaringan besar...',
        topologySnippet: 'Perangkat: PC1, Router1\nKoneksi: PC1 <---> Router1',
        languageCode: 'id',
      );

      final prompt = NetBotService.buildSystemPrompt(context);

      expect(prompt, contains('Anda adalah NetBot'));
      expect(prompt, contains('Modul 2: IP Addressing'));
      expect(prompt, contains('Subnetting IPv4'));
      expect(prompt, contains('Subnetting adalah teknik memecah'));
      expect(prompt, contains('PC1 <---> Router1'));
      expect(prompt, contains('Bahasa Indonesia'));
    });

    test('buildSystemPrompt builds correct English prompt with full context', () {
      const context = NetBotContext(
        materialTitle: 'Subnetting IPv4',
        moduleTitle: 'Module 2: IP Addressing',
        materialBodySnippet: 'Subnetting is the practice of dividing a network...',
        topologySnippet: 'Devices: PC1, Router1\nConnections: PC1 <---> Router1',
        languageCode: 'en',
      );

      final prompt = NetBotService.buildSystemPrompt(context);

      expect(prompt, contains('You are NetBot'));
      expect(prompt, contains('Module 2: IP Addressing'));
      expect(prompt, contains('Subnetting IPv4'));
      expect(prompt, contains('Subnetting is the practice'));
      expect(prompt, contains('PC1 <---> Router1'));
      expect(prompt, contains('English'));
    });
  });

  group('NetBot Providers & Resilience Tests', () {
    test('getAvailableProviders returns non-empty list sorted by priority', () {
      final providers = NetBotProviders.getAvailableProviders();

      expect(providers, isNotEmpty);
      for (int i = 0; i < providers.length - 1; i++) {
        expect(providers[i].priority <= providers[i + 1].priority, isTrue);
      }

      // Groq should be priority 1
      expect(providers.first.id, equals('groq'));
      expect(providers.first.candidateModels, contains('openai/gpt-oss-20b'));
    });

    test('sendMessageStream parses SSE streaming chunks properly', () async {
      final mockClient = MockClient((request) async {
        final sseResponse = [
          'data: {"choices":[{"delta":{"content":"Halo "}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"Mahasiswa! "}}]}\n\n',
          'data: {"choices":[{"delta":{"content":"Ada yang bisa dibantu?"}}]}\n\n',
          'data: [DONE]\n\n',
        ].join();

        return http.Response(sseResponse, 200);
      });

      const context = NetBotContext(languageCode: 'id');
      final chunks = <String>[];

      await for (final chunk in NetBotService.sendMessageStream(
        userMessage: 'Halo',
        context: context,
        httpClient: mockClient,
      )) {
        chunks.add(chunk);
      }

      expect(chunks.join(), equals('Halo Mahasiswa! Ada yang bisa dibantu?'));
    });

    test('sendMessageStream fails over when primary model/provider returns 429', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        final model = body['model'] as String;

        // Simulate 429 rate limit on first candidate model
        if (model == 'openai/gpt-oss-20b') {
          return http.Response('{"error":{"message":"Rate limit reached"}}', 429);
        }

        // Second model succeeds!
        return http.Response(
          'data: {"choices":[{"delta":{"content":"Respon dari model fallback"}}]}\n\ndata: [DONE]\n\n',
          200,
        );
      });

      const context = NetBotContext(languageCode: 'id');
      final chunks = <String>[];

      await for (final chunk in NetBotService.sendMessageStream(
        userMessage: 'Jelaskan router',
        context: context,
        httpClient: mockClient,
      )) {
        chunks.add(chunk);
      }

      expect(callCount, greaterThanOrEqualTo(2));
      expect(chunks.join(), equals('Respon dari model fallback'));
    });
  });

  group('NetBot Multi-Account Chat Isolation Tests', () {
    test('NetBotMessage serializes and deserializes accurately', () {
      final original = NetBotMessage(
        id: 'msg_1',
        text: 'Bagaimana cara subnetting /26?',
        isUser: true,
        timestamp: DateTime(2026, 11, 9, 20, 0),
        providerName: 'Groq LPU',
      );

      final json = original.toJson();
      final revived = NetBotMessage.fromJson(json);

      expect(revived.id, equals(original.id));
      expect(revived.text, equals(original.text));
      expect(revived.isUser, equals(original.isUser));
      expect(revived.timestamp, equals(original.timestamp));
      expect(revived.providerName, equals('Groq LPU'));
      expect(revived.isError, isFalse);
    });

    test('Chat history in SharedPreferences is strictly isolated per userId', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      const studentId = 'user_student_abc';
      const lecturerId = 'user_lecturer_xyz';

      final studentChat = [
        NetBotMessage(
          id: 's1',
          text: 'Pertanyaan dari mahasiswa',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];

      final lecturerChat = [
        NetBotMessage(
          id: 'l1',
          text: 'Pertanyaan dari dosen',
          isUser: true,
          timestamp: DateTime.now(),
        ),
      ];

      // Save student chat
      await prefs.setString(
        'netbot_chat_history_$studentId',
        jsonEncode(studentChat.map((m) => m.toJson()).toList()),
      );

      // Save lecturer chat
      await prefs.setString(
        'netbot_chat_history_$lecturerId',
        jsonEncode(lecturerChat.map((m) => m.toJson()).toList()),
      );

      // Verify student storage only has student messages
      final studentRaw = prefs.getString('netbot_chat_history_$studentId');
      final studentDecoded = (jsonDecode(studentRaw!) as List)
          .map((e) => NetBotMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(studentDecoded.length, equals(1));
      expect(studentDecoded.first.text, equals('Pertanyaan dari mahasiswa'));

      // Verify lecturer storage only has lecturer messages
      final lecturerRaw = prefs.getString('netbot_chat_history_$lecturerId');
      final lecturerDecoded = (jsonDecode(lecturerRaw!) as List)
          .map((e) => NetBotMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      expect(lecturerDecoded.length, equals(1));
      expect(lecturerDecoded.first.text, equals('Pertanyaan dari dosen'));

      // Verify clearing student chat does not touch lecturer chat
      await prefs.remove('netbot_chat_history_$studentId');
      expect(prefs.containsKey('netbot_chat_history_$studentId'), isFalse);
      expect(prefs.containsKey('netbot_chat_history_$lecturerId'), isTrue);
    });
  });

  group('NetBot AI Response Sanitization & Cleanup Tests', () {
    test('cleanResponseText removes excessive double asterisks from text', () {
      const raw = '**Router** adalah perangkat yang menghubungkan dua atau lebih **jaringan komputer**.';
      final cleaned = NetBotService.cleanResponseText(raw);

      expect(cleaned, equals('Router adalah perangkat yang menghubungkan dua atau lebih jaringan komputer.'));
      expect(cleaned, isNot(contains('**')));
    });

    test('cleanResponseText converts markdown bullets to clean bullets and removes hashes', () {
      const raw = '### Fungsi Utama:\n* Menghubungkan jaringan\n- Mengatur rute paket';
      final cleaned = NetBotService.cleanResponseText(raw);

      expect(cleaned, contains('Fungsi Utama:'));
      expect(cleaned, contains('• Menghubungkan jaringan'));
      expect(cleaned, contains('• Mengatur rute paket'));
      expect(cleaned, isNot(contains('###')));
    });

    test('cleanResponseText preserves asterisks inside markdown code blocks', () {
      const raw = 'Gunakan perintah berikut:\n```bash\nRouter(config)# interface gigabitEthernet 0/0\n**important_command**\n```\nSelesai.';
      final cleaned = NetBotService.cleanResponseText(raw);

      expect(cleaned, contains('```bash\nRouter(config)# interface gigabitEthernet 0/0\n**important_command**\n```'));
      expect(cleaned, contains('Gunakan perintah berikut:'));
      expect(cleaned, contains('Selesai.'));
    });
  });
}
