/// How a custom logo image is framed inside its rounded-square icon: a zoom and
/// an offset, as set in the image editor.
///
/// Offsets are fractions of the icon's size (0.1 = a tenth of the icon), so the
/// same framing works at every icon size. Stored as "scale,dx,dy".
class LogoTransform {
  final double scale;
  final double dx;
  final double dy;

  const LogoTransform({this.scale = 1.0, this.dx = 0.0, this.dy = 0.0});

  static const identity = LogoTransform();

  static const double minScale = 0.5;
  static const double maxScale = 4.0;

  bool get isIdentity => (scale - 1).abs() < 0.001 && dx.abs() < 0.001 && dy.abs() < 0.001;

  LogoTransform copyWith({double? scale, double? dx, double? dy}) =>
      LogoTransform(scale: scale ?? this.scale, dx: dx ?? this.dx, dy: dy ?? this.dy);

  /// Compact text form, e.g. "1.25,0.05,-0.1".
  String encode() => '${_round(scale)},${_round(dx)},${_round(dy)}';

  /// Parses [encode]'s form; null for null, empty or malformed input.
  static LogoTransform? decode(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(',');
    if (parts.length != 3) return null;
    final nums = parts.map((p) => double.tryParse(p.trim())).toList();
    if (nums.any((n) => n == null || !n.isFinite)) return null;
    return LogoTransform(
      scale: nums[0]!.clamp(minScale, maxScale),
      dx: nums[1]!.clamp(-1.0, 1.0),
      dy: nums[2]!.clamp(-1.0, 1.0),
    );
  }

  static double _round(double v) => (v * 1000).roundToDouble() / 1000;

  @override
  bool operator ==(Object other) =>
      other is LogoTransform && other.scale == scale && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(scale, dx, dy);

  @override
  String toString() => 'LogoTransform(${encode()})';
}
