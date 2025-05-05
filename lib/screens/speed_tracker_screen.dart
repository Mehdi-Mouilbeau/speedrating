import 'package:athle/export/exportToCsv.dart';
import 'package:athle/screens/speed_chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../camera/camera_service.dart';
import '../pose/pose_service.dart';

class SpeedTrackerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SpeedTrackerScreen({super.key, required this.cameras});

  @override
  _SpeedTrackerScreenState createState() => _SpeedTrackerScreenState();
}

class _SpeedTrackerScreenState extends State<SpeedTrackerScreen> {
  late CameraService _cameraService;
  late PoseService _poseService;
  CameraController? _controller;
  bool _isDetecting = false;
  double _currentSpeed = 0.0;
  final List<Offset> _positionHistory = [];
  DateTime? _lastUpdateTime;

  // Liste pour enregistrer les données de vitesse
  final List<Map<String, dynamic>> speedData = [];

  @override
  void initState() {
    super.initState();
    _cameraService = CameraService();
    _poseService = PoseService();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = await _cameraService.initializeCamera(widget.cameras.first);
    if (_controller != null) {
      _controller!.startImageStream((image) async {
        if (!_isDetecting) {
          _isDetecting = true;
          await _poseService.processPose(image, _updateSpeed);
          _isDetecting = false;
        }
      });
      setState(() {}); // Force UI update after camera initialization
    }
  }

  void _updateSpeed(Offset position) {
    final now = DateTime.now();
    _positionHistory.add(position);
    if (_positionHistory.length > 10) {
      _positionHistory.removeAt(0);
    }

    if (_positionHistory.length >= 2) {
      final previousPosition = _positionHistory.first;
      final previousTime = _lastUpdateTime ?? now;
      final timeDiff = now.difference(previousTime).inMilliseconds / 1000;
      final displacement = (position - previousPosition).distance;

      if (timeDiff > 0) {
        final speed = displacement / timeDiff;
        final speedKmh = speed * 3.6; // Convert to km/h

        setState(() {
          _currentSpeed = speedKmh;
        });

        // Enregistrer la vitesse dans le tableau avec son timestamp
        speedData.add({
          'timestamp': now,
          'speed': _currentSpeed,
        });
      }
    }

    _lastUpdateTime = now;
  }

  @override
  void dispose() {
    _controller?.dispose();
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Running Speed Tracker')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Running Speed Tracker')),
      body: Stack(
        children: [
          AspectRatio(
            aspectRatio: _controller!.value.aspectRatio,
            child: CameraPreview(_controller!),
          ),
          Positioned(
            top: 20,
            left: 20,
            child: IconButton(
              icon: Icon(Icons.show_chart, color: Colors.white),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SpeedChartScreen(speedData: speedData),
                  ),
                );
              },
            ),
          ),
          Positioned(
            top: 80,
            left: 20,
            child: ElevatedButton(
              onPressed: () {
                exportToCSV(speedData);
              },
              child: Text('Exporter en CSV'),
            ),
          ),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              color: Colors.black54,
              child: Text(
                'Speed: ${_currentSpeed.toStringAsFixed(1)} km/h',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
