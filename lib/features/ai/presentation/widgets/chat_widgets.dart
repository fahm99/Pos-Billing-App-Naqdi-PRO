import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:billing_app/features/ai/domain/entities/chat_message.dart';
import 'package:billing_app/features/ai/domain/entities/chat_session.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showCopy;

  const ChatBubble({super.key, required this.message, this.showCopy = true});

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == 'user';
    return Align(
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        child: Column(
          crossAxisAlignment: isUser ? CrossAxisAlignment.start : CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser ? Colors.blue.shade600 : Colors.grey.shade100,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser ? const Radius.circular(4) : const Radius.circular(16),
                  bottomRight: isUser ? const Radius.circular(16) : const Radius.circular(4),
                ),
              ),
              child: SelectableText(
                message.content,
                style: TextStyle(
                  fontSize: 15,
                  color: isUser ? Colors.white : Colors.black87,
                ),
              ),
            ),
            if (showCopy && !isUser)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: InkWell(
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: message.content));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('تم نسخ النص'), duration: Duration(seconds: 1)),
                    );
                  },
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.copy, size: 14, color: Colors.grey),
                      SizedBox(width: 4),
                      Text('نسخ', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class ChatInput extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isSending;

  const ChatInput({
    super.key,
    required this.controller,
    required this.onSend,
    this.isSending = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                textDirection: TextDirection.rtl,
                decoration: const InputDecoration(
                  hintText: 'اكتب سؤالك هنا...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(24))),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: isSending ? null : (_) => onSend(),
                maxLines: 4,
                minLines: 1,
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: isSending ? Colors.grey : Colors.blue.shade600,
              child: IconButton(
                icon: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, color: Colors.white),
                onPressed: isSending ? null : onSend,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyChatWidget extends StatelessWidget {
  final void Function(String) onSuggestion;

  const EmptyChatWidget({super.key, required this.onSuggestion});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome, size: 64, color: Colors.blue.shade200),
            const SizedBox(height: 16),
            Text(
              'المساعد الذكي',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            const Text(
              'اسأل عن مبيعاتك، منتجاتك، ديونك، أو اطلب تحليلاً\nلبيانات متجرك بذكاء',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 32),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                _suggestionChip(context, 'كم مبيعات اليوم؟'),
                _suggestionChip(context, 'أفضل منتج مبيعاً'),
                _suggestionChip(context, 'حالة المخزون'),
                _suggestionChip(context, 'تحليل الأرباح'),
                _suggestionChip(context, 'الديون المستحقة'),
                _suggestionChip(context, 'تقرير شامل'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _suggestionChip(BuildContext context, String text) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 13)),
      onPressed: () => onSuggestion(text),
    );
  }
}

class SessionDrawer extends StatelessWidget {
  final List<ChatSession> sessions;
  final String? currentId;
  final void Function(String) onSelect;
  final VoidCallback onNew;
  final void Function(String) onDelete;

  const SessionDrawer({
    super.key,
    required this.sessions,
    this.currentId,
    required this.onSelect,
    required this.onNew,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton.icon(
                  onPressed: onNew,
                  icon: const Icon(Icons.add),
                  label: const Text('محادثة جديدة'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 44),
                  ),
                ),
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: sessions.length,
                  itemBuilder: (context, index) {
                    final s = sessions[index];
                    final isSelected = s.id == currentId;
                    return ListTile(
                      selected: isSelected,
                      title: Text(
                        s.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        _formatDate(s.updatedAt),
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, size: 18),
                        onPressed: () => onDelete(s.id),
                      ),
                      onTap: () => onSelect(s.id),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} دقيقة';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} ساعة';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
