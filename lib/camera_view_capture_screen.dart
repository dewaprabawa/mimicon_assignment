import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mimicon_assignment/camera_view_editor_screen.dart';

class CameraViewCaptureScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  const CameraViewCaptureScreen({super.key, required this.cameras});

  @override
  State<CameraViewCaptureScreen> createState() =>
      _CameraViewCaptureScreenState();
}

class _CameraViewCaptureScreenState extends State<CameraViewCaptureScreen> {
  late CameraController controller;
  bool isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void initializeCamera() async {
    try {
      final currentCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
      );
      controller = CameraController(currentCamera, ResolutionPreset.max);
      await controller.initialize();

      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      handleCameraError(e);
    }
  }

  void handleCameraError(Object e) {
    if (e is CameraException) {
      switch (e.code) {
        case 'CameraAccessDenied':
          // Handle access errors here.
          break;
        default:
          // Handle other errors here.
          break;
      }
    }
  }

  void navigateToEditor(File capturedImage) {
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (context) => CameraViewEditor(capturedImage: capturedImage),
      ),
    );
  }

  void _captureImage() async {
    try {
      final XFile file = await controller.takePicture();
      debugPrint('Image captured: ${file.path}');
      navigateToEditor(File(file.path));
    } catch (e) {
      debugPrint('Error capturing image: $e');
    }
  }

  Future<void> _imageGallery() async {
    try {
      XFile? file = await ImagePicker().pickMedia();
      if (file == null) return;
      navigateToEditor(File(file.path));
    } catch (e) {
      debugPrint('Error pick image from gallery: $e');
    }
  }

  void _changeCamera() async {
    if (controller.value.isInitialized) {
      try {
        CameraLensDirection newDirection = isFrontCamera
            ? CameraLensDirection.back
            : CameraLensDirection.front;
        var newCamera = widget.cameras
            .firstWhere((camera) => camera.lensDirection == newDirection);

        await controller.dispose();

        controller = CameraController(newCamera, ResolutionPreset.max);
        await controller.initialize();

        setState(() {
          isFrontCamera = !isFrontCamera; 
        });
      } catch (e) {
        debugPrint('Error changing camera: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!controller.value.isInitialized) {
      return Container();
    }

    final height = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: const Icon(
          Icons.close_rounded,
          color: Colors.white,
        ),
        actions: const [
          Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
          )
        ],
      ),
      body: Column(
        mainAxisSize: MainAxisSize.max,
        children: [
          SizedBox(
              width: double.infinity,
              height: height * 0.6,
              child: CameraPreview(controller)),
          Expanded(
            child: Container(
              color: Colors.black,
              width: double.infinity,
              child: Column(
                mainAxisSize: MainAxisSize.max,
                children: [
                  const SizedBox(
                    height: 40,
                  ),
                  InkWell(
                    onTap: _captureImage,
                    child: SvgPicture.asset(
                        height: 74, width: 74, "assets/camera_button.svg"),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.only(left: 20, right: 20, top: 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        InkWell(
                          onTap: _imageGallery,
                          child: SvgPicture.asset(
                              height: 24, width: 24, "assets/gallery.svg"),
                        ),
                        InkWell(
                          onTap: _changeCamera,
                          child: SvgPicture.asset(
                              height: 24,
                              width: 24,
                              "assets/change_camera.svg"),
                        ),
                      ],
                    ),
                  )
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
