import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../services/openrouter_service.dart';
import '../shared_ui.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final OpenRouterService _openRouter = OpenRouterService();
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [
    {
      'role': 'assistant',
      'content':
          'Hello! I am your ReWorth Eco-Assistant. How can I help you with recycling or waste management today?',
    },
  ];
  bool _busy = false;

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

  Future<void> _sendPrompt() async {
    final prompt = _controller.text.trim();
    if (prompt.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': prompt});
      _busy = true;
      _controller.clear();
    });
    _scrollToBottom();

    try {
      final text = await _openRouter.ask(prompt);
      setState(() {
        _messages.add({'role': 'assistant', 'content': text});
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'assistant', 'content': 'Error: $e'});
      });
    } finally {
      setState(() => _busy = false);
      _scrollToBottom();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Eco Assistant',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: ReWorthUI.backgroundGradient),
        child: Column(
          children: [
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 100),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(20),
                    itemCount: _messages.length + (_busy ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _messages.length) {
                        return _buildTypingIndicator();
                      }
                      final msg = _messages[index];
                      final isUser = msg['role'] == 'user';
                      return _buildMessageBubble(msg['content']!, isUser);
                    },
                  ),
                ),
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(String content, bool isUser) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser)
            Container(
              margin: const EdgeInsets.only(right: 8, top: 4),
              child: const CircleAvatar(
                backgroundColor: ReWorthUI.accentGreen,
                radius: 16,
                child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
              ),
            ),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? ReWorthUI.accentBlue : Colors.grey[100],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomRight: isUser ? const Radius.circular(0) : null,
                  bottomLeft: !isUser ? const Radius.circular(0) : null,
                ),
              ),
              child: MarkdownBody(
                data: content,
                styleSheet: MarkdownStyleSheet(
                  p: TextStyle(
                    color: isUser ? Colors.white : Colors.black87,
                    fontSize: 15,
                    height: 1.4,
                  ),
                  strong: TextStyle(
                    color: isUser ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                  listBullet: TextStyle(
                    color: isUser ? Colors.white70 : Colors.black54,
                  ),
                ),
              ),
            ),
          ),
          if (isUser)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 4),
              child: const CircleAvatar(
                backgroundColor: ReWorthUI.accentBlue,
                radius: 16,
                child: Icon(Icons.person, color: Colors.white, size: 18),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const CircleAvatar(
            backgroundColor: ReWorthUI.accentGreen,
            radius: 16,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      ReWorthUI.accentGreen,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  'Assistant is typing...',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(30),
              ),
              child: TextField(
                controller: _controller,
                decoration: const InputDecoration(
                  hintText: 'Ask about recycling...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                ),
                onSubmitted: (_) => _sendPrompt(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _busy ? null : _sendPrompt,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: ReWorthUI.accentGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }
}
