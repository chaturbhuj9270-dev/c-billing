import 'package:flutter/material.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/services/language_service.dart';
import '../../core/services/signature_service.dart';

/// Full-screen signature pad for drawing owner signature.
///
/// Returns `true` via `Navigator.pop` if the signature was saved successfully.
class SignaturePadScreen extends StatefulWidget {
  const SignaturePadScreen({super.key});

  @override
  State<SignaturePadScreen> createState() => _SignaturePadScreenState();
}

class _SignaturePadScreenState extends State<SignaturePadScreen> {
  final List<List<Offset>> _strokes = [];
  List<Offset> _currentStroke = [];
  bool _isSaving = false;

  late AppLocalizations _localizations;

  @override
  void initState() {
    super.initState();
    _localizations = AppLocalizations(LanguageService.instance.currentLanguage);
  }

  bool get _hasDrawing =>
      _strokes.isNotEmpty || _currentStroke.isNotEmpty;

  void _clear() {
    setState(() {
      _strokes.clear();
      _currentStroke = [];
    });
  }

  Future<void> _save() async {
    if (!_hasDrawing) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _localizations.pleaseDrawSignature,
            style: const TextStyle(fontFamily: 'Literata'),
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Get the canvas size from the RenderBox
      final renderBox = _canvasKey.currentContext?.findRenderObject() as RenderBox?;
      final canvasSize = renderBox?.size ?? const Size(600, 250);

      final success = await SignatureService().saveSignature(_strokes, canvasSize);

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _localizations.signatureSaveFailed,
                style: const TextStyle(fontFamily: 'Literata'),
              ),
              backgroundColor: Colors.red[700],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  final GlobalKey _canvasKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B4D3E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context, false),
        ),
        title: Text(
          _localizations.drawSignature,
          style: const TextStyle(
            fontFamily: 'Literata',
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        actions: [
          // Clear button
          TextButton.icon(
            onPressed: _hasDrawing ? _clear : null,
            icon: Icon(
              Icons.refresh,
              color: _hasDrawing ? Colors.white : Colors.white38,
              size: 20,
            ),
            label: Text(
              _localizations.clear,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _hasDrawing ? Colors.white : Colors.white38,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 16),

          // Instructions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              _localizations.signatureInstructions,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Literata',
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Signature canvas
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                key: _canvasKey,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[300]!, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14.5),
                  child: GestureDetector(
                    onPanStart: (details) {
                      setState(() {
                        _currentStroke = [details.localPosition];
                      });
                    },
                    onPanUpdate: (details) {
                      setState(() {
                        _currentStroke.add(details.localPosition);
                      });
                    },
                    onPanEnd: (_) {
                      setState(() {
                        if (_currentStroke.isNotEmpty) {
                          _strokes.add(List.from(_currentStroke));
                        }
                        _currentStroke = [];
                      });
                    },
                    child: CustomPaint(
                      painter: _SignaturePainter(
                        strokes: _strokes,
                        currentStroke: _currentStroke,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Baseline indicator text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                const Expanded(child: Divider(color: Colors.grey)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    _localizations.signAbove,
                    style: TextStyle(
                      fontFamily: 'Literata',
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Colors.grey)),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Cancel
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: const BorderSide(color: Color(0xFF1B4D3E)),
                    ),
                    child: Text(
                      _localizations.cancel,
                      style: const TextStyle(
                        fontFamily: 'Literata',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1B4D3E),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Save
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1B4D3E),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            _localizations.saveSignature,
                            style: const TextStyle(
                              fontFamily: 'Literata',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// CustomPainter that draws signature strokes
class _SignaturePainter extends CustomPainter {
  final List<List<Offset>> strokes;
  final List<Offset> currentStroke;

  _SignaturePainter({
    required this.strokes,
    required this.currentStroke,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    // Draw completed strokes
    for (final stroke in strokes) {
      _drawStroke(canvas, stroke, paint);
    }

    // Draw current (in-progress) stroke
    if (currentStroke.isNotEmpty) {
      _drawStroke(canvas, currentStroke, paint);
    }

    // Draw a subtle baseline guide at ~75% height
    final baselineY = size.height * 0.75;
    final dashPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 0.8;

    const dashWidth = 6.0;
    const dashGap = 4.0;
    double x = 20;
    while (x < size.width - 20) {
      canvas.drawLine(
        Offset(x, baselineY),
        Offset(x + dashWidth, baselineY),
        dashPaint,
      );
      x += dashWidth + dashGap;
    }
  }

  void _drawStroke(Canvas canvas, List<Offset> stroke, Paint paint) {
    if (stroke.length < 2) {
      if (stroke.length == 1) {
        canvas.drawCircle(stroke[0], 1.5, paint..style = PaintingStyle.fill);
        paint.style = PaintingStyle.stroke;
      }
      return;
    }

    final path = Path()..moveTo(stroke[0].dx, stroke[0].dy);
    for (var i = 1; i < stroke.length; i++) {
      path.lineTo(stroke[i].dx, stroke[i].dy);
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SignaturePainter oldDelegate) => true;
}
