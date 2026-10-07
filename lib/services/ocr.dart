import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 기기 안에서 글자 인식 (ML Kit 온디바이스 모델, 한국어·라틴 문자).
/// 지원하지 않는 플랫폼(웹 등)에서는 null을 돌려주고, 화면은 직접 입력으로 대체한다.
class Ocr {
  static bool get supported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  static Future<String?> read(String imagePath) async {
    if (!supported) return null;
    final recognizer = TextRecognizer(script: TextRecognitionScript.korean);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));
      return result.text;
    } catch (_) {
      return null;
    } finally {
      await recognizer.close();
    }
  }
}
