import 'dart:io';
import 'package:flutter_driver/flutter_driver.dart';

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('usage: dart run tool/qa_screenshot.dart <ws-uri> [out-dir]');
    exit(64);
  }

  final wsUri = args[0];
  final outDir = args.length > 1 ? args[1] : '/tmp';
  await Directory(outDir).create(recursive: true);

  stdout.writeln('Connecting to Flutter Driver at $wsUri...');
  final driver = await FlutterDriver.connect(
    dartVmServiceUrl: wsUri,
    printCommunication: false,
    logCommunicationToFile: false,
  );

  try {
    // 1. Dark Mode Screenshot
    stdout.writeln('Switching to Dark Mode...');
    await driver.requestData('dark');
    await Future.delayed(const Duration(milliseconds: 1000));
    final darkBytes = await driver.screenshot();
    final darkPath = '$outDir/batterie_dark.png';
    await File(darkPath).writeAsBytes(darkBytes);
    stdout.writeln('Wrote dark mode screenshot to $darkPath (${darkBytes.length} bytes)');

    // 2. Light Mode Screenshot
    stdout.writeln('Switching to Light Mode...');
    await driver.requestData('light');
    await Future.delayed(const Duration(milliseconds: 1000));
    final lightBytes = await driver.screenshot();
    final lightPath = '$outDir/batterie_light.png';
    await File(lightPath).writeAsBytes(lightBytes);
    stdout.writeln('Wrote light mode screenshot to $lightPath (${lightBytes.length} bytes)');
  } finally {
    await driver.close();
  }
}
