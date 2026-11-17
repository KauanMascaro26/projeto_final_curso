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
  static const _cyan = AppColors.cyan;
  Color get _text => _palette.text;
  Color get _muted => _palette.muted;
  Color get _border => _palette.border;

  Color get _homeBackground => _palette.background;
  Color get _homeGreen => _palette.primaryForeground;
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
            AppThemeToggleButton(color: _homeText),
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
        title: const Text('Sobre', style: TextStyle(fontWeight: FontWeight.w800)),
        actions: [AppThemeToggleButton()],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: _homeCard,
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: _homeBorder),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -28,
                      child: Icon(Icons.eco_rounded, size: 132,
                        color: _homeGreen.withValues(alpha: 0.08)),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                          decoration: BoxDecoration(
                            color: _homeCardAccent,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.eco_rounded, size: 14, color: _homeGreen),
                            const SizedBox(width: 6),
                            Text('SUSTENTABILIDADE + TECNOLOGIA',
                              style: TextStyle(color: _homeGreen, fontSize: 9,
                                letterSpacing: 0.8, fontWeight: FontWeight.w900)),
                          ]),
                        ),
                        const SizedBox(height: 20),
                        Text('Descarte\nInteligente',
                          style: TextStyle(color: _text, fontSize: 29,
                            height: 1.05, letterSpacing: -0.8, fontWeight: FontWeight.w900)),
                        const SizedBox(height: 10),
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 260),
                          child: Text(
                            'Pequenas atitudes, apoiadas pela tecnologia, ajudam a construir uma cidade mais sustentável.',
                            style: TextStyle(color: _muted, fontSize: 12.5, height: 1.5),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildAboutSectionHeading('O que o app oferece', 'RECURSOS'),
              const SizedBox(height: 13),
              _buildAboutFeature(
                icon: Icons.document_scanner_rounded,
                accent: _cyan,
                title: 'Identificação de resíduos',
                description: 'Consulte materiais e encontre orientações para o descarte correto.',
              ),
              const SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.forum_rounded,
                accent: _homeGreen,
                title: 'Assistente ecológico',
                description: 'Tire dúvidas sobre separação, preparo e descarte de resíduos.',
              ),
              const SizedBox(height: 10),
              _buildAboutFeature(
                icon: Icons.location_on_rounded,
                accent: const Color(0xFFB8A0FF),
                title: 'Pontos de coleta',
                description: 'Encontre locais cadastrados e consulte sua localização no mapa.',
              ),
              const SizedBox(height: 28),
              _buildAboutSectionHeading('Do resíduo ao destino correto', 'COMO FUNCIONA'),
              const SizedBox(height: 15),
              Container(
                padding: const EdgeInsets.all(17),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border),
                ),
                child: Column(
                  children: [
                    _buildAboutStep('01', Icons.search_rounded, 'Identifique',
                      'Pesquise o material que deseja descartar.', _cyan),
                    Padding(
                      padding: const EdgeInsets.only(left: 17),
                      child: Align(alignment: Alignment.centerLeft,
                        child: Container(width: 1, height: 20, color: _border)),
                    ),
                    _buildAboutStep('02', Icons.lightbulb_outline_rounded, 'Receba orientação',
                      'Confira as informações para separar e descartar corretamente.', _homeGreen),
                    Padding(
                      padding: const EdgeInsets.only(left: 17),
                      child: Align(alignment: Alignment.centerLeft,
                        child: Container(width: 1, height: 20, color: _border)),
                    ),
                    _buildAboutStep('03', Icons.map_outlined, 'Encontre um ponto',
                      'Consulte no mapa os locais de coleta disponíveis.', const Color(0xFFB8A0FF)),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              _buildAboutSectionHeading('Desenvolvido com', 'TECNOLOGIA'),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: _border),
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildTechChip('Flutter'),
                    _buildTechChip('Dart'),
                    _buildTechChip('Python'),
                    _buildTechChip('FastAPI'),
                    _buildTechChip('PostgreSQL'),
                    _buildTechChip('Inteligência artificial'),
                    _buildTechChip('Geolocalização'),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _homeCardAccent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: _homeGreen, size: 21),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Informações importantes',
                            style: TextStyle(color: _homeGreen, fontSize: 13,
                              fontWeight: FontWeight.w900)),
                          const SizedBox(height: 7),
                          Text(
                            'O aplicativo está em desenvolvimento e tem como foco orientar a identificação e o descarte correto de resíduos em São Carlos - SP. Os pontos exibidos dependem dos dados cadastrados. Antes de se deslocar, confirme se o local recebe o material desejado.',
                            style: TextStyle(color: _text, fontSize: 11.5, height: 1.55),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Center(
                child: Text('Descarte Inteligente  •  São Carlos - SP',
                  style: TextStyle(color: _muted, fontSize: 10.5, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAboutSectionHeading(String title, String eyebrow) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eyebrow, style: TextStyle(color: _homeGreen, fontSize: 9,
          letterSpacing: 1.2, fontWeight: FontWeight.w900)),
        const SizedBox(height: 5),
        Text(title, style: TextStyle(color: _text, fontSize: 18,
          letterSpacing: -0.3, fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _buildAboutFeature({
    required IconData icon,
    required Color accent,
    required String title,
    required String description,
  }) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(icon, color: accent, size: 23),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: _text, fontSize: 13,
                  fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: _muted,
                  fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward_ios_rounded, color: _muted, size: 13),
        ],
      ),
    );
  }

  Widget _buildAboutStep(String number, IconData icon, String title,
      String description, Color accent) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: accent, size: 19),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$number  $title', style: TextStyle(color: _text,
                  fontSize: 12.5, fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(color: _muted,
                  fontSize: 11.5, height: 1.4)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTechChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      decoration: BoxDecoration(
        color: _homeCardAccent,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: _homeBorder),
      ),
      child: Text(label, style: TextStyle(color: _homeGreen,
        fontSize: 10.5, fontWeight: FontWeight.w800)),
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
        indicatorColor: _palette.cardAccent,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle>((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: _palette.navigationForeground,
            fontSize: 11,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
          );
        }),
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavigation,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.chat_bubble_outline_rounded),
            selectedIcon: Icon(Icons.chat_rounded),
            label: 'Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.search_rounded),
            selectedIcon: Icon(Icons.search_rounded),
            label: 'Buscar',
          ),
          NavigationDestination(
            icon: Icon(Icons.location_on_outlined),
            selectedIcon: Icon(Icons.location_on_rounded),
            label: 'Pontos',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border_rounded),
            selectedIcon: Icon(Icons.favorite_rounded),
            label: 'Favoritos',
          ),
          NavigationDestination(
            icon: Icon(Icons.info_outline_rounded),
            selectedIcon: Icon(Icons.info_rounded),
            label: 'Sobre',
          ),
        ],
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
        Icon(icon, color: palette.primaryForeground, size: 18),
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
