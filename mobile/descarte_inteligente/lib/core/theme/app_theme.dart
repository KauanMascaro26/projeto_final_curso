import 'package:flutter/material.dart';

abstract final class AppColors {
  static const emerald = Color(0xFF55D6A2);
  static const cyan = Color(0xFF53D9F5);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color background;
  final Color surface;
  final Color surfaceRaised;
  final Color card;
  final Color cardAccent;
  final Color text;
  final Color muted;
  final Color border;
  final Color primary;
  final Color primaryForeground;
  final Color navigationBackground;
  final Color navigationForeground;

  const AppPalette({
    required this.background,
    required this.surface,
    required this.surfaceRaised,
    required this.card,
    required this.cardAccent,
    required this.text,
    required this.muted,
    required this.border,
    required this.primary,
    required this.primaryForeground,
    required this.navigationBackground,
    required this.navigationForeground,
  });

  @override
  AppPalette copyWith({
    Color? background,
    Color? surface,
    Color? surfaceRaised,
    Color? card,
    Color? cardAccent,
    Color? text,
    Color? muted,
    Color? border,
    Color? primary,
    Color? primaryForeground,
    Color? navigationBackground,
    Color? navigationForeground,
  }) {
    return AppPalette(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceRaised: surfaceRaised ?? this.surfaceRaised,
      card: card ?? this.card,
      cardAccent: cardAccent ?? this.cardAccent,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      border: border ?? this.border,
      primary: primary ?? this.primary,
      primaryForeground: primaryForeground ?? this.primaryForeground,
      navigationBackground:
          navigationBackground ?? this.navigationBackground,
      navigationForeground:
          navigationForeground ?? this.navigationForeground,
    );
  }

  @override
  AppPalette lerp(covariant AppPalette? other, double t) {
    if (other == null) return this;

    return AppPalette(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceRaised: Color.lerp(surfaceRaised, other.surfaceRaised, t)!,
      card: Color.lerp(card, other.card, t)!,
      cardAccent: Color.lerp(cardAccent, other.cardAccent, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      border: Color.lerp(border, other.border, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryForeground:
          Color.lerp(primaryForeground, other.primaryForeground, t)!,
      navigationBackground:
          Color.lerp(navigationBackground, other.navigationBackground, t)!,
      navigationForeground:
          Color.lerp(navigationForeground, other.navigationForeground, t)!,
    );
  }
}

extension AppPaletteContext on BuildContext {
  AppPalette get appPalette =>
      Theme.of(this).extension<AppPalette>() ?? AppTheme.lightPalette;
}

class AppThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;

  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  void toggle() {
    _themeMode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
  }
}

final appThemeController = AppThemeController();

class AppThemeToggleButton extends StatelessWidget {
  final Color? color;

  const AppThemeToggleButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = appThemeController.isDark;
    return IconButton(
      tooltip: isDark ? 'Ativar tema claro' : 'Ativar tema escuro',
      onPressed: appThemeController.toggle,
      icon: Icon(
        isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
        color: color ?? Theme.of(context).colorScheme.primary,
      ),
    );
  }
}

abstract final class AppTheme {
  static const lightPalette = AppPalette(
    background: Color(0xFFF7FAF8),
    surface: Color(0xFFFFFFFF),
    surfaceRaised: Color(0xFFF2F6F2),
    card: Color(0xFFE0EDE2),
    cardAccent: Color(0xFFC9DCCB),
    text: Color(0xFF20352B),
    muted: Color(0xFF718078),
    border: Color(0xFFDCE6DE),
    primary: Color(0xFF26734D),
    primaryForeground: Color(0xFFFFFFFF),
    navigationBackground: Color(0xFF091923),
    navigationForeground: Color(0xFFADC1CC),
  );

  static const darkPalette = AppPalette(
    background: Color(0xFF07131D),
    surface: Color(0xFF0D202B),
    surfaceRaised: Color(0xFF122B38),
    card: Color(0xFF1E332A),
    cardAccent: Color(0xFF33483B),
    text: Color(0xFFF2F8FA),
    muted: Color(0xFFADC1CC),
    border: Color(0xFF204653),
    primary: AppColors.emerald,
    primaryForeground: Color(0xFF07131D),
    navigationBackground: Color(0xFF091923),
    navigationForeground: Color(0xFFADC1CC),
  );

  static ThemeData get light =>
      _build(lightPalette, Brightness.light);

  static ThemeData get dark =>
      _build(darkPalette, Brightness.dark);

  static ThemeData _build(AppPalette palette, Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: palette.primary,
      brightness: brightness,
    ).copyWith(
      primary: palette.primary,
      onPrimary: palette.primaryForeground,
      secondary: AppColors.cyan,
      surface: palette.surface,
      onSurface: palette.text,
      surfaceContainerLow: palette.surfaceRaised,
      onSurfaceVariant: palette.muted,
      outlineVariant: palette.border,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      extensions: [palette],
      scaffoldBackgroundColor: palette.background,
      appBarTheme: AppBarTheme(
        backgroundColor: palette.background,
        foregroundColor: palette.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
      ),
      cardTheme: CardThemeData(
        color: palette.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.surfaceRaised,
        hintStyle: TextStyle(color: palette.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: palette.primary, width: 1.5),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: palette.primary,
          foregroundColor: palette.primaryForeground,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
      ),
      dividerColor: palette.border,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: palette.primary,
        selectionColor: palette.primary.withValues(alpha: 0.22),
        selectionHandleColor: palette.primary,
      ),
    );
  }
}
