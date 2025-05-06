import 'package:athle/export/exportToCsv.dart';
import 'package:athle/screens/speed_chart_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../camera/camera_controller.dart';
import '../pose/pose_service.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeedTrackerScreen extends StatefulWidget {
  final List<CameraDescription> cameras;

  const SpeedTrackerScreen({super.key, required this.cameras});

  @override
  _SpeedTrackerScreenState createState() => _SpeedTrackerScreenState();
}

class _SpeedTrackerScreenState extends State<SpeedTrackerScreen> {
  late CameraControllerService _cameraControllerService;
  late PoseService _poseService;
  bool _isDetecting = false;
  double _currentSpeed = 0.0;
  final List<Offset> _positionHistory = [];
  DateTime? _lastUpdateTime;

  // Liste pour enregistrer les données de vitesse
  final List<Map<String, dynamic>> speedData = [];

  // Points de calibration
  Offset? _calibrationStartPx;
  Offset? _calibrationEndPx;
  bool _isCalibrating = true;

  // Positions des chevilles
  Offset? _leftAnklePosition;
  Offset? _rightAnklePosition;

  @override
  void initState() {
    super.initState();
    _cameraControllerService = CameraControllerService();
    _poseService = PoseService();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.microphone,
      Permission.storage,
    ].request();

    final info = statuses[Permission.camera];
    if (info == PermissionStatus.granted) {
      _initializeCamera();
    } else {
      // Handle the case where the user denies the permission
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Camera permission is required to use this app')),
      );
    }
  }

  Future<void> _initializeCamera() async {
    await _cameraControllerService.initializeCamera(widget.cameras.first);
    await _cameraControllerService.startImageStream((image) async {
      if (!_isDetecting && !_isCalibrating) {
        _isDetecting = true;
        await _poseService.processPose(image, _updateSpeed);
        _isDetecting = false;
      }
    });
    setState(() {}); // Force UI update after camera initialization
  }

  void _onTapDown(TapDownDetails details) {
    final position = details.localPosition;
    if (_calibrationStartPx == null) {
      setState(() {
        _calibrationStartPx = position;
      });
      print('Position 0m enregistrée : $position');
    } else if (_calibrationEndPx == null) {
      setState(() {
        _calibrationEndPx = position;
        _isCalibrating = false;
      });
      print('Position 20m enregistrée : $position');
    }
  }

  double _pixelToMeters(Offset current) {
    if (_calibrationStartPx == null || _calibrationEndPx == null) return 0;

    final totalPixelDistance = (_calibrationEndPx! - _calibrationStartPx!).distance;
    final currentDistance = (current - _calibrationStartPx!).distance;

    final meters = 20.0 * (currentDistance / totalPixelDistance);
    return meters;
  }

  void _updateSpeed(Offset leftAnklePosition, Offset rightAnklePosition) {
    setState(() {
      _leftAnklePosition = leftAnklePosition;
      _rightAnklePosition = rightAnklePosition;
    });

    final now = DateTime.now();
    final currentPosition = Offset(
      (leftAnklePosition.dx + rightAnklePosition.dx) / 2,
      (leftAnklePosition.dy + rightAnklePosition.dy) / 2,
    );
    _positionHistory.add(currentPosition);
    if (_positionHistory.length > 10) {
      _positionHistory.removeAt(0);
    }

    if (_positionHistory.length >= 2 && !_isCalibrating) {
      final previous = _positionHistory[_positionHistory.length - 2];
      final previousTime = _lastUpdateTime ?? now;

      final timeDiff = now.difference(previousTime).inMilliseconds / 1000;
      final d1 = _pixelToMeters(previous);
      final d2 = _pixelToMeters(currentPosition);
      final deltaMeters = d2 - d1;

      if (timeDiff > 0) {
        final speedMps = deltaMeters / timeDiff;
        final speedKmh = speedMps * 3.6;

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

  Future<void> _startRecording() async {
    await _cameraControllerService.startRecording();
    setState(() {});
  }

  Future<void> _stopRecording() async {
    await _cameraControllerService.stopRecording();
    setState(() {});
  }

  @override
  void dispose() {
    _cameraControllerService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_cameraControllerService.controller == null || !_cameraControllerService.controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: Text('Running Speed Tracker')),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Running Speed Tracker')),
      body: Stack(
        fit: StackFit.expand, // Make the Stack take the full size of the Scaffold
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTapDown: _onTapDown,
              child: CameraPreview(_cameraControllerService.controller!),
            ),
          ),
          if (_calibrationStartPx != null)
            Positioned(
              left: _calibrationStartPx!.dx,
              top: _calibrationStartPx!.dy,
              child: Icon(Icons.circle, color: Colors.red, size: 20),
            ),
          if (_calibrationEndPx != null)
            Positioned(
              left: _calibrationEndPx!.dx,
              top: _calibrationEndPx!.dy,
              child: Icon(Icons.circle, color: Colors.red, size: 20),
            ),
          if (_leftAnklePosition != null)
            Positioned(
              left: _leftAnklePosition!.dx,
              top: _leftAnklePosition!.dy,
              child: Icon(Icons.circle, color: Colors.blue, size: 20),
            ),
          if (_rightAnklePosition != null)
            Positioned(
              left: _rightAnklePosition!.dx,
              top: _rightAnklePosition!.dy,
              child: Icon(Icons.circle, color: Colors.blue, size: 20),
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
            bottom: 80,
            left: 20,
            child: ElevatedButton(
              onPressed: _cameraControllerService.isRecording ? _stopRecording : _startRecording,
              child: Text(_cameraControllerService.isRecording ? 'Arrêter l\'enregistrement' : 'Démarrer l\'enregistrement'),
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
