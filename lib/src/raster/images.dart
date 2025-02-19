import 'dart:typed_data';
import 'dart:ui';

Future<Image> imageFrom({required Uint8List bytes}) async {
  final codec = await instantiateImageCodec(bytes);
  try {
    final frame = await codec.getNextFrame();
    return frame.image;
  } finally {
    codec.dispose();
  }
}
