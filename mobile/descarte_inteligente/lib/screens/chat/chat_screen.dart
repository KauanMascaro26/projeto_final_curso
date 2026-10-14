import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _navy = Color(0xFF101C2C);
  static const _navySoft = Color(0xFF1C3045);
  static const _green = Color(0xFF168A68);
  static const _mint = Color(0xFF55D6A2);
  static const _cyan = Color(0xFF53D9F5);
  static const _background = Color(0xFFF4F7FB);
  static const _text = Color(0xFF182638);
  static const _muted = Color(0xFF68788B);

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [
    const _ChatMessage(
      text: 'Olá! Sou o assistente do Descarte Inteligente. Posso ajudar você '
          'a descobrir como preparar e descartar seus resíduos. Por onde '
          'vamos começar?',
      isUser: false,
    ),
  ];

  bool _isSending = false;

  static const _suggestions = [
    _Suggestion('Pilha usada', 'Como descarto uma pilha usada?', Icons.battery_3_bar_outlined),
    _Suggestion('Garrafa PET', 'Como descarto uma garrafa PET?', Icons.water_bottle_outlined),
    _Suggestion('Papelão', 'Como preparo o papelão para reciclagem?', Icons.inventory_2_outlined),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage([String? suggestedMessage]) async {
    final message = (suggestedMessage ?? _messageController.text).trim();
    if (message.isEmpty || _isSending) return;

    final history = _messages
        .map((item) => <String, String>{
              'role': item.isUser ? 'user' : 'assistant',
              'content': item.text,
            })
        .toList();

    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      final response = await ApiService.sendChatMessage(message, history: history);
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: response['answer']?.toString() ?? 'Não recebi uma resposta válida do assistente.',
          isUser: false,
        ));
        _isSending = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _messages.add(_ChatMessage(
          text: 'Não consegui responder agora. Verifique sua conexão e tente novamente.',
          isUser: false,
        ));
        _isSending = false;
      });
    }

    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isWelcome = _messages.length == 1 && !_isSending;

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _navy,
        foregroundColor: Colors.white,
        toolbarHeight: 78,
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_mint, _cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(Icons.auto_awesome_rounded, color: _navy, size: 25),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Chat inteligente', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.circle, color: _mint, size: 8),
                      SizedBox(width: 6),
                      Text('Assistente de descarte', style: TextStyle(fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              itemCount: _messages.length + (_isSending ? 1 : 0) + (isWelcome ? 1 : 0),
              itemBuilder: (context, index) {
                if (isWelcome && index == _messages.length) {
                  return const _WelcomePrompts();
                }
                if (_isSending && index == _messages.length + (isWelcome ? 1 : 0)) {
                  return const _ThinkingBubble();
                }
                return _MessageBubble(message: _messages[index]);
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE1E8F0))),
              boxShadow: [BoxShadow(color: Color(0x0A101C2C), blurRadius: 18, offset: Offset(0, -5))],
            ),
            child: SafeArea(
              top: false,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                      decoration: InputDecoration(
                        hintText: 'Pergunte sobre um resíduo...',
                        hintStyle: const TextStyle(color: _muted, fontSize: 14),
                        filled: true,
                        fillColor: _background,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: Color(0xFFE1E8F0)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: Color(0xFFE1E8F0)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(22),
                          borderSide: const BorderSide(color: _green, width: 1.5),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 9),
                  SizedBox(
                    width: 50,
                    height: 50,
                    child: FilledButton(
                      onPressed: _isSending ? null : () => _sendMessage(),
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: const Color(0xFFB8C5D5),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),
                      ),
                      child: Icon(_isSending ? Icons.more_horiz_rounded : Icons.arrow_upward_rounded, size: 25),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Suggestion {
  final String title;
  final String prompt;
  final IconData icon;

  const _Suggestion(this.title, this.prompt, this.icon);
}

class _WelcomePrompts extends StatelessWidget {
  const _WelcomePrompts();

  static const _items = _ChatScreenState._suggestions;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('COMECE POR AQUI', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.3, color: Color(0xFF68788B))),
          const SizedBox(height: 10),
          ..._items.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: Material(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(17),
                  child: InkWell(
                    onTap: () => context.findAncestorStateOfType<_ChatScreenState>()?._sendMessage(item.prompt),
                    borderRadius: BorderRadius.circular(17),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(17),
                        border: Border.all(color: const Color(0xFFE1E8F0)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F8F1),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Icon(item.icon, color: const Color(0xFF168A68)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(item.title, style: const TextStyle(color: Color(0xFF182638), fontWeight: FontWeight.w700, fontSize: 14))),
                          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF168A68), size: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _ChatMessage {
  final String text;
  final bool isUser;

  const _ChatMessage({required this.text, required this.isUser});
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final background = message.isUser ? const Color(0xFF168A68) : Colors.white;
    final foreground = message.isUser ? Colors.white : const Color(0xFF182638);

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * 0.84),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(19),
            topRight: const Radius.circular(19),
            bottomLeft: Radius.circular(message.isUser ? 19 : 5),
            bottomRight: Radius.circular(message.isUser ? 5 : 19),
          ),
          border: message.isUser ? null : Border.all(color: const Color(0xFFE1E8F0)),
          boxShadow: message.isUser
              ? const []
              : const [BoxShadow(color: Color(0x07101C2C), blurRadius: 12, offset: Offset(0, 4))],
        ),
        child: Text(message.text, style: TextStyle(color: foreground, fontSize: 15, height: 1.48)),
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 17,
              height: 17,
              child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF168A68)),
            ),
            SizedBox(width: 10),
            Text('Preparando sua resposta...', style: TextStyle(color: Color(0xFF68788B), fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
