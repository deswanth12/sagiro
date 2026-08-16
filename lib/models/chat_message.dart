enum ChatSender { user, assistant }

class ChatMessage {
  final String id;
  final String text;
  final ChatSender sender;
  final DateTime timestamp;
  final List<String> suggestions;
  final String? actionTitle;
  final Function()? onActionPressed;

  ChatMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    this.suggestions = const [],
    this.actionTitle,
    this.onActionPressed,
  });
}
