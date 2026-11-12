import 'package:flutter_test/flutter_test.dart';
import 'package:netlearn/features/netbot/netbot_models.dart';
import 'package:netlearn/features/netbot/netbot_service.dart';

void main() {
  group('NetBot Context & Guardrails Tests', () {
    test('buildSystemPrompt contains strict out-of-scope guardrail in Indonesian', () {
      const context = NetBotContext(
        languageCode: 'id',
        moduleTitle: 'Modul 2: Pengalamatan IP',
        materialTitle: 'Dasar Subnetting',
      );

      final prompt = NetBotService.buildSystemPrompt(context);

      expect(prompt.contains('BATASAN RUANG LINGKUP & TOPIK (SANGAT KETAT)'), isTrue);
      expect(prompt.contains('PENOLAKAN PERTANYAAN DI LUAR TOPIK'), isTrue);
      expect(prompt.contains('resep masakan'), isTrue);
      expect(prompt.contains('WAJIB MENOLAK DENGAN SANTUN DAN RAMAH'), isTrue);
    });

    test('buildSystemPrompt contains strict out-of-scope guardrail in English', () {
      const context = NetBotContext(
        languageCode: 'en',
        moduleTitle: 'Module 2: IP Addressing',
        materialTitle: 'Subnetting Fundamentals',
      );

      final prompt = NetBotService.buildSystemPrompt(context);

      expect(prompt.contains('STRICT CONTEXT SCOPE'), isTrue);
      expect(prompt.contains('OUT-OF-SCOPE REFUSAL'), isTrue);
      expect(prompt.contains('MUST POLITELY AND FIRMLY DECLINE'), isTrue);
    });

    test('cleanResponseText formats clean text without excessive markdown', () {
      const raw = '### Subnet Mask\n\n**Subnet mask** digunakan untuk memisahkan **Network ID** dan **Host ID**.\n- Poin 1\n* Poin 2';
      final clean = NetBotService.cleanResponseText(raw);

      expect(clean.contains('**'), isFalse);
      expect(clean.contains('###'), isFalse);
      expect(clean.contains('• Poin 1'), isTrue);
      expect(clean.contains('• Poin 2'), isTrue);
    });
  });
}

