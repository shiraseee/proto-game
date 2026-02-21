class Memory {
  final int? id;
  final String content;
  final String timestamp;
  final double importanceScore;

  Memory({
    this.id,
    required this.content,
    required this.timestamp,
    this.importanceScore = 0.5,
  });

  factory Memory.fromMap(Map<String, dynamic> map) {
    return Memory(
      id: map['id'] as int?,
      content: map['content'] as String,
      timestamp: map['timestamp'] as String,
      importanceScore: (map['importance_score'] as num?)?.toDouble() ?? 0.5,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'content': content,
      'timestamp': timestamp,
      'importance_score': importanceScore,
    };
  }
}

class ChatMessage {
  final String text;
  final MessageRole role;
  final DateTime time;

  ChatMessage({
    required this.text,
    required this.role,
    DateTime? time,
  }) : time = time ?? DateTime.now();
}

enum MessageRole { user, pet, error }
