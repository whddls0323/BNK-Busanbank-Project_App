import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

class VisionTestScreen extends StatefulWidget {
  const VisionTestScreen({super.key});

  @override
  State<VisionTestScreen> createState() => _VisionTestScreenState();
}

class _VisionTestScreenState extends State<VisionTestScreen> {
  XFile? image;
  String result = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('OCR 테스트 (Google Vision)'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (image != null)
              Image.file(File(image!.path), height: 250),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final picked =
                await picker.pickImage(source: ImageSource.gallery);

                if (picked != null) {
                  setState(() {
                    image = picked;
                    result = "";
                  });
                }
              },
              child: const Text('이미지 선택'),
            ),

            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: image == null
                  ? null
                  : () async {
                await textDetection(imagePath: image!.path);
              },
              child: const Text('텍스트 추출'),
            ),

            const SizedBox(height: 24),

            if (result.isNotEmpty)
              Text(
                result,
                style: const TextStyle(fontSize: 16),
              ),
          ],
        ),
      ),
    );
  }

  /// 이미지 base64 인코딩
  Future<String> encodeImageToBase64(String imagePath) async {
    final file = File(imagePath);
    final Uint8List bytes = await file.readAsBytes();
    return base64Encode(bytes);
  }

  /// 텍스트 추출
  Future<void> textDetection({required String imagePath}) async {
    try {
      log('textDetection 진입');

      final base64Image = await encodeImageToBase64(imagePath);
      log('base64 길이: ${base64Image.length}');

      final response = await http.post(
        Uri.parse(
          'https://vision.googleapis.com/v1/images:annotate'
              '?key=AIzaSyBldHAhTkWn9e1dEFQaxprGsdJXRHULdh4',
        ),
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
        },
        body: jsonEncode({
          "requests": [
            {
              "image": {"content": base64Image},
              "features": [{"type": "LABEL_DETECTION"}]
            }
          ]
        }),
      );

      log('statusCode: ${response.statusCode}');
      log('responseBody: ${response.body}');

      setState(() {
        result = response.body;
      });
    } catch (e, s) {
      log('OCR EXCEPTION', error: e, stackTrace: s);
      setState(() {
        result = '에러: $e';
      });
    }
  }
}