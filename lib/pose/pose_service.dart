// lib/pose/pose_service.dart

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_ml_kit/google_ml_kit.dart';

class PoseService {
  final PoseDetector _poseDetector = GoogleMlKit.vision.poseDetector();

  Future<void> processPose(CameraImage image, Function(Offset) updateSpeed) async {
    final inputImage = InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: InputImageRotation.rotation0deg,
        format: InputImageFormat.nv21,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );

    final poses = await _poseDetector.processImage(inputImage);
    if (poses.isNotEmpty) {
      final pose = poses.first;
      final leftAnkle = pose.landmarks[PoseLandmarkType.leftAnkle];
      final rightAnkle = pose.landmarks[PoseLandmarkType.rightAnkle];

      if (leftAnkle != null && rightAnkle != null) {
        final position = Offset(
          (leftAnkle.x + rightAnkle.x) / 2,
          (leftAnkle.y + rightAnkle.y) / 2,
        );
        updateSpeed(position);
      }
    }
  }

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final allBytes = WriteBuffer();
    for (var plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }
}
