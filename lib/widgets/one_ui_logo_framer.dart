import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../features/subscriptions/domain/entities/logo_transform.dart';
import '../theme/one_ui_theme.dart';
import '../utils/one_ui_brand_catalog.dart';
import 'one_ui_brand_icon.dart';

/// Image editor for a custom logo: shows the real icon large, and lets you pinch
/// to zoom and drag to reposition the image inside it (or use the zoom slider).
/// What you see is exactly how the icon renders everywhere else, because it is
/// the same [OneUIBrandIcon] with the same [LogoTransform].
class OneUILogoFramer extends StatefulWidget {
  final String url;
  final String name;
  final Color background;
  final LogoTransform value;
  final ValueChanged<LogoTransform> onChanged;
  final double size;

  const OneUILogoFramer({
    super.key,
    required this.url,
    required this.name,
    required this.background,
    required this.value,
    required this.onChanged,
    this.size = 200,
  });

  @override
  State<OneUILogoFramer> createState() => _OneUILogoFramerState();
}

class _OneUILogoFramerState extends State<OneUILogoFramer> {
  LogoTransform _start = LogoTransform.identity;
  Offset _startFocal = Offset.zero;

  void _onScaleStart(ScaleStartDetails d) {
    _start = widget.value;
    _startFocal = d.localFocalPoint;
  }

  void _onScaleUpdate(ScaleUpdateDetails d) {
    final moved = (d.localFocalPoint - _startFocal) / widget.size;
    widget.onChanged(LogoTransform(
      scale: (_start.scale * d.scale).clamp(LogoTransform.minScale, LogoTransform.maxScale),
      dx: (_start.dx + moved.dx).clamp(-1.0, 1.0),
      dy: (_start.dy + moved.dy).clamp(-1.0, 1.0),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.value;
    return Column(
      children: [
        Semantics(
          label: 'Logo framing. Pinch to zoom, drag to move.',
          child: GestureDetector(
            onScaleStart: _onScaleStart,
            onScaleUpdate: _onScaleUpdate,
            onDoubleTap: () {
              HapticFeedback.selectionClick();
              widget.onChanged(LogoTransform.identity);
            },
            child: SizedBox.square(
              dimension: widget.size,
              child: Stack(
                children: [
                  OneUIBrandIcon(
                    name: widget.name,
                    brandColor: widget.background,
                    logoUrl: widget.url,
                    logoTransform: t,
                    brandPresetId: '__none__',
                    size: widget.size,
                  ),
                  // Thirds guide to line the logo up by eye.
                  IgnorePointer(
                    child: CustomPaint(
                      size: Size.square(widget.size),
                      painter: _ThirdsPainter(
                        radius: widget.size * 0.32,
                        // Visible on any background: dark lines on light colours.
                        color: OneUIBrandCatalog.foregroundOn(widget.background).withValues(alpha: 0.22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            const Icon(Icons.zoom_out_rounded, size: 20, color: OneUITheme.textSecondary),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: OneUITheme.accentBlue,
                  inactiveTrackColor: OneUITheme.surfacePill,
                  thumbColor: Colors.white,
                  overlayColor: OneUITheme.accentBlue.withValues(alpha: 0.12),
                  trackHeight: 4,
                ),
                child: Slider(
                  value: t.scale.clamp(LogoTransform.minScale, LogoTransform.maxScale),
                  min: LogoTransform.minScale,
                  max: LogoTransform.maxScale,
                  label: '${(t.scale * 100).round()}%',
                  semanticFormatterCallback: (v) => 'Zoom ${(v * 100).round()} percent',
                  onChanged: (v) => widget.onChanged(t.copyWith(scale: v)),
                ),
              ),
            ),
            const Icon(Icons.zoom_in_rounded, size: 20, color: OneUITheme.textSecondary),
          ],
        ),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Pinch to zoom, drag to move. Double-tap to reset.',
                style: TextStyle(fontSize: 12.5, height: 1.35, color: OneUITheme.textSecondary),
              ),
            ),
            TextButton(
              onPressed: t.isIdentity
                  ? null
                  : () {
                      HapticFeedback.selectionClick();
                      widget.onChanged(LogoTransform.identity);
                    },
              child: const Text('Reset'),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThirdsPainter extends CustomPainter {
  final double radius;
  final Color color;

  const _ThirdsPainter({required this.radius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.save();
    canvas.clipRRect(RRect.fromRectAndRadius(rect, Radius.circular(radius)));
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    for (var i = 1; i < 3; i++) {
      final x = size.width * i / 3;
      final y = size.height * i / 3;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(_ThirdsPainter old) => old.radius != radius || old.color != color;
}
