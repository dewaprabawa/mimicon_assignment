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
  State<CameraViewCaptureScreen> createState() => _CameraViewCaptureScreenState();
}

class _CameraViewCaptureScreenState extends State<CameraViewCaptureScreen> {
  late CameraController controller;
  bool isFrontCamera = false;

  @override
  void initState() {
    super.initState();
    final currentCamera = widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back);
    controller = CameraController(currentCamera, ResolutionPreset.max);
    controller.initialize().then((_) {
      if (!mounted) {
        return;
      }
      setState(() {});
    }).catchError((Object e) {
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
    });
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _captureImage() async {
    try {
      final XFile file = await controller.takePicture();
      // Handle the captured image file
      print('Image captured: ${file.path}');
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  CameraViewEditor(capturedImage: File(file.path))));
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  void _changeCamera() async {
    if (controller.value.isInitialized) {
      try {
        // Toggle between front and back cameras
        CameraLensDirection newDirection = isFrontCamera
            ? CameraLensDirection.back
            : CameraLensDirection.front;
        var newCamera = widget.cameras
            .firstWhere((camera) => camera.lensDirection == newDirection);

        // Dispose of the current controller before initializing a new one
        await controller.dispose();

        // Initialize the new controller with the new camera
        controller = CameraController(newCamera, ResolutionPreset.max);
        await controller.initialize();

        setState(() {
          isFrontCamera = !isFrontCamera; // Update the current camera direction
        });
      } catch (e) {
        print('Error changing camera: $e');
      }
    }
  }

  Future<void> _imageGallery() async {
    try {
      XFile? xfile = await ImagePicker().pickMedia();
      if (xfile == null) return;

      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) =>
                  CameraViewEditor(capturedImage: File(xfile.path))));
    } catch (e) {
      debugPrint(e.toString() + "::image load from gallery");
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    if (!controller.value.isInitialized) {
      return Container();
    }
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
