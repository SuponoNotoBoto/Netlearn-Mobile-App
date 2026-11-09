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

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isUser': isUser,
        'timestamp': timestamp.toIso8601String(),
        'isError': isError,
        'providerName': providerName,
      };

  factory NetBotMessage.fromJson(Map<String, dynamic> json) => NetBotMessage(
        id: json['id'] as String,
        text: json['text'] as String,
        isUser: json['isUser'] as bool,
        timestamp: DateTime.parse(json['timestamp'] as String),
        isError: json['isError'] as bool? ?? false,
        providerName: json['providerName'] as String?,
      );
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
