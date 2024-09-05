import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:path_provider/path_provider.dart';


/// To get the Data from the URL
Future<String> getData() async {
  String url =
      "https://codeskulptor-demos.commondatastorage.googleapis.com/descent/background%20music.mp3";
  String path = "";
  try {
    var response = await http.get(Uri.parse(url), headers: {
      "X-Microsoft-OutputFormat": "audio-48khz-96kbitrate-mono-mp3",
      "Content-Type": "application/ssml+xml"
    });

    if (response.statusCode == 200) {
      var bytes = response.bodyBytes;

      final tempDir = await getTemporaryDirectory();
      File file = await File('${tempDir.path}/audio.mp3').create();
      await file.writeAsBytes(bytes);

      debugPrint("File saved at ${file.path}");
      path = file.path;
    } else {
      debugPrint(
          "Failed to download file. Status code: ${response.statusCode}");
    }
  } catch (e) {
    debugPrint("Error occurred: $e");
  }
  return path;
}
