import 'package:flutter/material.dart';

import '../chat/chat_screen.dart';
import '../collection_points/collection_points_screen.dart';
import '../identification/identification_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _background = Color(0xFF07131D);
  static const _surface = Color(0xFF0D202B);
  static const _surfaceRaised = Color(0xFF122B38);
  static const _green = Color(0xFF55D6A2);
  static const _cyan = Color(0xFF53D9F5);
  static const _text = Color(0xFFF2F8FA);
  static const _muted = Color(0xFFADC1CC);
  static const _border = Color(0xFF204653);

  int _currentIndex = 0;

  void _openChat() => setState(() => _currentIndex = 1);

  void _openIdentification() => setState(() => _currentIndex = 2);

  void _openCollectionPoints() => setState(() => _currentIndex = 3);

  void _showAbout() => setState(() => _currentIndex = 4);

  void _onNavigation(int index) {
    setState(() => _currentIndex = index);
  }

  Widget _buildHomeContent() {
    return SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 16),
                    const Text(
                      'Identifique, aprenda e descarte',
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'de forma correta.',
                      style: TextStyle(
                        color: _green,
                        fontSize: 22,
                        height: 1.15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 17),
                    _buildChatCard(),
                    const SizedBox(height: 22),
                    const Text(
                      'Explore o aplicativo',
                      style: TextStyle(
                        color: _text,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Escolha como deseja começar.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.search_rounded,
                            title: 'Buscar resíduo',
                            description: 'Encontre orientações por material.',
                            accent: _cyan,
                            onTap: _openIdentification,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _ActionCard(
                            icon: Icons.photo_camera_outlined,
                            title: 'Identificar por foto',
                            description: 'Reconhecimento visual.',
                            accent: _muted,
                            disabled: true,
                            onTap: null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 17),
                    _buildCollectionCard(),
                    const SizedBox(height: 16),
                    _buildImpactCard(),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
  }

  Widget _buildAboutScreen() {
    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: _background,
        foregroundColor: _text,
        elevation: 0,
        title: const Text(
          'Sobre',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF103D3D), Color(0xFF102B40)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _green.withValues(alpha: 0.45)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_green, _cyan],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.all(Radius.circular(19)),
                      ),
                      child: const Icon(
                        Icons.park_rounded,
                        color: _background,
                        size: 34,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Descarte Inteligente',
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Tecnologia a favor de uma cidade mais sustentável.',
                      style: TextStyle(color: _muted, height: 1.5, fontSize: 13),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'O que você encontra aqui',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildAboutFeature(
                icon: Icons.search_rounded,
                accent: _cyan,
                title: 'Identificação de resíduos',
                description: 'Consulte materiais e encontre orientações para o descarte correto.',
              ),
              const SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.chat_bubble_outline_rounded,
                accent: _green,
                title: 'Assistente ecológico',
                description: 'Tire dúvidas e receba orientações sobre separação e descarte.',
              ),
              const SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.location_on_outlined,
                accent: const Color(0xFFB8A0FF),
                title: 'Pontos de coleta',
                description: 'Consulte os locais cadastrados e visualize sua localização no mapa.',
              ),
              const SizedBox(height: 24),
              const Text(
                'Como funciona',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildAboutFeature(
                icon: Icons.manage_search_rounded,
                accent: _cyan,
                title: '1. Encontre o resíduo',
                description: 'Pesquise pelo nome do material para consultar informações e orientações.',
              ),
              const SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.lightbulb_outline_rounded,
                accent: _green,
                title: '2. Entenda como descartar',
                description: 'Use o assistente ecológico para esclarecer dúvidas sobre preparo e separação.',
              ),
              const SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.map_outlined,
                accent: const Color(0xFFB8A0FF),
                title: '3. Consulte os pontos',
                description: 'Visualize os locais cadastrados no mapa e confira as informações disponíveis.',
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.memory_rounded, color: _cyan, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Tecnologias do projeto',
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Flutter e Dart • Aplicativo mobile',
                      style: TextStyle(color: _text, fontWeight: FontWeight.w700, fontSize: 12.5),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Python e FastAPI • Serviços de backend',
                      style: TextStyle(color: _muted, fontSize: 12.5),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'PostgreSQL • Banco de dados',
                      style: TextStyle(color: _muted, fontSize: 12.5),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Inteligência artificial e geolocalização • Apoio à identificação e consulta de pontos',
                      style: TextStyle(color: _muted, fontSize: 12.5, height: 1.4),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: _green, size: 19),
                        SizedBox(width: 8),
                        Text(
                          'Informações importantes',
                          style: TextStyle(
                            color: _text,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    Text(
                      'O aplicativo está em desenvolvimento e tem como foco orientar a identificação e o descarte correto de resíduos em São Carlos - SP.',
                      style: TextStyle(color: _muted, height: 1.5, fontSize: 12.5),
                    ),
                    SizedBox(height: 10),
                    Text(
                      'Os pontos exibidos dependem dos dados cadastrados. Antes de se deslocar, confirme diretamente com o estabelecimento se ele recebe o material desejado.',
                      style: TextStyle(color: _muted, height: 1.5, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const Center(
                child: Text(
                  'Descarte Inteligente • São Carlos - SP',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutFeature({
    required IconData icon,
    required Color accent,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: accent, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: _text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const ChatScreen(),
          const IdentificationScreen(),
          const CollectionPointsScreen(),
          _buildAboutScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 62,
        backgroundColor: const Color(0xFF091923),
        indicatorColor: _green.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? _green : _muted,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          );
        }),
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigation,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded, color: _green),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_rounded, color: _green),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded, color: _green),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded, color: _green),
            label: 'Pontos',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline_rounded),
            selectedIcon: Icon(Icons.info_rounded, color: _green),
            label: 'Sobre',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.16),
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: const Icon(Icons.park_rounded, color: _background, size: 30),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Descarte Inteligente',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
              SizedBox(height: 3),
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: _green, size: 13),
                  SizedBox(width: 3),
                  Text(
                    'São Carlos - SP',
                    style: TextStyle(
                      color: _muted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: _surfaceRaised,
            shape: BoxShape.circle,
            border: Border.all(color: _border),
          ),
          child: IconButton(
            tooltip: 'Sobre',
            onPressed: _showAbout,
            icon: const Icon(
              Icons.info_outline_rounded,
              color: _muted,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: _openChat,
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF103D3D), Color(0xFF102B40)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _green.withValues(alpha: 0.72)),
            boxShadow: [
              BoxShadow(
                color: _green.withValues(alpha: 0.06),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _green.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _green.withValues(alpha: 0.28)),
                ),
                child: const Icon(
                  Icons.chat_rounded,
                  color: _green,
                  size: 23,
                  shadows: [
                    Shadow(color: Color(0x9955D6A2), blurRadius: 9),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Chat inteligente',
                      style: TextStyle(
                        color: _text,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Tire suas dúvidas sobre descarte',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right_rounded, color: _green, size: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionCard() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: _openCollectionPoints,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 17),
          decoration: BoxDecoration(
            color: _surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _border),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _cyan.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.location_on_outlined,
                  color: _cyan,
                  size: 29,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pontos de coleta',
                      style: TextStyle(
                        color: _text,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Consulte os locais cadastrados no aplicativo.',
                      style: TextStyle(
                        color: _muted,
                        fontSize: 12.5,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded, color: _cyan, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 17),
      decoration: BoxDecoration(
        color: const Color(0xFF0B202A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.eco_outlined, color: _green, size: 25),
          ),
          const SizedBox(width: 13),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pequenas atitudes,',
                  style: TextStyle(
                    color: _text,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  'grandes mudanças.',
                  style: TextStyle(
                    color: _green,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'O descarte correto ajuda a construir uma cidade mais sustentável.',
                  style: TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.auto_awesome_rounded, color: _green, size: 25),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color accent;
  final bool disabled;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.accent,
    this.disabled = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF0D202B),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 172),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFF204653)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: accent.withValues(alpha: 0.26)),
                ),
                child: Icon(icon, color: accent, size: 25),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xFFF2F8FA),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                description,
                style: const TextStyle(
                  color: Color(0xFFADC1CC),
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              if (disabled) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF172F3C),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'Em breve',
                    style: TextStyle(
                      color: Color(0xFFADC1CC),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
