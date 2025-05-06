import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' show join;

class CameraControllerService {
  CameraController? _controller;
  bool _isRecording = false;
  XFile? _videoFile;

  Future<void> initializeCamera(CameraDescription camera) async {
    _controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
    await _controller!.initialize();
  }

  Future<void> startImageStream(Function(CameraImage) onImageAvailable) async {
    if (_controller != null && _controller!.value.isInitialized) {
      await _controller!.startImageStream(onImageAvailable);
    }
  }

  Future<void> startRecording() async {
    if (_controller != null && _controller!.value.isInitialized && !_isRecording) {
      final directory = await getExternalStorageDirectory();
      if (directory != null) {
        final path = join(directory.path, '${DateTime.now()}.mp4');
        await _controller!.startVideoRecording();
        _isRecording = true;
        _videoFile = XFile(path);
      } else {
        throw Exception('External storage directory not found');
      }
    }
  }

  Future<void> stopRecording() async {
    if (_controller != null && _controller!.value.isRecordingVideo) {
      _videoFile = await _controller!.stopVideoRecording();
      _isRecording = false;
    }
  }

  void dispose() {
    _controller?.dispose();
  }

  CameraController? get controller => _controller;
  bool get isRecording => _isRecording;
  XFile? get videoFile => _videoFile;
}
