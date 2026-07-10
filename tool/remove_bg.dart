import 'dart:io';
import 'dart:collection';
import 'package:image/image.dart' as img;

void main() {
  final srcDir = Directory('patapons_draw');
  final outDir = Directory('assets/sprites');
  outDir.createSync(recursive: true);

  for (final file in srcDir.listSync()) {
    if (file is! File) continue;
    final name = file.uri.pathSegments.last;
    if (!name.endsWith('.jpeg') && !name.endsWith('.jpg')) continue;

    final baseName = name.replaceAll(RegExp(r'\.(jpeg|jpg)$'), '');
    print('Processing $name...');

    final bytes = file.readAsBytesSync();
    final image = img.decodeJpg(bytes);
    if (image == null) {
      print('  Failed to decode $name');
      continue;
    }

    final w = image.width;
    final h = image.height;

    final rv = List<int>.filled(w * h, 0);
    final gv = List<int>.filled(w * h, 0);
    final bv = List<int>.filled(w * h, 0);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final p = image.getPixel(x, y);
        final idx = y * w + x;
        rv[idx] = p.r.toInt();
        gv[idx] = p.g.toInt();
        bv[idx] = p.b.toInt();
      }
    }

    final isBg = List.filled(w * h, false);
    final visited = List.filled(w * h, false);
    final queue = Queue<int>();

    void seed(int idx) {
      if (!visited[idx]) {
        visited[idx] = true;
        queue.add(idx);
      }
    }

    // Seed from top edge and upper portions of side edges ONLY
    // Do NOT seed from bottom — dark ground connects to character body
    for (int x = 0; x < w; x++) {
      seed(x); // top row
    }
    for (int y = 0; y < h; y++) {
      seed(y * w);         // left column
      seed(y * w + w - 1); // right column
    }

    while (queue.isNotEmpty) {
      final idx = queue.removeFirst();
      final x = idx % w;
      final y = idx ~/ w;

      // Don't mark dark pixels in the bottom half as background
      // This protects the character's dark body from being eaten
      // through the dark ground connection
      final brightness = rv[idx] + gv[idx] + bv[idx];
      if (y > h * 0.55 && brightness < 150) {
        continue;
      }

      isBg[idx] = true;

      final offsets = <int>[
        if (x > 0) -1,
        if (x < w - 1) 1,
        if (y > 0) -w,
        if (y < h - 1) w,
      ];

      for (final off in offsets) {
        final nIdx = idx + off;
        if (visited[nIdx]) continue;

        final dr = (rv[idx] - rv[nIdx]).abs();
        final dg = (gv[idx] - gv[nIdx]).abs();
        final db = (bv[idx] - bv[nIdx]).abs();

        if (dr + dg + db < 45) {
          visited[nIdx] = true;
          queue.add(nIdx);
        }
      }
    }

    // Create output with alpha
    final out = img.Image(width: w, height: h, numChannels: 4);
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final idx = y * w + x;
        final outPixel = out.getPixel(x, y);

        if (isBg[idx]) {
          outPixel.setRgba(0, 0, 0, 0);
        } else {
          int bgN = 0;
          if (x > 0 && isBg[idx - 1]) bgN++;
          if (x < w - 1 && isBg[idx + 1]) bgN++;
          if (y > 0 && isBg[idx - w]) bgN++;
          if (y < h - 1 && isBg[idx + w]) bgN++;

          final alpha = bgN >= 2 ? 180 : (bgN == 1 ? 230 : 255);
          outPixel.setRgba(rv[idx], gv[idx], bv[idx], alpha);
        }
      }
    }

    // Crop to content
    int minX = w, maxX = 0, minY = h, maxY = 0;
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        if (out.getPixel(x, y).a > 10) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }

    minX = (minX - 2).clamp(0, w - 1);
    minY = (minY - 2).clamp(0, h - 1);
    maxX = (maxX + 2).clamp(0, w - 1);
    maxY = (maxY + 2).clamp(0, h - 1);

    final cropped = img.copyCrop(out, x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);

    final outPath = '${outDir.path}/$baseName.png';
    File(outPath).writeAsBytesSync(img.encodePng(cropped));
    print('  Saved $outPath (${cropped.width}x${cropped.height})');
  }
  print('Done!');
}
