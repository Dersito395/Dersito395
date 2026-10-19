import 'package:flutter/material.dart';

/// Paleta oficial do SOBREVIVA.
abstract final class Palette {
  static const militaryGreen = Color(0xFF364536);
  static const darkGreen = Color(0xFF1D2922);
  static const graphite = Color(0xFF242827);
  static const white = Color(0xFFF7F7F3);
  static const safetyOrange = Color(0xFFE58A32);
  static const danger = Color(0xFFB23A30);
  static const ok = Color(0xFF2E6B45);
}

/// Cores semânticas extras usadas em cuidados, alertas e emergências.
@immutable
class FieldColors extends ThemeExtension<FieldColors> {
  const FieldColors({
    required this.caution,
    required this.onCaution,
    required this.danger,
    required this.onDanger,
    required this.okColor,
    required this.cardBorder,
  });
  final Color caution;
  final Color onCaution;
  final Color danger;
  final Color onDanger;
  final Color okColor;
  final Color cardBorder;

  @override
  FieldColors copyWith({Color? caution, Color? onCaution, Color? danger, Color? onDanger, Color? okColor, Color? cardBorder}) => FieldColors(
    caution: caution ?? this.caution,
    onCaution: onCaution ?? this.onCaution,
    danger: danger ?? this.danger,
    onDanger: onDanger ?? this.onDanger,
    okColor: okColor ?? this.okColor,
    cardBorder: cardBorder ?? this.cardBorder,
  );

  @override
  FieldColors lerp(FieldColors? other, double t) => other ?? this;
}

extension FieldColorsX on BuildContext {
  FieldColors get field => Theme.of(this).extension<FieldColors>()!;
}

enum ThemeVariant { light, dark, outdoor, batterySaver }

ThemeData buildTheme(ThemeVariant variant) {
  final scheme = switch (variant) {
    ThemeVariant.light => const ColorScheme(
      brightness: Brightness.light,
      primary: Palette.militaryGreen,
      onPrimary: Palette.white,
      primaryContainer: Color(0xFFD5DED2),
      onPrimaryContainer: Palette.darkGreen,
      secondary: Palette.safetyOrange,
      onSecondary: Palette.darkGreen,
      secondaryContainer: Color(0xFFF8E0C6),
      onSecondaryContainer: Color(0xFF4A2A06),
      tertiary: Palette.darkGreen,
      onTertiary: Palette.white,
      error: Palette.danger,
      onError: Palette.white,
      surface: Palette.white,
      onSurface: Palette.graphite,
      onSurfaceVariant: Color(0xFF555B54),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF1F1EB),
      surfaceContainer: Color(0xFFEAEAE3),
      surfaceContainerHigh: Color(0xFFE3E4DC),
      surfaceContainerHighest: Color(0xFFDCDDD4),
      outline: Color(0xFF8A8F86),
      outlineVariant: Color(0xFFCDD0C7),
    ),
    ThemeVariant.dark || ThemeVariant.batterySaver => ColorScheme(
      brightness: Brightness.dark,
      primary: const Color(0xFFA9C2A5),
      onPrimary: Palette.darkGreen,
      primaryContainer: Palette.militaryGreen,
      onPrimaryContainer: Palette.white,
      secondary: Palette.safetyOrange,
      onSecondary: Palette.darkGreen,
      secondaryContainer: const Color(0xFF5A3814),
      onSecondaryContainer: const Color(0xFFFBE3C8),
      tertiary: const Color(0xFFCFE0CB),
      onTertiary: Palette.darkGreen,
      error: const Color(0xFFFF8A80),
      onError: Palette.darkGreen,
      surface: variant == ThemeVariant.batterySaver ? Colors.black : Palette.darkGreen,
      onSurface: Palette.white,
      onSurfaceVariant: const Color(0xFFC3C8BF),
      surfaceContainerLowest: variant == ThemeVariant.batterySaver ? Colors.black : const Color(0xFF162019),
      surfaceContainerLow: variant == ThemeVariant.batterySaver ? const Color(0xFF0B0B0B) : const Color(0xFF223027),
      surfaceContainer: variant == ThemeVariant.batterySaver ? const Color(0xFF121212) : Palette.graphite,
      surfaceContainerHigh: variant == ThemeVariant.batterySaver ? const Color(0xFF181818) : const Color(0xFF2D3331),
      surfaceContainerHighest: variant == ThemeVariant.batterySaver ? const Color(0xFF1F1F1F) : const Color(0xFF363C3A),
      outline: const Color(0xFF8D948B),
      outlineVariant: const Color(0xFF414A44),
    ),
    ThemeVariant.outdoor => const ColorScheme(
      brightness: Brightness.light,
      primary: Palette.darkGreen,
      onPrimary: Colors.white,
      primaryContainer: Color(0xFFCFDACB),
      onPrimaryContainer: Colors.black,
      secondary: Color(0xFFB85F0B),
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFFFFD8B0),
      onSecondaryContainer: Colors.black,
      tertiary: Colors.black,
      onTertiary: Colors.white,
      error: Color(0xFF9E1C12),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: Colors.black,
      onSurfaceVariant: Color(0xFF1E1E1E),
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: Color(0xFFF4F4F4),
      surfaceContainer: Color(0xFFEDEDED),
      surfaceContainerHigh: Color(0xFFE5E5E5),
      surfaceContainerHighest: Color(0xFFDDDDDD),
      outline: Colors.black,
      outlineVariant: Color(0xFF555555),
    ),
  };

  final dark = scheme.brightness == Brightness.dark;
  final outdoor = variant == ThemeVariant.outdoor;
  final base = ThemeData(colorScheme: scheme, useMaterial3: true, visualDensity: VisualDensity.standard);
  final textTheme = base.textTheme
      .apply(bodyColor: scheme.onSurface, displayColor: scheme.onSurface)
      .copyWith(
        headlineSmall: base.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.3, color: scheme.onSurface),
        titleLarge: base.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.2, color: scheme.onSurface),
        titleMedium: base.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700, color: scheme.onSurface),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.45, color: scheme.onSurface, fontWeight: outdoor ? FontWeight.w600 : null),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4, color: scheme.onSurface, fontWeight: outdoor ? FontWeight.w600 : null),
      );
  final borderColor = outdoor ? Colors.black : scheme.outlineVariant;

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      scrolledUnderElevation: 1,
      centerTitle: false,
      titleTextStyle: textTheme.titleLarge,
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: scheme.surfaceContainerLow,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: borderColor, width: outdoor ? 1.5 : 1),
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: dark ? scheme.surfaceContainerLowest : scheme.surfaceContainerLow,
      indicatorColor: scheme.secondary.withValues(alpha: dark ? 0.35 : 0.3),
      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium?.copyWith(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onSurface)),
      iconTheme: WidgetStatePropertyAll(IconThemeData(color: scheme.onSurface)),
    ),
    chipTheme: base.chipTheme.copyWith(
      side: BorderSide(color: borderColor),
      labelStyle: textTheme.labelLarge?.copyWith(color: scheme.onSurface, fontWeight: FontWeight.w600),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: dark ? scheme.surfaceContainerHigh : Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: borderColor, width: outdoor ? 2 : 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: scheme.secondary, width: 2),
      ),
    ),
    dividerTheme: DividerThemeData(color: borderColor, space: 1),
    pageTransitionsTheme: variant == ThemeVariant.batterySaver
        ? const PageTransitionsTheme(builders: {TargetPlatform.android: _NoTransitionBuilder(), TargetPlatform.iOS: _NoTransitionBuilder()})
        : base.pageTransitionsTheme,
    extensions: [
      FieldColors(
        caution: dark ? const Color(0xFF4A3214) : (outdoor ? const Color(0xFFFFE0B8) : const Color(0xFFFBEBD8)),
        onCaution: dark ? const Color(0xFFFFE2C2) : Colors.black,
        danger: dark ? const Color(0xFF5C1F1A) : (outdoor ? const Color(0xFF9E1C12) : Palette.danger),
        onDanger: Colors.white,
        okColor: dark ? const Color(0xFF8FD3A5) : Palette.ok,
        cardBorder: borderColor,
      ),
    ],
  );
}

class _NoTransitionBuilder extends PageTransitionsBuilder {
  const _NoTransitionBuilder();
  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation, Widget child) =>
      child;
}

/// Ícones das categorias e guias (nomes definidos no conteúdo editorial).
const Map<String, IconData> contentIcons = {
  'crisis': Icons.crisis_alert,
  'coronavirus': Icons.coronavirus_outlined,
  'no_food': Icons.no_food_outlined,
  'power_off': Icons.power_off_outlined,
  'shield': Icons.shield_outlined,
  'agriculture': Icons.agriculture_outlined,
  'water_drop': Icons.water_drop_outlined,
  'restaurant': Icons.restaurant_outlined,
  'cabin': Icons.cabin_outlined,
  'medical_services': Icons.medical_services_outlined,
  'explore': Icons.explore_outlined,
  'local_fire_department': Icons.local_fire_department_outlined,
  'backpack': Icons.backpack_outlined,
  'location_city': Icons.location_city_outlined,
  'forest': Icons.forest_outlined,
  'eco': Icons.eco_outlined,
  'cell_tower': Icons.cell_tower,
  'fact_check': Icons.fact_check_outlined,
  'monitor_heart': Icons.monitor_heart_outlined,
  'sick': Icons.sick_outlined,
  'bloodtype': Icons.bloodtype_outlined,
  'flood': Icons.flood_outlined,
  'ac_unit': Icons.ac_unit,
  'wb_sunny': Icons.wb_sunny_outlined,
  'pest_control': Icons.pest_control_outlined,
  'explore_off': Icons.explore_off_outlined,
  'person_search': Icons.person_search_outlined,
};

IconData iconFor(String name) => contentIcons[name] ?? Icons.menu_book_outlined;
