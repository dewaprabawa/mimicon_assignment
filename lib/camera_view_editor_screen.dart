import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:mimicon_assignment/face_painter.dart';
import 'package:oktoast/oktoast.dart';

class CameraViewEditor extends StatefulWidget {
  final File capturedImage;
  const CameraViewEditor({Key? key, required this.capturedImage})
      : super(key: key);

  @override
  _CameraViewEditorState createState() => _CameraViewEditorState();
}

class _CameraViewEditorState extends State<CameraViewEditor> {
  GlobalKey globalKey = GlobalKey();
  ui.Image? imageCanvas;
  bool isFaceDetected = false;
  bool hasDownloaded = false;

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

  @override
  void initState() {
    super.initState();
    startPreparingImage();
  }

  Future<void> startPreparingImage() async {
    try {
      File imageFile = File(widget.capturedImage.path);
      Uint8List bytes = await imageFile.readAsBytes();
      ui.Codec codec = await ui.instantiateImageCodec(
        bytes,
      );
      imageCanvas = (await codec.getNextFrame()).image;
      isFaceDetected = false;
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> detectEyes() async {
    try {
      setState(() {
        leftEyePoints.clear();
        rightEyePoints.clear();
      });

      faces = await faceDetector
          .processImage(InputImage.fromFile(widget.capturedImage));

      if (faces.length > 1) {
        setState(() {
          isFaceDetected = false;
        });

        if (!mounted) return;

        showToast(
        "다시찍기", position: ToastPosition.top,
        context: context
        );

        await Future.delayed(Duration(milliseconds: 900));

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
      debugPrint(e.toString());
    }
  }

  Future<void> detectMouth() async {
    try {
      setState(() {
        isFaceDetected = false;
        mouthPoints.clear();
      });

      faces = await faceDetector
          .processImage(InputImage.fromFile(widget.capturedImage));

      if (faces.length > 1) {
        if (!mounted) return;

        showToast(
        "다시찍기", position: ToastPosition.top,
        context: context
        );

        await Future.delayed(Duration(milliseconds: 900));

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
      debugPrint(e.toString());
    }
  }

  Future<void> saveImage() async {
    try {
      RenderRepaintBoundary boundary =
          globalKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage();
      ByteData? byteData =
          await (image.toByteData(format: ui.ImageByteFormat.png));
      if (byteData != null) {
        final result =
            await ImageGallerySaver.saveImage(byteData.buffer.asUint8List());
        debugPrint(result.toString());
      }

      setState(() {
        hasDownloaded = true;
      });

      if (!mounted) return;

      showToast(
        "2개 이상의 얼굴이 감지되었어요!", position: ToastPosition.top);

    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download image.'),
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
            if (!hasDownloaded)
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
            if (!hasDownloaded)
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
      key: globalKey,
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
