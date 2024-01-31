import 'dart:io';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class CameraViewEditor extends StatefulWidget {
  final File capturedImage;
  const CameraViewEditor({Key? key, required this.capturedImage})
      : super(key: key);

  @override
  _CameraViewEditorState createState() => _CameraViewEditorState();
}

class _CameraViewEditorState extends State<CameraViewEditor> {
  @override
  void initState() {
    super.initState();
    prepareImage();
  }

  //Create an instance of ScreenshotController
  GlobalKey _globalKey = GlobalKey();

  ui.Image? imageCanvas;
  bool isFaceDetected = false;

  List<Offset> leftEyePoints = [];
  List<Offset> rightEyePoints = [];
  List<Offset> mouthPoints = [];
  List<Face> faces = [];

  final FaceDetector faceDetector = FaceDetector(
    options: FaceDetectorOptions(
      enableContours: true,
      enableLandmarks: true,
    ),
  );

  Future<void> prepareImage() async {
    try {
      print("widget.capturedImage ${widget.capturedImage.path}");
      // Read the image file using File class
      File imageFile = File(widget.capturedImage.path);
      Uint8List bytes = await imageFile.readAsBytes();
      ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
      );
      imageCanvas = (await codec.getNextFrame()).image!;
      isFaceDetected = false;
      print("imageCanvas ${imageCanvas}");
      print("widget.capturedImage ${widget.capturedImage}");
    } catch (e) {
      print(e);
    }
  }

  Future<void> detectEyes() async {
    try {
      setState(() {
        leftEyePoints.clear();
        rightEyePoints.clear();
      });
      faces = await faceDetector
          .processImage(InputImage.fromFile(widget.capturedImage!));

      if (faces.length > 1) {
        setState(() {
          isFaceDetected = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('다시찍기'),
        ));
        Navigator.popUntil(context, (route) => route.isFirst);
        return;
      }

      for (Face face in faces) {
        for (MapEntry<FaceLandmarkType, FaceLandmark?> entry
            in face.landmarks.entries) {
          if (entry.value != null) {
            if (entry.key == FaceLandmarkType.leftEye) {
              leftEyePoints.add(Offset(
                entry.value!.position.x.toDouble(),
                entry.value!.position.y.toDouble(),
              ));
            } else if (entry.key == FaceLandmarkType.rightEye) {
              rightEyePoints.add(Offset(
                entry.value!.position.x.toDouble(),
                entry.value!.position.y.toDouble(),
              ));
            }
          }
        }
      }

      setState(() {
        isFaceDetected = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> detectMouth() async {
    try {
      setState(() {
        isFaceDetected = false;
        mouthPoints.clear();
      });
      faces = await faceDetector
          .processImage(InputImage.fromFile(widget.capturedImage!));

      if (faces.length > 1) {
        setState(() {
          ScaffoldMessenger.of(context).showSnackBar(
          const  SnackBar(
              content: Text('다시찍기'),
            ),
          );
        });
        Navigator.popUntil(context, (route) => route.isFirst);
        return;
      }

      for (Face face in faces) {
        for (MapEntry<FaceLandmarkType, FaceLandmark?> entry
            in face.landmarks.entries) {
          if (entry.value != null) {
            if (entry.key == FaceLandmarkType.bottomMouth) {
              double centerX = (entry.value!.position.x +
                          face.landmarks[FaceLandmarkType.leftMouth]!.position
                              .x) /
                      2.0 +
                  15;
              double centerY = (entry.value!.position.y +
                      face.landmarks[FaceLandmarkType.rightMouth]!.position.y) /
                  2.0;

              mouthPoints.add(Offset(centerX, centerY));
            }
          }
        }
      }
      setState(() {
        isFaceDetected = true;
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> saveImage() async {
    try {
      RenderRepaintBoundary boundary = _globalKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await (image.toByteData(format: ui.ImageByteFormat.png));
      if (byteData != null) {
        final result =
            await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
        print(result);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Screenshot captured successfully!'),
        ),
      );
    } catch (e) {
      print(e);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to capture screenshot.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final height = MediaQuery.of(context).size.height;
    final width = MediaQuery.of(context).size.width;
    bool isNotlayeredGreen =
        rightEyePoints.isEmpty && leftEyePoints.isEmpty || mouthPoints.isEmpty;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.close_rounded,
            color: Colors.white,
          ),
        ),
        actions: const [
          Icon(
            Icons.more_vert_rounded,
            color: Colors.white,
          )
        ],
      ),
      body: Container(
        color: Colors.black,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isFaceDetected)
              SizedBox(
                child: _buildImageBeforeDetected(height),
              ),
            if (imageCanvas != null && isFaceDetected)
              SizedBox(
                child: _buildImageAfterDetected(height),
              ),
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 10),
              child: InkWell(
                onTap: () {
                  Navigator.pop(context);
                },
                child: SvgPicture.asset("assets/back_button.svg"),
              ),
            ),
            const SizedBox(
              height: 20,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Row(
                children: [
                  InkWell(
                    onTap: () async {
                      await detectEyes();
                    },
                    child: SvgPicture.asset("assets/eye_button.svg"),
                  ),
                  const SizedBox(width: 20),
                  InkWell(
                    onTap: () async {
                      await detectMouth();
                    },
                    child: SvgPicture.asset("assets/mouth_button.svg"),
                  ),
                ],
              ),
            ),
            const Spacer(),
            Center(
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                    fixedSize: Size(width - 10, 55),
                    backgroundColor: isNotlayeredGreen
                        ? Colors.grey
                        : const Color(0xff7B8FF7)),
                child: SvgPicture.asset("assets/저장하기download_text.svg"),
                onPressed: () async {
                  if (isNotlayeredGreen) return;
                  await saveImage();
                },
              ),
            ),
            const SizedBox(
              height: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageAfterDetected(double height) {
    return RepaintBoundary(
      key: _globalKey,
      child: SizedBox(
        width: double.infinity,
        height: height * 0.6,
        child: FittedBox(
          child: SizedBox(
            width: imageCanvas!.width.toDouble(),
            height: imageCanvas!.height.toDouble(),
            child: CustomPaint(
              painter: FacePainter(
                image: imageCanvas!,
                mouthPoints: mouthPoints,
                leftEyePoints: leftEyePoints,
                rightEyePoints: rightEyePoints,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageBeforeDetected(double height) {
    return Image.file(
      width: double.infinity,
      height: height * 0.6,
      widget.capturedImage,
      fit: BoxFit.contain,
    );
  }
}

class FacePainter extends CustomPainter {
  ui.Image image;
  List<Offset> leftEyePoints = [];
  List<Offset> rightEyePoints = [];
  List<Offset> mouthPoints = [];

  FacePainter({
    required this.image,
    required this.leftEyePoints,
    required this.rightEyePoints,
    required this.mouthPoints,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (image != null) {
      canvas.drawImage(image, Offset.zero, Paint());
    }

    for (Offset point in leftEyePoints) {
      _drawOval(canvas, point, point.dx * 0.3, point.dy * 0.2,
          Paint()..color = Color(0xff01FF0B).withOpacity(0.5));
    }

    for (Offset point in rightEyePoints) {
      _drawOval(canvas, point, point.dx * 0.3, point.dy * 0.2,
          Paint()..color = Color(0xff01FF0B).withOpacity(0.5));
    }

    for (Offset point in mouthPoints) {
      _drawOval(canvas, point, point.dx * 0.40, point.dy * 0.12,
          Paint()..color = Color(0xff01FF0B).withOpacity(0.5));
    }
  }

  void _drawOval(
      Canvas canvas, Offset center, double width, double height, Paint paint) {
    Rect oval = Rect.fromCenter(center: center, width: width, height: height);
    canvas.drawOval(oval, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}
