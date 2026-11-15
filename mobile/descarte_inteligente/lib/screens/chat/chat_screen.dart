import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../services/location_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  AppPalette get _palette => context.appPalette;
  Color get _background => _palette.background;
  Color get _surface => _palette.surface;
  Color get _surfaceRaised => _palette.surfaceRaised;
  Color get _green => _palette.primary;
  static const _cyan = AppColors.cyan;
  Color get _text => _palette.text;
  Color get _muted => _palette.muted;
  Color get _border => _palette.border;

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
      accent: AppColors.emerald,
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

  List<Map<String, dynamic>> _buildHistory(
    Iterable<_ChatMessage> messages,
  ) {
    final history = messages
        .map((item) {
          final content = item.text.trim();
          final turn = <String, dynamic>{
            'role': item.isUser ? 'user' : 'assistant',
            'content': content.length > 2500
                ? content.substring(0, 2500)
                : content,
          };
          if (!item.isUser && item.collectionPoints.isNotEmpty) {
            turn['collection_point_ids'] = item.collectionPoints
                .map((point) => point['id'])
                .whereType<int>()
                .toList();
          }
          return turn;
        })
        .where((turn) => (turn['content'] as String).isNotEmpty)
        .toList();

    return history.length <= 12
        ? history
        : history.sublist(history.length - 12);
  }

  Future<void> _sendMessage([String? suggestedMessage]) async {
    final message = (suggestedMessage ?? _messageController.text).trim();
    if (message.isEmpty || _isSending) return;

    final history = _buildHistory(_messages);

    _messageController.clear();
    setState(() {
      _messages.add(_ChatMessage(text: message, isUser: true));
      _isSending = true;
    });
    _scrollToBottom();

    try {
      double? latitude;
      double? longitude;
      final position = await LocationService.getCurrentLocationIfPermitted();
      latitude = position?.latitude;
      longitude = position?.longitude;

      final response = await ApiService.sendChatMessage(
        message,
        history: history,
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      final points = (response['collection_points'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _messages.add(_ChatMessage(
          text: response['answer']?.toString() ??
              'Não recebi uma resposta válida do assistente.',
          isUser: false,
          collectionPoints: points,
          needsLocationSelection: response['needs_location_selection'] == true,
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

  Future<LatLng?> _pickLocationOnMap() async {
    LatLng? selectedLocation;

    return showModalBottomSheet<LatLng>(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SizedBox(
              height: MediaQuery.sizeOf(context).height * 0.72,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Escolha sua localização',
                          style: TextStyle(
                            color: _text,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Toque no mapa para marcar um ponto de referência. Não é necessário ativar o GPS.',
                          style: TextStyle(color: _muted, fontSize: 12, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: GoogleMap(
                      initialCameraPosition: const CameraPosition(
                        target: LatLng(-22.0175, -47.8908),
                        zoom: 13,
                      ),
                      onTap: (position) {
                        setSheetState(() => selectedLocation = position);
                      },
                      markers: selectedLocation == null
                          ? const {}
                          : {
                              Marker(
                                markerId: const MarkerId('selected_location'),
                                position: selectedLocation!,
                                draggable: true,
                                onDragEnd: (position) {
                                  setSheetState(() => selectedLocation = position);
                                },
                              ),
                            },
                      myLocationButtonEnabled: false,
                      myLocationEnabled: false,
                      zoomControlsEnabled: true,
                    ),
                  ),
                  SafeArea(
                    top: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: selectedLocation == null
                              ? null
                              : () => Navigator.pop(sheetContext, selectedLocation),
                          icon: Icon(Icons.check),
                          label: Text('Usar esta localização'),
                          style: FilledButton.styleFrom(
                            backgroundColor: _green,
                            foregroundColor: _palette.primaryForeground,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _selectLocationForSearch() async {
    if (_isSending) return;
    final location = await _pickLocationOnMap();
    if (location == null || !mounted) return;

    final lastUserIndex = _messages.lastIndexWhere((item) => item.isUser);
    if (lastUserIndex < 0) return;
    final originalMessage = _messages[lastUserIndex].text;
    final history = _buildHistory(_messages.take(lastUserIndex));

    setState(() => _isSending = true);
    _scrollToBottom();

    try {
      final response = await ApiService.sendChatMessage(
        originalMessage,
        history: history,
        latitude: location.latitude,
        longitude: location.longitude,
      );
      if (!mounted) return;
      final points = (response['collection_points'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();
      setState(() {
        _messages.add(_ChatMessage(
          text: response['answer']?.toString() ??
              'Não recebi uma resposta válida do assistente.',
          isUser: false,
          collectionPoints: points,
        ));
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages.add(const _ChatMessage(
          text: 'Não consegui consultar os pontos com essa localização. Tente novamente.',
          isUser: false,
        ));
        _isSending = false;
      });
    }
    _scrollToBottom();
  }

  Future<void> _useCurrentLocationForSearch() async {
    if (_isSending) return;

    final lastUserIndex = _messages.lastIndexWhere((item) => item.isUser);
    if (lastUserIndex < 0) return;

    Position position;
    try {
      position = await LocationService.getCurrentLocation();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Não consegui acessar sua localização. Ative o GPS ou escolha um ponto no mapa.',
          ),
          action: SnackBarAction(
            label: 'Configurações',
            onPressed: () => LocationService.openLocationSettings(),
          ),
          backgroundColor: _surfaceRaised,
        ),
      );
      return;
    }

    if (!mounted) return;
    final originalMessage = _messages[lastUserIndex].text;
    final history = _buildHistory(_messages.take(lastUserIndex));

    setState(() => _isSending = true);
    _scrollToBottom();

    try {
      final response = await ApiService.sendChatMessage(
        originalMessage,
        history: history,
        latitude: position.latitude,
        longitude: position.longitude,
      );
      if (!mounted) return;

      final points = (response['collection_points'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      setState(() {
        _messages.add(_ChatMessage(
          text: response['answer']?.toString() ??
              'Não recebi uma resposta válida do assistente.',
          isUser: false,
          collectionPoints: points,
          needsLocationSelection: response['needs_location_selection'] == true,
        ));
        _isSending = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não consegui consultar os pontos agora. Tente novamente.'),
        ),
      );
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
        toolbarHeight: 60,
        titleSpacing: 4,
        actions: [AppThemeToggleButton()],
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [_green, _cyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.park_rounded, color: _background, size: 18),
            ),
            SizedBox(width: 11),
            Expanded(
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
                      return _MessageBubble(
                        message: _messages[index],
                        onChooseLocation: _messages[index].needsLocationSelection
                            ? _selectLocationForSearch
                            : null,
                        onUseCurrentLocation: _messages[index].needsLocationSelection
                            ? _useCurrentLocationForSearch
                            : null,
                      );
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
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: context.appPalette.card,
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: _green.withValues(alpha: 0.45)),
              boxShadow: [
                BoxShadow(
                  color: _cyan.withValues(alpha: 0.10),
                  blurRadius: 30,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Icon(Icons.eco_rounded, color: _green, size: 30),
          ),
          SizedBox(height: 12),
          Text(
            'O QUE VAMOS',
            style: TextStyle(
              color: _muted,
              fontSize: 11.5,
              letterSpacing: 1.8,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'RECICLAR HOJE?',
            style: TextStyle(
              color: _text,
              fontSize: 25,
              height: 1.1,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
            ),
          ),
          SizedBox(height: 7),
          Text(
            'Tire suas dúvidas, descubra como separar seus resíduos e dê o próximo passo para um futuro mais sustentável.',
            style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
          ),
          SizedBox(height: 14),
          Row(
            children: [
              Expanded(
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
          SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _suggestions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              mainAxisExtent: 118,
            ),
            itemBuilder: (context, index) {
              final item = _suggestions[index];
              return _SuggestionCard(
                item: item,
                onTap: () => _sendMessage(item.prompt),
              );
            },
          ),
          SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _surface,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: _border),
            ),
            child: Row(
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
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 8),
      decoration: BoxDecoration(
        color: _surface,
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
                style: TextStyle(color: _text, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'O que você quer descartar?',
                  hintStyle: TextStyle(color: _muted, fontSize: 13),
                  filled: true,
                  fillColor: _surfaceRaised,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide(color: _green, width: 1.4),
                  ),
                ),
              ),
            ),
            SizedBox(width: 9),
            Opacity(
              opacity: _isSending ? 0.42 : 1,
              child: SizedBox(
                width: 43,
                height: 43,
                child: FilledButton(
                  onPressed: _isSending ? null : () => _sendMessage(),
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    foregroundColor: _palette.primaryForeground,
                    disabledBackgroundColor: _green,
                    disabledForegroundColor: _background,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: Icon(Icons.arrow_upward_rounded, size: 25),
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
      color: context.appPalette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.appPalette.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: item.accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(item.icon, color: item.accent, size: 22),
                  ),
                  Spacer(),
                  Icon(
                    Icons.north_east_rounded,
                    color: item.accent,
                    size: 19,
                  ),
                ],
              ),
              Spacer(),
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appPalette.text,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                item.subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.appPalette.muted,
                  fontSize: 9.5,
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
  final List<Map<String, dynamic>> collectionPoints;
  final bool needsLocationSelection;

  const _ChatMessage({
    required this.text,
    required this.isUser,
    this.collectionPoints = const [],
    this.needsLocationSelection = false,
  });
}

class _MessageBubble extends StatelessWidget {
  final _ChatMessage message;
  final VoidCallback? onChooseLocation;
  final VoidCallback? onUseCurrentLocation;

  const _MessageBubble({
    required this.message,
    this.onChooseLocation,
    this.onUseCurrentLocation,
  });

  @override
  Widget build(BuildContext context) {
    final background = message.isUser
        ? const Color(0xFF126D59)
        : context.appPalette.surface;

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.88,
        ),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(message.isUser ? 18 : 5),
            bottomRight: Radius.circular(message.isUser ? 5 : 18),
          ),
          border: Border.all(
            color: message.isUser
                ? context.appPalette.primary
                : context.appPalette.border,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...message.text
                .split(RegExp(r'\n\s*\n'))
                .where((paragraph) => paragraph.trim().isNotEmpty)
                .map((paragraph) => Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        paragraph.trim(),
                        style: TextStyle(
                          color: message.isUser
                              ? Colors.white
                              : context.appPalette.text,
                          fontSize: 14,
                          height: 1.48,
                        ),
                      ),
                    )),
            if (!message.isUser &&
                message.needsLocationSelection &&
                onChooseLocation != null) ...[
              SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onUseCurrentLocation,
                    icon: Icon(Icons.my_location_rounded, size: 17),
                    label: Text('Usar minha localização'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: context.appPalette.primary,
                      side: BorderSide(color: context.appPalette.primary),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: onChooseLocation,
                    icon: Icon(Icons.map_outlined, size: 17),
                    label: Text('Escolher no mapa'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ChatScreenState._cyan,
                      side: BorderSide(color: _ChatScreenState._cyan),
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ],
              ),
            ],
            if (!message.isUser && message.collectionPoints.isNotEmpty) ...[
              SizedBox(height: 12),
              Text(
                message.collectionPoints.length == 1
                    ? 'Ponto de coleta'
                    : 'Pontos de coleta',
                style: TextStyle(
                  color: context.appPalette.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 7),
              ...message.collectionPoints.map((point) {
                final name = point['nome']?.toString() ?? 'Ponto de coleta';
                final address = point['endereco']?.toString() ?? '';
                final distance = point['distancia_km'];
                final lat = (point['latitude'] as num?)?.toDouble();
                final lon = (point['longitude'] as num?)?.toDouble();

                return Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 7),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.appPalette.surfaceRaised,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: context.appPalette.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: context.appPalette.text,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (address.isNotEmpty) ...[
                        SizedBox(height: 3),
                        Text(
                          address,
                          style: TextStyle(
                            color: context.appPalette.muted,
                            fontSize: 11.5,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (distance != null) ...[
                        SizedBox(height: 5),
                        Text(
                          '${(distance as num).toStringAsFixed(1)} km',
                          style: TextStyle(
                            color: context.appPalette.primary,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                      if (lat != null && lon != null) ...[
                        SizedBox(height: 4),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final uri = Uri.https(
                                'www.google.com',
                                '/maps/dir/',
                                {
                                  'api': '1',
                                  'destination': '$lat,$lon',
                                },
                              );
                              await launchUrl(
                                uri,
                                mode: LaunchMode.externalApplication,
                              );
                            },
                            icon: Icon(Icons.directions, size: 16),
                            label: Text('Abrir rota'),
                            style: TextButton.styleFrom(
                              foregroundColor: _ChatScreenState._cyan,
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }
}

class _BrandLoader extends StatelessWidget {
  final double size;

  const _BrandLoader({this.size = 34});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 2.2,
              color: context.appPalette.primary,
            ),
          ),
          Icon(
            Icons.park_rounded,
            color: context.appPalette.primary,
            size: size * 0.48,
          ),
        ],
      ),
    );
  }
}

class _ThinkingBubble extends StatelessWidget {
  const _ThinkingBubble();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _BrandLoader(size: 30),
            SizedBox(width: 9),
            Text(
              'Preparando sua resposta...',
              style: TextStyle(color: context.appPalette.muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
