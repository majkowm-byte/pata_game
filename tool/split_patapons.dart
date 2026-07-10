import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

void main() {
  final file = File('patapons_draw/8_patapons.png');
  print('Loading image...');
  final image = img.decodePng(file.readAsBytesSync())!;
  final w = image.width;
  final h = image.height;
  print('Image size: ${w}x$h');

  // Manual cut positions based on visual inspection of the image
  // Top row (5 characters): Gaciar, Włosatol, Kundziak, Silny, Drewniak
  // Bottom row (3 characters): Tutek, Grillak, Zieloniak

  final midY = (h * 0.50).round();

  // Top row cuts (between characters)
  // Centers roughly at: 150, 390, 700, 1000, 1350
  final topCuts = [270, 545, 850, 1175];
  // Bottom row cuts
  // Centers roughly at: 530, 870, 1200
  final botCuts = [700, 1040];

  final outDir = Directory('assets/sprites');
  outDir.createSync(recursive: true);

  // Clean old files
  for (final f in outDir.listSync()) {
    if (f is File && f.path.endsWith('.png')) f.deleteSync();
  }

  // Top row names (left to right)
  final topNames = ['Gaciar', 'Wlosatol', 'Kundziak', 'Silny', 'Drewniak'];
  final topBounds = [0, ...topCuts, w];
  for (int i = 0; i < topNames.length; i++) {
    _extractAndSave(image, topBounds[i], 0, topBounds[i + 1] - topBounds[i], midY, outDir, topNames[i]);
  }

  // Bottom row names (left to right)
  final botNames = ['Tutek', 'Grillak', 'Zieloniak'];
  final botBounds = [300, ...botCuts, 1400];
  for (int i = 0; i < botNames.length; i++) {
    _extractAndSave(image, botBounds[i], midY, botBounds[i + 1] - botBounds[i], h - midY, outDir, botNames[i]);
  }

  print('\nDone!');
}

void _extractAndSave(img.Image source, int sx, int sy, int sw, int sh,
    Directory outDir, String name) {
  sx = sx.clamp(0, source.width - 1);
  sy = sy.clamp(0, source.height - 1);
  sw = sw.clamp(1, source.width - sx);
  sh = sh.clamp(1, source.height - sy);

  final cropped = img.copyCrop(source, x: sx, y: sy, width: sw, height: sh);

  // Find content bounds (brightness > 80)
  int minX = sw, maxX = 0, minY = sh, maxY = 0;
  for (int y = 0; y < cropped.height; y++) {
    for (int x = 0; x < cropped.width; x++) {
      final p = cropped.getPixel(x, y);
      if (p.r.toInt() + p.g.toInt() + p.b.toInt() > 100) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  if (maxX <= minX || maxY <= minY) {
    print('  $name: no content, skipping');
    return;
  }

  final pad = 6;
  minX = max(0, minX - pad);
  minY = max(0, minY - pad);
  maxX = min(sw - 1, maxX + pad);
  maxY = min(sh - 1, maxY + pad);

  final trimmed = img.copyCrop(cropped,
      x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

  // Dark background → transparent
  final out = img.Image(width: trimmed.width, height: trimmed.height, numChannels: 4);
  for (int cy = 0; cy < trimmed.height; cy++) {
    for (int cx = 0; cx < trimmed.width; cx++) {
      final p = trimmed.getPixel(cx, cy);
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();
      final brightness = r + g + b;

      final outP = out.getPixel(cx, cy);
      if (brightness < 55) {
        outP.setRgba(0, 0, 0, 0);
      } else if (brightness < 105) {
        final alpha = ((brightness - 55) / 50 * 255).clamp(0, 255).toInt();
        outP.setRgba(r, g, b, alpha);
      } else {
        outP.setRgba(r, g, b, 255);
      }
    }
  }

  final path = '${outDir.path}/$name.png';
  File(path).writeAsBytesSync(img.encodePng(out));
  print('  Saved $path (${out.width}x${out.height})');
}
