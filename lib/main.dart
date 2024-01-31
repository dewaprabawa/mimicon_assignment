import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:mimicon_assignment/camera_view_capture_screen.dart';

List<CameraDescription> _cameras = <CameraDescription>[];

void main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    _cameras = await availableCameras();
  } on CameraException catch (e) {
    debugPrint(e.description);
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: CameraViewCaptureScreen(cameras: _cameras),
    );
  }
}


