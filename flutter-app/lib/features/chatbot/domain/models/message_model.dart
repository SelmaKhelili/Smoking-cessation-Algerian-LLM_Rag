class MessageModel {
  final String text;
  final bool isSentByMe;
  final String time;

  const MessageModel({
    required this.text,
    required this.isSentByMe,
    required this.time,
  });
}
