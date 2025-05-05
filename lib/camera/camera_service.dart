// lib/camera/camera_service.dart
import 'package:camera/camera.dart';

class CameraService {
  CameraController? _controller;
  bool _isInitialized = false;

  Future<CameraController?> initializeCamera(CameraDescription camera) async {
    _controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
    _isInitialized = true;
    return _controller;
  }

  CameraController? get controller => _controller;
  bool get isInitialized => _isInitialized;
}
