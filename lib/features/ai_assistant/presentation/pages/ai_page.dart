import 'package:flutter/material.dart';
import 'package:atmos_frontend/core/auth/auth_state.dart';
import 'package:atmos_frontend/features/ai_assistant/data/ai_api_client.dart';

class ChatMessage {
  final String text;
  final bool isUser;

  ChatMessage({required this.text, required this.isUser});
}

class AiPage extends StatefulWidget {
  const AiPage({super.key});

  @override
  State<AiPage> createState() => _AiPageState();
}

class _AiPageState extends State<AiPage> with TickerProviderStateMixin {
  final TextEditingController _textController = TextEditingController();
  final List<ChatMessage> _messages = [];
  final ScrollController _scrollController = ScrollController();
  final AiApiClient _apiClient = AiApiClient();
  final FocusNode _focusNode = FocusNode();

  bool _isTyping = false;
  bool _isLoadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    final history = await _apiClient.getChatHistory();
    if (mounted) {
      setState(() {
        _isLoadingHistory = false;
        for (var item in history) {
          _messages.add(ChatMessage(
            text: item['text'] ?? '',
            isUser: item['isUser'] ?? false,
          ));
        }
      });
      Future.delayed(const Duration(milliseconds: 100), _scrollToBottom);
    }
  }

  void _handleSubmitted(String text) async {
    if (text.trim().isEmpty) return;
    _textController.clear();
    _focusNode.requestFocus();

    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isTyping = true;
    });
    _scrollToBottom();

    final aiResponse = await _apiClient.sendMessage(text);

    if (mounted) {
      setState(() {
        _messages.add(ChatMessage(text: aiResponse, isUser: false));
        _isTyping = false;
      });
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E2C),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFFF6B6B), size: 24),
            SizedBox(width: 8),
            Text('Delete Conversation', style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
        content: const Text(
          'Are you sure you want to delete this entire conversation? This action cannot be undone.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6B6B),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await _apiClient.deleteConversation();
              if (mounted) {
                if (success) {
                  setState(() {
                    _messages.clear();
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Conversation deleted'),
                      backgroundColor: const Color(0xFF2D2D44),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Failed to delete conversation'),
                      backgroundColor: const Color(0xFFFF6B6B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AuthState(),
      builder: (context, _) {
        final isDark = AuthState().theme == 'Dark Mode';
        final bgColor = isDark ? const Color(0xFF12121F) : Colors.white;
        final appBarColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEEE);
        final appBarIconColor = isDark ? Colors.white70 : Colors.black54;
        final titleColor = isDark ? Colors.white : Colors.black87;
        final subtitleColor = isDark ? const Color(0xFF4ADE80) : Colors.green.shade600;

        return Scaffold(
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: appBarColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: appBarIconColor, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Atmos AI Assistant', style: TextStyle(color: titleColor, fontWeight: FontWeight.w600, fontSize: 16)),
                    Text('Online', style: TextStyle(color: subtitleColor, fontSize: 12, fontWeight: FontWeight.w400)),
                  ],
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.delete_outline, color: appBarIconColor, size: 22),
                tooltip: 'Delete Conversation',
                onPressed: _messages.isEmpty ? null : _showDeleteDialog,
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: Column(
            children: [
              Expanded(
                child: _isLoadingHistory
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const CircularProgressIndicator(color: Color(0xFF3A7BD5), strokeWidth: 2),
                            const SizedBox(height: 12),
                            Text('Loading conversation...', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 13)),
                          ],
                        ),
                      )
                    : _messages.isEmpty
                        ? _buildEmptyState(isDark)
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            itemCount: _messages.length + (_isTyping ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _messages.length && _isTyping) return _buildTypingIndicator(isDark);
                              return _buildMessageBubble(_messages[index], isDark);
                            },
                          ),
              ),
              _buildInputArea(isDark),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3A7BD5).withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 36),
          ),
          const SizedBox(height: 20),
          Text('Atmos AI Assistant', style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 20, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Ask me about weather, activities,\nand travel recommendations!', textAlign: TextAlign.center, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 14, height: 1.5)),
          const SizedBox(height: 28),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _buildSuggestionChip('Weather in Cebu', isDark),
              _buildSuggestionChip('Activities in Manila', isDark),
              _buildSuggestionChip('Plan my day', isDark),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionChip(String text, bool isDark) {
    return GestureDetector(
      onTap: () => _handleSubmitted(text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF0F0F0),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFDDDDDD)),
        ),
        child: Text(text, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
      ),
    );
  }

  Widget _buildTypingIndicator(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 600 + (i * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF3A7BD5).withValues(alpha: 0.4),
                          const Color(0xFF3A7BD5),
                          (1 + (value * 2 * 3.14159).remainder(1)) / 2,
                        ),
                        shape: BoxShape.circle,
                      ),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isDark) {
    final isUser = message.isUser;
    final aiBubbleColor = isDark ? const Color(0xFF1E1E2C) : const Color(0xFFF0F4FF);
    final aiTextColor = isDark ? Colors.white.withValues(alpha: 0.9) : Colors.black87;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF3A7BD5) : aiBubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isUser ? const Color(0xFF3A7BD5) : Colors.black).withValues(alpha: 0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(message.text, style: TextStyle(color: isUser ? Colors.white : aiTextColor, fontSize: 14.5, height: 1.45)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(bool isDark) {
    return Container(
      padding: EdgeInsets.only(
        left: 12, right: 12, top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFEEEEEE),
        border: Border(
          top: BorderSide(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFDDDDDD), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF12121F) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: isDark ? const Color(0xFF2D2D44) : const Color(0xFFDDDDDD)),
              ),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                onSubmitted: _handleSubmitted,
                style: TextStyle(color: isDark ? Colors.white : Colors.black87, fontSize: 14.5),
                decoration: InputDecoration(
                  hintText: 'Ask Atmos AI...',
                  hintStyle: TextStyle(color: isDark ? Colors.white30 : Colors.black38),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _isTyping ? null : () => _handleSubmitted(_textController.text),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: _isTyping ? null : const LinearGradient(
                  colors: [Color(0xFF00D2FF), Color(0xFF3A7BD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                color: _isTyping ? (isDark ? const Color(0xFF2D2D44) : Colors.grey.shade300) : null,
                borderRadius: BorderRadius.circular(14),
              ),
              child: _isTyping
                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(color: Color(0xFF3A7BD5), strokeWidth: 2))
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
