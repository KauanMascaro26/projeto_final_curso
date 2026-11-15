import 'dart:math';

import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

import '../chat/chat_screen.dart';
import '../collection_points/collection_points_screen.dart';
import '../identification/identification_screen.dart';
import '../favorites/favorites_screen.dart';
import '../../services/api_service.dart';
import '../../services/favorite_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  AppPalette get _palette => context.appPalette;
  Color get _background => _palette.background;
  Color get _surface => _palette.surface;
  Color get _surfaceRaised => _palette.surfaceRaised;
  static const _green = AppColors.emerald;
  static const _cyan = AppColors.cyan;
  Color get _text => _palette.text;
  Color get _muted => _palette.muted;
  Color get _border => _palette.border;

  Color get _homeBackground => _palette.background;
  Color get _homeSurface => _palette.surface;
  Color get _homeGreen => _palette.primary;
  Color get _homeText => _palette.text;
  Color get _homeMuted => _palette.muted;
  Color get _homeBorder => _palette.border;
  Color get _homeCard => _palette.card;
  Color get _homeCardAccent => _palette.cardAccent;

  int _currentIndex = 0;
  Key _favoritesKey = UniqueKey();
  Key _identificationKey = UniqueKey();
  String? _initialMaterialQuery;

  static const List<_DailyFact> _dailyFacts = [
    _DailyFact(title: 'Separe antes de descartar', text: 'Manter recicláveis separados dos rejeitos ajuda a reduzir a contaminação dos materiais.', icon: Icons.recycling_rounded),
    _DailyFact(title: 'Atenção às pilhas', text: 'Pilhas e baterias precisam de pontos de recebimento específicos. Não descarte no lixo comum.', icon: Icons.battery_charging_full_rounded),
    _DailyFact(title: 'Embalagens limpas', text: 'Retirar restos de alimentos e líquidos das embalagens facilita a triagem dos recicláveis.', icon: Icons.local_drink_outlined),
    _DailyFact(title: 'Óleo de cozinha', text: 'O óleo usado não deve ser despejado na pia. Armazene-o em uma garrafa fechada e procure um ponto de coleta.', icon: Icons.water_drop_outlined),
    _DailyFact(title: 'Papel e papelão', text: 'Papelão seco e sem excesso de resíduos é mais adequado para encaminhamento à reciclagem.', icon: Icons.inventory_2_outlined),
    _DailyFact(title: 'Descarte de vidro', text: 'Envolva cacos de vidro em papel resistente ou coloque-os em embalagem rígida identificada antes do descarte.', icon: Icons.wine_bar_outlined),
    _DailyFact(title: 'Lâmpadas precisam de cuidado', text: 'Lâmpadas fluorescentes e outras com componentes especiais devem ser levadas a pontos de recebimento apropriados.', icon: Icons.lightbulb_outline_rounded),
    _DailyFact(title: 'Eletrônicos não vão ao lixo comum', text: 'Celulares, cabos e pequenos aparelhos podem conter materiais que exigem logística reversa.', icon: Icons.devices_other_rounded),
    _DailyFact(title: 'Reutilizar também ajuda', text: 'Antes de descartar um objeto em bom estado, considere se ele pode ser reutilizado ou doado.', icon: Icons.volunteer_activism_outlined),
    _DailyFact(title: 'Evite misturar recicláveis', text: 'Separar papel, plástico, metal e vidro facilita a triagem e o encaminhamento dos materiais.', icon: Icons.category_outlined),
    _DailyFact(title: 'Medicamentos têm coleta própria', text: 'Medicamentos vencidos ou sem uso devem ser entregues em pontos de coleta específicos, como farmácias participantes.', icon: Icons.medication_outlined),
    _DailyFact(title: 'Pneus têm destinação própria', text: 'Pneus usados devem ser encaminhados a locais de recebimento adequados, nunca abandonados em terrenos ou vias públicas.', icon: Icons.tire_repair_rounded),
    _DailyFact(title: 'Confira antes de levar', text: 'Os pontos de coleta podem aceitar materiais diferentes. Consulte as informações do local antes de se deslocar.', icon: Icons.location_on_outlined),
    _DailyFact(title: 'Cuide dos resíduos cortantes', text: 'Agulhas e objetos perfurocortantes exigem acondicionamento seguro e orientação de descarte específica.', icon: Icons.warning_amber_rounded),
    _DailyFact(title: 'Compostagem reduz resíduos', text: 'Restos de frutas, verduras e borra de café podem ser aproveitados em sistemas de compostagem adequados.', icon: Icons.grass_rounded),
  ];

  late final _DailyFact _dailyFact;
  late Future<_HomeStats> _homeStats;

  @override
  void initState() {
    super.initState();
    _dailyFact = _dailyFacts[Random().nextInt(_dailyFacts.length)];
    _homeStats = _loadHomeStats();
  }

  Future<_HomeStats> _loadHomeStats() async {
    final results = await Future.wait([
      ApiService.getCollectionPoints(),
      ApiService.getWasteTypes(),
      FavoriteService.getAll(),
    ]);
    final points = results[0] as List;
    final materials = results[1] as List;
    final favorites = (results[2] as List)
        .where((item) => item is Map && item['type'] == 'point')
        .length;
    return _HomeStats(
      collectionPoints: points.length,
      materials: materials.length,
      favorites: favorites,
    );
  }

  void _openChat() => setState(() => _currentIndex = 1);

  void _openIdentification([String? material]) => setState(() {
        _initialMaterialQuery = material;
        _identificationKey = UniqueKey();
        _currentIndex = 2;
      });

  void _openCollectionPoints() => setState(() => _currentIndex = 3);

  void _showAbout() => setState(() => _currentIndex = 5);

  void _onNavigation(int index) {
    setState(() {
      _currentIndex = index;
      if (index == 4) _favoritesKey = UniqueKey();
      if (index == 0) _homeStats = _loadHomeStats();
    });
  }

  Widget _buildHomeContent() {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(15, 14, 15, 17),
                    decoration: BoxDecoration(
                      color: _homeCard,
                      borderRadius: BorderRadius.circular(23),
                      border: Border.all(color: _homeBorder),
                    ),
                    child: Column(
                      children: [
                        _buildHeader(),
                        SizedBox(height: 13),
                        _buildStatsCard(),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Materiais',
                        style: TextStyle(color: _homeText, fontSize: 18, fontWeight: FontWeight.w800),
                      ),
                      TextButton(
                        onPressed: () => _openIdentification(),
                        style: TextButton.styleFrom(
                          foregroundColor: _homeGreen,
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(40, 32),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: Text('Ver todos'),
                      ),
                    ],
                  ),
                  SizedBox(height: 10),
                  _buildMaterialShortcuts(),
                  SizedBox(height: 24),
                  _buildDailyFactCard(),
                  SizedBox(height: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCard() {
    return FutureBuilder<_HomeStats>(
      future: _homeStats,
      builder: (context, snapshot) {
        final stats = snapshot.data;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          decoration: BoxDecoration(
            color: _homeCard,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.location_on_outlined,
                  value: stats?.collectionPoints.toString() ?? '—',
                  label: 'pontos cadastrados',
                  dark: true,
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0x6655A982)),
              Expanded(
                child: _StatItem(
                  icon: Icons.category_outlined,
                  value: stats?.materials.toString() ?? '—',
                  label: 'materiais',
                  dark: true,
                ),
              ),
              Container(width: 1, height: 42, color: const Color(0x6655A982)),
              Expanded(
                child: _StatItem(
                  icon: Icons.favorite_border_rounded,
                  value: stats?.favorites.toString() ?? '—',
                  label: 'favoritos',
                  dark: true,
                ),
              ),
            ],
          ),
        );
      },
    );
  }


  String _greetingForCurrentTime() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia, ';
    if (hour < 18) return 'Boa tarde, ';
    return 'Boa noite, ';
  }

  Widget _buildHeader() {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(17),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: _homeCardAccent,
          borderRadius: BorderRadius.circular(17),
        ),
        child: Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _openChat,
                borderRadius: BorderRadius.circular(15),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _homeCard.withValues(alpha: 0.35),
                              blurRadius: 12,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.auto_awesome_rounded,
                          color: Color(0xFF164B40),
                          size: 25,
                        ),
                      ),
                      SizedBox(width: 11),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: _homeGreen,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              letterSpacing: -0.2,
                            ),
                            children: [
                              TextSpan(text: _greetingForCurrentTime()),
                              TextSpan(
                                text: 'Kauan!',
                                style: TextStyle(
                                  color: _homeGreen,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _homeGreen,
                        size: 16,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            AppThemeToggleButton(color: _homeGreen),
          ],
        ),
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
        title: Text(
          'Sobre',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        actions: [AppThemeToggleButton()],
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
                  color: _homeCard,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _homeBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: _homeCardAccent,
                        borderRadius: BorderRadius.circular(19),
                      ),
                      child: Icon(
                        Icons.park_rounded,
                        color: _homeGreen,
                        size: 34,
                      ),
                    ),
                    SizedBox(height: 18),
                    Text(
                      'Descarte Inteligente',
                      style: TextStyle(
                        color: _text,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.4,
                      ),
                    ),
                    SizedBox(height: 7),
                    Text(
                      'Tecnologia a favor de uma cidade mais sustentável.',
                      style: TextStyle(color: _muted, height: 1.5, fontSize: 13),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              Text(
                'O que você encontra aqui',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12),
              _buildAboutFeature(
                icon: Icons.search_rounded,
                accent: _cyan,
                title: 'Identificação de resíduos',
                description: 'Consulte materiais e encontre orientações para o descarte correto.',
              ),
              SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.chat_bubble_outline_rounded,
                accent: _green,
                title: 'Assistente ecológico',
                description: 'Tire dúvidas e receba orientações sobre separação e descarte.',
              ),
              SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.location_on_outlined,
                accent: const Color(0xFFB8A0FF),
                title: 'Pontos de coleta',
                description: 'Consulte os locais cadastrados e visualize sua localização no mapa.',
              ),
              SizedBox(height: 24),
              Text(
                'Como funciona',
                style: TextStyle(
                  color: _text,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 12),
              _buildAboutFeature(
                icon: Icons.manage_search_rounded,
                accent: _cyan,
                title: '1. Encontre o resíduo',
                description: 'Pesquise pelo nome do material para consultar informações e orientações.',
              ),
              SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.lightbulb_outline_rounded,
                accent: _green,
                title: '2. Entenda como descartar',
                description: 'Use o assistente ecológico para esclarecer dúvidas sobre preparo e separação.',
              ),
              SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.map_outlined,
                accent: const Color(0xFFB8A0FF),
                title: '3. Consulte os pontos',
                description: 'Visualize os locais cadastrados no mapa e confira as informações disponíveis.',
              ),
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(
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
              SizedBox(height: 24),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: _border),
                ),
                child: Column(
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
              SizedBox(height: 18),
              Center(
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
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
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
      backgroundColor: _homeBackground,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _buildHomeContent(),
          const ChatScreen(),
          IdentificationScreen(key: _identificationKey, initialQuery: _initialMaterialQuery),
          const CollectionPointsScreen(),
          FavoritesScreen(key: _favoritesKey),
          _buildAboutScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        height: 62,
        backgroundColor: _palette.navigationBackground,
        indicatorColor: _green.withValues(alpha: 0.18),
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? _green : _palette.navigationForeground,
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
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded, color: _green),
            label: 'Favoritos',
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
            color: _homeCard,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: _homeBorder),
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
                  color: _homeCardAccent,
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: _homeBorder),
                ),
                child: Icon(
                  Icons.chat_rounded,
                  color: _homeGreen,
                  size: 23,
                  shadows: [
                    Shadow(color: Color(0x9955D6A2), blurRadius: 9),
                  ],
                ),
              ),
              SizedBox(width: 14),
              Expanded(
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
              SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: _homeGreen, size: 28),
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
                child: Icon(
                  Icons.location_on_outlined,
                  color: _cyan,
                  size: 29,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
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
              Icon(Icons.arrow_forward_rounded, color: _cyan, size: 21),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialShortcuts() {
    const materials = <_MaterialShortcut>[
      _MaterialShortcut('Plástico', Icons.local_drink_outlined, 'plástico'),
      _MaterialShortcut('Vidro', Icons.wine_bar_outlined, 'vidro'),
      _MaterialShortcut('Papel', Icons.description_outlined, 'papel'),
      _MaterialShortcut('Metal', Icons.settings_outlined, 'metal'),
      _MaterialShortcut('Pilhas', Icons.battery_full_rounded, 'pilha'),
      _MaterialShortcut('Eletrônicos', Icons.devices_other_rounded, 'eletrônico'),
      _MaterialShortcut('Óleo', Icons.water_drop_outlined, 'óleo'),
      _MaterialShortcut('Papelão', Icons.inventory_2_outlined, 'papelão'),
    ];

    return SizedBox(
      height: 142,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: materials.length,
        separatorBuilder: (_, _) => SizedBox(width: 11),
        itemBuilder: (context, index) {
          final material = materials[index];
          return SizedBox(
            width: 112,
            child: Material(
              color: _homeCard,
              borderRadius: BorderRadius.circular(17),
              child: InkWell(
                onTap: () => _openIdentification(material.query),
                borderRadius: BorderRadius.circular(17),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(10, 13, 10, 11),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(17),
                    border: Border.all(color: const Color(0x6655A982)),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _homeCardAccent,
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(material.icon, color: _homeGreen, size: 29),
                      ),
                      SizedBox(height: 11),
                      Text(
                        material.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: _homeText, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDailyFactCard() {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: _homeCard,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _homeBorder),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -24,
            child: Icon(Icons.eco_rounded, size: 142, color: _homeGreen.withValues(alpha: 0.06)),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _homeCardAccent,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: _homeGreen, size: 14),
                          SizedBox(width: 6),
                          Text('VOCÊ SABIA?', style: TextStyle(color: _homeGreen, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1)),
                        ],
                      ),
                    ),
                    Spacer(),
                    Icon(_dailyFact.icon, color: _homeGreen, size: 23),
                  ],
                ),
                SizedBox(height: 17),
                Text(
                  _dailyFact.title,
                  style: TextStyle(color: _homeText, fontSize: 19, height: 1.15, fontWeight: FontWeight.w900, letterSpacing: -0.35),
                ),
                SizedBox(height: 8),
                ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 290),
                  child: Text(
                    _dailyFact.text,
                    style: TextStyle(color: _homeMuted, fontSize: 12.5, height: 1.5),
                  ),
                ),
                SizedBox(height: 15),
              ],
            ),
          ),
        ],
      ),
    );
  }

}

class _HomeStats {
  final int collectionPoints;
  final int materials;
  final int favorites;

  const _HomeStats({
    required this.collectionPoints,
    required this.materials,
    required this.favorites,
  });
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final bool dark;

  const _StatItem({
    required this.icon,
    required this.value,
    required this.label,
    this.dark = false,
  });

  @override
  Widget build(BuildContext context) {
    final palette = context.appPalette;
    final foreground = palette.text;
    final secondary = palette.muted;
    return Column(
      children: [
        Icon(icon, color: palette.primary, size: 18),
        SizedBox(height: 7),
        Text(
          value,
          style: TextStyle(color: foreground, fontSize: 19, fontWeight: FontWeight.w900, height: 1),
        ),
        SizedBox(height: 5),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: secondary, fontSize: 9.5, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _DailyFact {
  final String title;
  final String text;
  final IconData icon;
  const _DailyFact({required this.title, required this.text, required this.icon});
}

class _MaterialShortcut {
  final String label;
  final IconData icon;
  final String query;
  const _MaterialShortcut(this.label, this.icon, this.query);
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
      color: context.appPalette.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: BoxConstraints(minHeight: 172),
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: context.appPalette.border),
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
              SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  color: context.appPalette.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 5),
              Text(
                description,
                style: TextStyle(
                  color: context.appPalette.muted,
                  fontSize: 11.5,
                  height: 1.35,
                ),
              ),
              if (disabled) ...[
                SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: context.appPalette.surfaceRaised,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Em breve',
                    style: TextStyle(
                      color: context.appPalette.muted,
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
