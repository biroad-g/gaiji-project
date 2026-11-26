import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// 切り取り・調整の結果
class CropResult {
  CropResult({
    required this.bytes,
    required this.width,
    required this.height,
  });

  final Uint8List bytes;
  final int width;
  final int height;
}

/// 画像の切り取り・余白調整・背景透過を行う純Dartサービス。
/// Android / Web の双方で同一の挙動になる。
class CropService {
  /// [source] から [rect]（画像ピクセル座標）を切り出す。
  ///
  /// - [autoTrim] : 切り出し範囲内の「墨」に合わせて余白を詰める
  /// - [transparentPaper] : 紙の地色を透過させ、字形だけの PNG にする
  /// - [threshold] : 墨と紙を分ける明度しきい値（0-255）
  static CropResult crop({
    required Uint8List source,
    required int left,
    required int top,
    required int right,
    required int bottom,
    bool autoTrim = true,
    bool transparentPaper = false,
    int threshold = 150,
    int padding = 6,
  }) {
    final decoded = img.decodeImage(source);
    if (decoded == null) {
      return CropResult(bytes: source, width: 0, height: 0);
    }

    final x0 = left.clamp(0, decoded.width - 1);
    final y0 = top.clamp(0, decoded.height - 1);
    final x1 = right.clamp(x0 + 1, decoded.width);
    final y1 = bottom.clamp(y0 + 1, decoded.height);

    img.Image out = img.copyCrop(
      decoded,
      x: x0,
      y: y0,
      width: x1 - x0,
      height: y1 - y0,
    );

    if (autoTrim) {
      out = _trimToInk(out, threshold);
    }

    if (transparentPaper) {
      out = _paperToAlpha(out, threshold);
    } else {
      out = _normalizePaper(out, threshold);
    }

    if (padding > 0) {
      out = _pad(out, padding);
    }

    final png = img.encodePng(out, level: 6);
    return CropResult(
      bytes: Uint8List.fromList(png),
      width: out.width,
      height: out.height,
    );
  }

  /// 墨の外接矩形まで詰める（紙面の余白を落とす）
  static img.Image _trimToInk(img.Image src, int threshold) {
    int minX = src.width, minY = src.height, maxX = -1, maxY = -1;
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final lum = _luminance(p);
        if (lum < threshold) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    if (maxX < 0 || maxY < 0) return src; // 墨が見つからない場合はそのまま

    // わずかに外側へ（字形の端が切れないように）
    final pad = math.max(2, (math.max(src.width, src.height) * 0.02).round());
    final cx0 = (minX - pad).clamp(0, src.width - 1);
    final cy0 = (minY - pad).clamp(0, src.height - 1);
    final cx1 = (maxX + pad).clamp(cx0 + 1, src.width);
    final cy1 = (maxY + pad).clamp(cy0 + 1, src.height);

    // 正方形に近づける（外字は一字を方形で扱うため）
    final w = cx1 - cx0;
    final h = cy1 - cy0;
    final int side = math.max(w, h);
    final int centerX = (cx0 + cx1) ~/ 2;
    final int centerY = (cy0 + cy1) ~/ 2;
    final int sx = (centerX - side ~/ 2)
        .clamp(0, math.max(0, src.width - side))
        .toInt();
    final int sy = (centerY - side ~/ 2)
        .clamp(0, math.max(0, src.height - side))
        .toInt();
    final int sw = math.min(side, src.width - sx);
    final int sh = math.min(side, src.height - sy);

    return img.copyCrop(src, x: sx, y: sy, width: sw, height: sh);
  }

  /// 紙の地色を透明にし、墨だけを残す（濃淡は保持）
  static img.Image _paperToAlpha(img.Image src, int threshold) {
    final out = img.Image(width: src.width, height: src.height, numChannels: 4);
    final hi = math.max(threshold + 40, 200).toDouble();
    for (int y = 0; y < src.height; y++) {
      for (int x = 0; x < src.width; x++) {
        final p = src.getPixel(x, y);
        final lum = _luminance(p);
        double alpha;
        if (lum <= threshold) {
          alpha = 1.0;
        } else if (lum >= hi) {
          alpha = 0.0;
        } else {
          alpha = 1.0 - ((lum - threshold) / (hi - threshold));
        }
        // 墨色は黒寄りに正規化（紙の色かぶりを除去）
        const value = 0;
        out.setPixelRgba(x, y, value, value, value, (alpha * 255).round());
      }
    }
    return out;
  }

  /// 背景透過しない場合：紙の明るさを揃えて読みやすくする
  static img.Image _normalizePaper(img.Image src, int threshold) {
    final out = src.convert(numChannels: 3);
    for (int y = 0; y < out.height; y++) {
      for (int x = 0; x < out.width; x++) {
        final p = out.getPixel(x, y);
        final lum = _luminance(p);
        if (lum > threshold) {
          // 紙はほぼ白に
          out.setPixelRgb(x, y, 253, 251, 244);
        } else {
          // 墨はやや引き締める
          final f = (lum / threshold).clamp(0.0, 1.0);
          final v = (40 + 60 * f).round();
          out.setPixelRgb(x, y, v, v, (v * 0.95).round());
        }
      }
    }
    return out;
  }

  static img.Image _pad(img.Image src, int padding) {
    final out = img.Image(
      width: src.width + padding * 2,
      height: src.height + padding * 2,
      numChannels: src.numChannels,
    );
    final bg = src.numChannels == 4 ? 0 : 253;
    img.fill(out, color: img.ColorRgba8(bg, bg, bg, 0));
    img.compositeImage(out, src, dstX: padding, dstY: padding);
    return out;
  }

  static double _luminance(img.Pixel p) =>
      0.299 * p.r + 0.587 * p.g + 0.114 * p.b;

  /// 解像度が大きすぎる写真を縮小（メモリ対策）
  static Uint8List downscaleIfNeeded(Uint8List source, {int maxSide = 2200}) {
    final decoded = img.decodeImage(source);
    if (decoded == null) return source;
    final longest = math.max(decoded.width, decoded.height);
    if (longest <= maxSide) return source;
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxSide : null,
      height: decoded.height > decoded.width ? maxSide : null,
      interpolation: img.Interpolation.average,
    );
    return Uint8List.fromList(img.encodeJpg(resized, quality: 90));
  }

  /// 詳細表示用のサムネイル生成（base64 を軽くする）
  static Uint8List makeThumbnail(Uint8List source, {int maxSide = 900}) {
    final decoded = img.decodeImage(source);
    if (decoded == null) return source;
    final longest = math.max(decoded.width, decoded.height);
    if (longest <= maxSide) return Uint8List.fromList(img.encodePng(decoded));
    final resized = img.copyResize(
      decoded,
      width: decoded.width >= decoded.height ? maxSide : null,
      height: decoded.height > decoded.width ? maxSide : null,
      interpolation: img.Interpolation.average,
    );
    return Uint8List.fromList(img.encodePng(resized));
  }
}
