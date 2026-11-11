import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'calendar_models.dart';

@immutable
class TimeboardStatusColors {
  const TimeboardStatusColors({required this.fill, required this.text});
  final Color fill;
  final Color text;

  @override
  bool operator ==(Object other) =>
      other is TimeboardStatusColors &&
      other.fill == fill &&
      other.text == text;

  @override
  int get hashCode => Object.hash(fill, text);
}

/// Design tokens for the calendar. The host can pass its own instance (or
/// `copyWith` one of the presets) to restyle without forking widgets.
@immutable
class TimeboardTheme {
  const TimeboardTheme({
    required this.surfaceCanvas,
    required this.surfaceSubtle,
    required this.surfaceBrandSubtle,
    required this.surfaceToday,
    required this.borderDefault,
    required this.borderGrid,
    required this.contentPrimary,
    required this.contentSecondary,
    required this.contentMuted,
    required this.contentBrand,
    required this.actionPrimary,
    required this.contentOnAction,
    required this.todayMarker,
    required this.error,
    required this.confirmed,
    required this.out,
    required this.returned,
    required this.draft,
    required this.conflict,
    required this.draftSolid,
    this.task = const TimeboardStatusColors(
      fill: Color(0xFFEDE7FB),
      text: Color(0xFF5B2DB3),
    ),
    this.fontFamily = 'Inter',
    this.panelRadius = 16,
    this.chipRadius = 8,
    this.controlRadius = 10,
  });

  /// A theme in the shape of [base] (the light or dark preset by default)
  /// with [brand] as its accent: action buttons, the active tab, the "today"
  /// wash and confirmed bookings all follow it.
  factory TimeboardTheme.fromSeed(
    Color brand, {
    Brightness brightness = Brightness.light,
    TimeboardTheme? base,
  }) {
    final dark = brightness == Brightness.dark;
    final b = base ?? (dark ? TimeboardTheme.dark : TimeboardTheme.light);
    // On a dark canvas the brand has to be light enough to read as text.
    final text = dark
        ? HSLColor.fromColor(brand).withLightness(0.74).toColor()
        : HSLColor.fromColor(brand).withLightness(0.24).toColor();
    final tint = Color.alphaBlend(
      brand.withValues(alpha: dark ? 0.18 : 0.10),
      b.surfaceCanvas,
    );
    return b.copyWith(
      surfaceBrandSubtle: tint,
      surfaceToday: tint,
      contentBrand: text,
      actionPrimary: brand,
      confirmed: TimeboardStatusColors(fill: tint, text: text),
    );
  }

  final Color surfaceCanvas;
  final Color surfaceSubtle;
  final Color surfaceBrandSubtle;
  final Color surfaceToday;
  final Color borderDefault;
  final Color borderGrid;
  final Color contentPrimary;
  final Color contentSecondary;
  final Color contentMuted;
  final Color contentBrand;
  final Color actionPrimary;
  final Color contentOnAction;
  final Color todayMarker;
  final Color error;
  final TimeboardStatusColors confirmed;
  final TimeboardStatusColors out;
  final TimeboardStatusColors returned;
  final TimeboardStatusColors draft;
  final TimeboardStatusColors conflict;

  /// Month-grid chip for drafts (solid, stronger than [draft]).
  final TimeboardStatusColors draftSolid;

  /// Tasks on their due date — see [TimeboardBookingStatus.task].
  final TimeboardStatusColors task;

  /// The design uses Inter. The package does not bundle it; the host app
  /// registers the font, and Flutter falls back to the default if it is missing.
  final String? fontFamily;

  /// Corner radius of the calendar panel, of event chips and blocks, and of
  /// the toolbar buttons.
  final double panelRadius;
  final double chipRadius;
  final double controlRadius;

  static const light = TimeboardTheme(
    surfaceCanvas: Color(0xFFFFFFFF),
    surfaceSubtle: Color(0xFFF7F7F7),
    surfaceBrandSubtle: Color(0xFFF2FBFF),
    surfaceToday: Color(0xFFF2FBFF),
    borderDefault: Color(0xFFD9D9D9),
    borderGrid: Color(0xFFD9D9D9),
    contentPrimary: Color(0xFF191919),
    contentSecondary: Color(0xFF333333),
    contentMuted: Color(0xFF666666),
    contentBrand: Color(0xFF004F76),
    actionPrimary: Color(0xFF004F76),
    contentOnAction: Color(0xFFFFFFFF),
    todayMarker: Color(0xFF2EAD2E),
    error: Color(0xFFFF0000),
    confirmed: TimeboardStatusColors(
      fill: Color(0xFFE8F4FA),
      text: Color(0xFF004F76),
    ),
    out: TimeboardStatusColors(
      fill: Color(0xFFFFF7CC),
      text: Color(0xFF765900),
    ),
    returned: TimeboardStatusColors(
      fill: Color(0xFFDFF5D8),
      text: Color(0xFF176A0A),
    ),
    draft: TimeboardStatusColors(
      fill: Color(0xFFE6E6E6),
      text: Color(0xFF4A4A4A),
    ),
    conflict: TimeboardStatusColors(
      fill: Color(0xFFFFE3E3),
      text: Color(0xFF9B1C1C),
    ),
    draftSolid: TimeboardStatusColors(
      fill: Color(0xFF666666),
      text: Color(0xFFFFFFFF),
    ),
  );

  static const dark = TimeboardTheme(
    surfaceCanvas: Color(0xFF191919),
    surfaceSubtle: Color(0xFF333333),
    surfaceBrandSubtle: Color(0xFF00202F),
    surfaceToday: Color(0xFF122B37),
    borderDefault: Color(0xFF666666),
    borderGrid: Color(0xFF474747),
    contentPrimary: Color(0xFFFFFFFF),
    contentSecondary: Color(0xFFF7F7F7),
    contentMuted: Color(0xFF9A9A9A),
    contentBrand: Color(0xFF5FA5C8),
    actionPrimary: Color(0xFF0876A8),
    contentOnAction: Color(0xFFFFFFFF),
    todayMarker: Color(0xFF7ED957),
    error: Color(0xFFFF6666),
    confirmed: TimeboardStatusColors(
      fill: Color(0xFF102B38),
      text: Color(0xFFB8E5F7),
    ),
    out: TimeboardStatusColors(
      fill: Color(0xFF3D3213),
      text: Color(0xFFFFE082),
    ),
    returned: TimeboardStatusColors(
      fill: Color(0xFF163C27),
      text: Color(0xFFA7E889),
    ),
    draft: TimeboardStatusColors(
      fill: Color(0xFF353535),
      text: Color(0xFFE5E5E5),
    ),
    conflict: TimeboardStatusColors(
      fill: Color(0xFF48212A),
      text: Color(0xFFFFB4BC),
    ),
    draftSolid: TimeboardStatusColors(
      fill: Color(0xFF353535),
      text: Color(0xFFE5E5E5),
    ),
    task: TimeboardStatusColors(
      fill: Color(0xFF2E2445),
      text: Color(0xFFD7C8FF),
    ),
  );

  TimeboardStatusColors statusColors(TimeboardBookingStatus s) => switch (s) {
    TimeboardBookingStatus.confirmed => confirmed,
    TimeboardBookingStatus.out => out,
    TimeboardBookingStatus.returned => returned,
    TimeboardBookingStatus.draft => draft,
    TimeboardBookingStatus.conflict => conflict,
    TimeboardBookingStatus.overdue => conflict,
    TimeboardBookingStatus.cancelled => draft,
    TimeboardBookingStatus.task => task,
  };

  /// [lineHeight] is in logical pixels, as in the Figma text styles.
  TextStyle text(
    double size,
    FontWeight weight,
    Color color, {
    double? lineHeight,
  }) => TextStyle(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    color: color,
    height: lineHeight == null ? 1.3 : lineHeight / size,
    letterSpacing: 0,
  );

  TimeboardTheme copyWith({
    Color? surfaceCanvas,
    Color? surfaceSubtle,
    Color? surfaceBrandSubtle,
    Color? surfaceToday,
    Color? borderDefault,
    Color? borderGrid,
    Color? contentPrimary,
    Color? contentSecondary,
    Color? contentMuted,
    Color? contentBrand,
    Color? actionPrimary,
    Color? contentOnAction,
    Color? todayMarker,
    Color? error,
    TimeboardStatusColors? confirmed,
    TimeboardStatusColors? out,
    TimeboardStatusColors? returned,
    TimeboardStatusColors? draft,
    TimeboardStatusColors? conflict,
    TimeboardStatusColors? draftSolid,
    TimeboardStatusColors? task,
    String? fontFamily,
    double? panelRadius,
    double? chipRadius,
    double? controlRadius,
  }) => TimeboardTheme(
    surfaceCanvas: surfaceCanvas ?? this.surfaceCanvas,
    surfaceSubtle: surfaceSubtle ?? this.surfaceSubtle,
    surfaceBrandSubtle: surfaceBrandSubtle ?? this.surfaceBrandSubtle,
    surfaceToday: surfaceToday ?? this.surfaceToday,
    borderDefault: borderDefault ?? this.borderDefault,
    borderGrid: borderGrid ?? this.borderGrid,
    contentPrimary: contentPrimary ?? this.contentPrimary,
    contentSecondary: contentSecondary ?? this.contentSecondary,
    contentMuted: contentMuted ?? this.contentMuted,
    contentBrand: contentBrand ?? this.contentBrand,
    actionPrimary: actionPrimary ?? this.actionPrimary,
    contentOnAction: contentOnAction ?? this.contentOnAction,
    todayMarker: todayMarker ?? this.todayMarker,
    error: error ?? this.error,
    confirmed: confirmed ?? this.confirmed,
    out: out ?? this.out,
    returned: returned ?? this.returned,
    draft: draft ?? this.draft,
    conflict: conflict ?? this.conflict,
    draftSolid: draftSolid ?? this.draftSolid,
    task: task ?? this.task,
    fontFamily: fontFamily ?? this.fontFamily,
    panelRadius: panelRadius ?? this.panelRadius,
    chipRadius: chipRadius ?? this.chipRadius,
    controlRadius: controlRadius ?? this.controlRadius,
  );

  List<Object?> get _fields => [
    surfaceCanvas,
    surfaceSubtle,
    surfaceBrandSubtle,
    surfaceToday,
    borderDefault,
    borderGrid,
    contentPrimary,
    contentSecondary,
    contentMuted,
    contentBrand,
    actionPrimary,
    contentOnAction,
    todayMarker,
    error,
    confirmed,
    out,
    returned,
    draft,
    conflict,
    draftSolid,
    task,
    fontFamily,
    panelRadius,
    chipRadius,
    controlRadius,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeboardTheme && listEquals(other._fields, _fields);

  @override
  int get hashCode => Object.hashAll(_fields);
}
