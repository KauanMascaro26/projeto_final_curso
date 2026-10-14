import 'package:flutter/material.dart';

import '../../services/api_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  static const _background = Color(0xFF07131D);
  static const _surface = Color(0xFF0D202B);
  static const _surfaceRaised = Color(0xFF122B38);
  static const _green = Color(0xFF55D6A2);
  static const _greenDark = Color(0xFF168A68);
  static const _cyan = Color(0xFF53D9F5);
  static const _text = Color(0xFFF2F8FA);
  static const _muted = Color(0xFFADC1CC);
  static const _border = Color(0xFF204653);

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
    _Suggestion(
      title: 'Pilhas e baterias',
      subtitle: 'Descarte seguro de eletrônicos',
      prompt: 'Como descarto uma pilha usada?',
      icon: Icons.battery_3_bar_rounded,
      accent: _green,
    ),
    _Suggestion(
      title: 'Plástico e garrafas',
      subtitle: 'Prepare para reciclagem',
      prompt: 'Como descarto uma garrafa PET?',
      icon: Icons.recycling_rounded,
      accent: _cyan,
    ),
    _Suggestion(
      title: 'Papel e papelão',
      subtitle: 'Saiba como separar',
      prompt: 'Como preparo o papelão para reciclagem?',
      icon: Icons.inventory_2_outlined,
      accent: Color(0xFFB8A0FF),
    ),
    _Suggestion(
      title: 'Óleo de cozinha',
      subtitle: 'Evite contaminar a água',
      prompt: 'Como devo descartar óleo de cozinha usado?',
      icon: Icons.water_drop_outlined,
      accent: Color(0xFFFFC875),
    ),
  ];

  bool get _isWelcome => _messages.length == 1 && !_isSending;

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
          text: response['answer']?.toString() ??
              'Não recebi uma resposta válida do assistente.',
          isUser: false,
        ));
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(const _ChatMessage(
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
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 70,
        titleSpacing: 4,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_green, _cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.park_rounded, color: _background, size: 26),
            ),
            const SizedBox(width: 11),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Assistente ecológico',
                    style: TextStyle(
                      color: _text,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 3),
                  Row(
                    children: [
                      Icon(Icons.circle, color: _green, size: 7),
                      SizedBox(width: 6),
                      Text(
                        'Descarte Inteligente',
                        style: TextStyle(color: _muted, fontSize: 11.5),
                      ),
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
            child: _isWelcome
                ? _buildWelcome()
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
                    itemCount: _messages.length + (_isSending ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_isSending && index == _messages.length) {
                        return const _ThinkingBubble();
                      }
                      return _MessageBubble(message: _messages[index]);
                    },
                  ),
          ),
          _buildComposer(),
        ],
      ),
    );
  }

  Widget _buildWelcome() {
    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF123F43), Color(0xFF102D43)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: _green.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.10),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: const Icon(Icons.eco_rounded, color: _green, size: 42),
          ),
          const SizedBox(height: 25),
          const Text(
            'O QUE VAMOS',
            style: TextStyle(
              color: _muted,
              fontSize: 13,
              letterSpacing: 2.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'RECICLAR HOJE?',
            style: TextStyle(
              color: _text,
              fontSize: 31,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tire suas dúvidas, descubra como separar seus resíduos e dê o próximo passo para um futuro mais sustentável.',
            style: TextStyle(color: _muted, fontSize: 14, height: 1.55),
          ),
          const SizedBox(height: 26),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'ESCOLHA UM TEMA',
                  style: TextStyle(
                    color: _text,
                    fontSize: 12,
                    letterSpacing: 1.4,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(Icons.touch_app_outlined, color: _green.withValues(alpha: 0.9), size: 18),
            ],
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              mainAxisExtent: 154,
            ),
            itemBuilder: (context, index) {
              final item = _suggestions[index];
              return _SuggestionCard(
                item: item,
                onTap: () => _sendMessage(item.prompt),
              );
            },
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _border),
            ),
            child: const Row(
              children: [
                Icon(Icons.auto_awesome_rounded, color: _cyan, size: 21),
                SizedBox(width: 11),
                Expanded(
                  child: Text(
                    'Você também pode escrever uma pergunta com suas próprias palavras.',
                    style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComposer() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF091923),
        border: Border(top: BorderSide(color: _border)),
        boxShadow: [
          BoxShadow(
            color: Color(0x26000000),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
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
                style: const TextStyle(color: _text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'O que você quer descartar?',
                  hintStyle: const TextStyle(color: _muted, fontSize: 13),
                  filled: true,
                  fillColor: _surfaceRaised,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: const BorderSide(color: _green, width: 1.4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 9),
            SizedBox(
              width: 49,
              height: 49,
              child: FilledButton(
                onPressed: _isSending ? null : () => _sendMessage(),
                style: FilledButton.styleFrom(
                  backgroundColor: _green,
                  foregroundColor: _background,
                  disabledBackgroundColor: _surfaceRaised,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(17),
                  ),
                ),
                child: Icon(
                  _isSending ? Icons.more_horiz_rounded : Icons.arrow_upward_rounded,
                  size: 25,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Suggestion {
  final String title;
  final String subtitle;
  final String prompt;
  final IconData icon;
  final Color accent;

  const _Suggestion({
    required this.title,
    required this.subtitle,
    required this.prompt,
    required this.icon,
    required this.accent,
  });
}

class _SuggestionCard extends StatelessWidget {
  final _Suggestion item;
  final VoidCallback onTap;

  const _SuggestionCard({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _ChatScreenState._surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _ChatScreenState._border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.accent, size: 22),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    color: item.accent,
                    size: 19,
                  ),
                ],
              ),
              const Spacer(),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ChatScreenState._text,
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ChatScreenState._muted,
                  fontSize: 10.5,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
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
    final background = message.isUser
        ? const Color(0xFF126D59)
        : _ChatScreenState._surface;
    final foreground = _ChatScreenState._text;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.86,
        ),
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
          border: Border.all(
            color: message.isUser ? _ChatScreenState._greenDark : _ChatScreenState._border,
          ),
        ),
        child: Text(
          message.text,
          style: const TextStyle(color: foreground, fontSize: 14.5, height: 1.5),
        ),
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
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _ChatScreenState._green,
              ),
            ),
            SizedBox(width: 10),
            Text(
              'Preparando sua resposta...',
              style: TextStyle(color: _ChatScreenState._muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
