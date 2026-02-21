import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/memory.dart';
import '../services/app_state.dart';
import '../services/gemini_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _messages = <ChatMessage>[];
  bool _loading = false;
  bool _greetingShown = false;
  late AnimationController _bounceController;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: -10).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  void _showGreeting(String greeting) {
    if (_greetingShown || greeting.isEmpty) return;
    _greetingShown = true;
    setState(() {
      _messages.add(ChatMessage(text: greeting, role: MessageRole.pet));
    });
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _loading) return;

    final appState = context.read<AppState>();
    _controller.clear();

    setState(() {
      _messages.add(ChatMessage(text: text, role: MessageRole.user));
      _loading = true;
    });
    _scrollToBottom();

    try {
      final response = await GeminiService.chatWithPet(text, appState.apiKey);
      appState.incrementChat();
      setState(() {
        _messages.add(ChatMessage(text: response, role: MessageRole.pet));
      });
    } catch (e) {
      setState(() {
        _messages.add(ChatMessage(
          text: e.toString().replaceFirst('Exception: ', ''),
          role: MessageRole.error,
        ));
      });
    }

    setState(() => _loading = false);
    _scrollToBottom();
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

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    // Show greeting when available
    if (appState.greeting.isNotEmpty && !_greetingShown) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showGreeting(appState.greeting);
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('🐣 AniMind')),
      body: Column(
        children: [
          // Pet display area
          _buildPetArea(appState),

          // Divider
          Container(height: 1, color: const Color(0xFFE8DCC8)),

          // Chat messages
          Expanded(child: _buildChatArea()),

          // Input area
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildPetArea(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: const Color(0xFFFFF8E7),
      child: Column(
        children: [
          Text(
            'Day ${appState.dayCount} of your life together',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFFA0896C),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedBuilder(
            animation: _bounceAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _bounceAnimation.value),
                child: child,
              );
            },
            child: Text(
              appState.moodEmoji,
              style: const TextStyle(fontSize: 52),
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF7C4DFF).withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              appState.moodLabel,
              style: const TextStyle(
                fontSize: 11,
                color: Color(0xFF7C4DFF),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Pixel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF5D4037),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatArea() {
    if (_messages.isEmpty) {
      return const Center(
        child: Text(
          'Say something to Pixel!',
          style: TextStyle(color: Color(0xFFBBA88C), fontSize: 14),
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_loading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length && _loading) {
          return _buildTypingIndicator();
        }
        return _buildMessageBubble(_messages[index]);
      },
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.role == MessageRole.user;
    final isError = msg.role == MessageRole.error;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.78,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? const Color(0xFF7C4DFF)
              : isError
                  ? const Color(0xFFFFEBEE)
                  : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
          border: isError ? Border.all(color: const Color(0xFFFFCDD2)) : null,
          boxShadow: isUser
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isUser && !isError)
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'Pixel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7C4DFF),
                  ),
                ),
              ),
            Text(
              msg.text,
              style: TextStyle(
                fontSize: 15,
                color: isUser ? Colors.white : const Color(0xFF333333),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF7C4DFF),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Pixel is thinking...',
            style: TextStyle(
              fontSize: 13,
              color: const Color(0xFF7C4DFF).withAlpha(200),
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        12,
        12,
        12,
        12 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8DCC8))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              enabled: !_loading,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
              decoration: InputDecoration(
                hintText: 'Talk to Pixel...',
                hintStyle: const TextStyle(color: Color(0xFF999999)),
                filled: true,
                fillColor: const Color(0xFFF5F0E6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: _controller.text.trim().isEmpty || _loading
                ? const Color(0xFFD1C4E9)
                : const Color(0xFF7C4DFF),
            borderRadius: BorderRadius.circular(22),
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: _sendMessage,
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
