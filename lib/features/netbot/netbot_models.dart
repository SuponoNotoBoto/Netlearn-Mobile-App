class NetBotMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isError;
  final String? providerName;

  const NetBotMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isError = false,
    this.providerName,
  });

  NetBotMessage copyWith({
    String? id,
    String? text,
    bool? isUser,
    DateTime? timestamp,
    bool? isError,
    String? providerName,
  }) {
    return NetBotMessage(
      id: id ?? this.id,
      text: text ?? this.text,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isError: isError ?? this.isError,
      providerName: providerName ?? this.providerName,
    );
  }
}

class NetBotContext {
  final String? materialTitle;
  final String? moduleTitle;
  final String? materialBodySnippet;
  final String? topologySnippet;
  final String languageCode;

  const NetBotContext({
    this.materialTitle,
    this.moduleTitle,
    this.materialBodySnippet,
    this.topologySnippet,
    this.languageCode = 'id',
  });
}

class AiProviderConfig {
  final String id;
  final String name;
  final String endpoint;
  final String apiKey;
  final List<String> candidateModels;
  final int priority;

  const AiProviderConfig({
    required this.id,
    required this.name,
    required this.endpoint,
    required this.apiKey,
    required this.candidateModels,
    required this.priority,
  });

  bool get isValid => apiKey.trim().isNotEmpty;
}

