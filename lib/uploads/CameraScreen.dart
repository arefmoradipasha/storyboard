import 'dart:async';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CameraScreenA extends StatefulWidget {
  const CameraScreenA({Key? key}) : super(key: key);

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreenA> {
  List<CameraDescription> _cameras = [];
  CameraController? _controller;
  int _selectedCameraIdx = 0;
  FlashMode _flashMode = FlashMode.off;
  bool _isRecording = false;
  Timer? _timer;
  double _recordDuration = 0.0; // به ثانیه
  static const int maxRecordDuration = 30; // بیشترین زمان ضبط (۳۰ ثانیه)

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _selectedCameraIdx = 0;
        _controller = CameraController(
          _cameras[_selectedCameraIdx],
          ResolutionPreset.high,
          enableAudio: true,
        );
        await _controller!.initialize();
        if (!mounted) return;
        setState(() {});
      }
    } on CameraException catch (e) {
      print("Error initializing camera: $e");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _onCapturePressed() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;
    try {
      final XFile file = await _controller!.takePicture();
      print('Picture captured: ${file.path}');
      Navigator.pop(context, file.path);
    } on CameraException catch (e) {
      print("Error capturing picture: $e");
    }
  }

  Future<void> _startVideoRecording() async {
    if (_controller == null || !_controller!.value.isInitialized || _isRecording) return;
    try {
      await _controller!.startVideoRecording();
      _isRecording = true;
      _recordDuration = 0.0;
      HapticFeedback.vibrate();
      _flashBlinkEffect();
      _timer = Timer.periodic(Duration(milliseconds: 100), (timer) {
        setState(() {
          _recordDuration += 0.1;
        });
        if (_recordDuration >= maxRecordDuration) {
          _stopVideoRecording();
        }
      });
    } on CameraException catch (e) {
      print("Error starting video recording: $e");
    }
  }

  void _flashBlinkEffect() {
    int count = 0;
    Timer.periodic(Duration(milliseconds: 200), (blinkTimer) async {
      if (!_isRecording) {
        blinkTimer.cancel();
        return;
      }
      try {
        if (count % 2 == 0) {
          await _controller?.setFlashMode(FlashMode.torch);
        } else {
          await _controller?.setFlashMode(FlashMode.off);
        }
      } catch (e) {
        print("Error toggling flash for blink effect: $e");
      }
      count++;
      if (count >= 6) {
        blinkTimer.cancel();
        try {
          await _controller?.setFlashMode(_flashMode);
        } catch (e) {
          print("Error restoring flash mode: $e");
        }
      }
    });
  }

  Future<void> _stopVideoRecording() async {
    if (!_isRecording) return;
    try {
      final XFile file = await _controller!.stopVideoRecording();
      _timer?.cancel();
      _isRecording = false;
      print('Video recorded: ${file.path}');
      Navigator.pop(context, file.path);
    } on CameraException catch (e) {
      print("Error stopping video recording: $e");
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _startVideoRecording();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    if (_isRecording) {
      _stopVideoRecording();
    }
  }

  Future<void> _toggleCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIdx = (_selectedCameraIdx + 1) % _cameras.length;
    await _controller?.dispose();
    _controller = CameraController(
      _cameras[_selectedCameraIdx],
      ResolutionPreset.high,
      enableAudio: true,
    );
    try {
      await _controller!.initialize();
      setState(() {});
    } on CameraException catch (e) {
      print("Error switching camera: $e");
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null || !_controller!.value.isInitialized) return;
    try {
      if (_flashMode == FlashMode.off) {
        _flashMode = FlashMode.always;
      } else {
        _flashMode = FlashMode.off;
      }
      await _controller!.setFlashMode(_flashMode);
      setState(() {});
    } on CameraException catch (e) {
      print("Error toggling flash: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            top: 40,
            left: 20,
            child: IconButton(
              icon: Icon(
                _flashMode == FlashMode.off ? Icons.flash_off : Icons.flash_on,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _toggleFlash,
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              icon: Icon(
                Icons.flip_camera_ios,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _toggleCamera,
            ),
          ),
          Positioned(
            top: 40,
            left: 70,
            child: IconButton(
              icon: Icon(
                Icons.close,
                color: Colors.white,
                size: 28,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTap: _onCapturePressed,
                onLongPressStart: _onLongPressStart,
                onLongPressEnd: _onLongPressEnd,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                    if (_isRecording)
                      SizedBox(
                        width: 90,
                        height: 90,
                        child: CircularProgressIndicator(
                          value: _recordDuration / maxRecordDuration,
                          strokeWidth: 4,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                          backgroundColor: Colors.white.withOpacity(0.3),
                        ),
                      ),
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}