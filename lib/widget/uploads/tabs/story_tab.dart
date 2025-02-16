import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';

class StoryTab extends StatefulWidget {
  final Function(AssetEntity?)? onMediaSelected;
  const StoryTab({Key? key, this.onMediaSelected}) : super(key: key);

  @override
  StoryTabState createState() => StoryTabState();
}

class StoryTabState extends State<StoryTab> with SingleTickerProviderStateMixin {
  CameraController? _cameraController;
  bool _isCameraInitialized = false;
  bool _isCameraPermissionGranted = false;
  List<CameraDescription> _cameras = [];
  int _selectedCameraIndex = 0;
  bool _isFlashOn = false;

  List<AssetEntity> _galleryImages = [];
  AssetEntity? selectedImage;
  bool _isGalleryLoading = true;
  bool _isGallerySheetOpen = false;

  VideoPlayerController? _videoPlayerController;
  bool _isRecording = false;
  late DateTime _recordStartTime;
  double _recordDuration = 0;
  final double maxRecordDuration = 15; // 15 seconds max duration
  late AnimationController _animationController;
  late Animation<double> _progressAnimation;

  double _currentZoom = 0.8;
  final double _minZoom = 1.0;
  final double _maxZoom = 8.0;
  double _baseScale = 1.0;

  List<AssetEntity> get galleryImages => _galleryImages;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _fetchGalleryImages();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 15),
    );
    _progressAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _videoPlayerController?.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeCamera() async {
    if (!await Permission.camera.isGranted) {
      final status = await Permission.camera.request();
      if (!status.isGranted) {
        setState(() {
          _isCameraPermissionGranted = false;
        });
        return;
      }
    }
    _isCameraPermissionGranted = true;
    _cameras = await availableCameras();
    if (_cameras.isNotEmpty) {
      _selectedCameraIndex = 0;
      _cameraController = CameraController(
        _cameras[_selectedCameraIndex],
        ResolutionPreset.medium,
      );
      await _cameraController!.initialize();
      _currentZoom = 0.8;
      await _cameraController!.setZoomLevel(_currentZoom);
      await _cameraController!.setFlashMode(FlashMode.off);
      setState(() {
        _isCameraInitialized = true;
      });
    }
  }

  Future<void> _fetchGalleryImages() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (permitted.isAuth) {
      List<AssetPathEntity> albums =
          await PhotoManager.getAssetPathList(type: RequestType.all);
      if (albums.isNotEmpty) {
        AssetPathEntity album = albums.first;
        List<AssetEntity> assets = await album.getAssetListPaged(page: 0, size: 9999);
        setState(() {
          _galleryImages = assets;
          _isGalleryLoading = false;
        });
      }
    }
  }

  Future<void> setSelectedImage(AssetEntity newAsset) async {
    if (newAsset.type == AssetType.video) {
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
      }
      File? file = await newAsset.file;
      if (file != null) {
        _videoPlayerController = VideoPlayerController.file(file);
        await _videoPlayerController!.initialize();
        _videoPlayerController!.setLooping(true);
        _videoPlayerController!.play();
      }
    } else {
      if (_videoPlayerController != null) {
        await _videoPlayerController!.dispose();
        _videoPlayerController = null;
      }
    }
    setState(() {
      selectedImage = newAsset;
    });
    if (widget.onMediaSelected != null) {
      widget.onMediaSelected!(newAsset);
    }
  }

  void clearSelectedImage() async {
    if (_videoPlayerController != null) {
      await _videoPlayerController!.dispose();
      _videoPlayerController = null;
    }
    setState(() {
      selectedImage = null;
    });
    if (widget.onMediaSelected != null) {
      widget.onMediaSelected!(null);
    }
  }

  Future<void> _toggleFlash() async {
    if (!_isCameraInitialized) return;
    _isFlashOn = !_isFlashOn;
    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    setState(() {});
  }

  Future<void> flipCamera() async {
    if (_cameras.length < 2) return;
    _selectedCameraIndex = (_selectedCameraIndex + 1) % _cameras.length;
    await _cameraController!.dispose();
    _cameraController =
        CameraController(_cameras[_selectedCameraIndex], ResolutionPreset.medium);
    await _cameraController!.initialize();
    await _cameraController!.setFlashMode(_isFlashOn ? FlashMode.torch : FlashMode.off);
    _currentZoom = 0.7;
    await _cameraController!.setZoomLevel(_currentZoom);
    setState(() {});
  }

  Future<void> _startRecording() async {
    if (_isRecording) return;
    _isRecording = true;
    _recordStartTime = DateTime.now();
    setState(() {});
    _animationController.forward();

    await _cameraController!.startVideoRecording();
    Timer.periodic(Duration(seconds: 1), (timer) {
      if (_isRecording) {
        setState(() {
          _recordDuration = DateTime.now().difference(_recordStartTime).inSeconds.toDouble();
        });
        if (_recordDuration >= maxRecordDuration) {
          _stopRecording();
          timer.cancel();
        }
      }
    });
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;
    await _cameraController!.stopVideoRecording();
    setState(() {
      _isRecording = false;
      _recordDuration = 0;
    });
    _animationController.reset();
  }

  void _onCapturePressed() {
    if (!_isRecording) {
      _cameraController!.takePicture().then((XFile? file) {
        if (file != null) {
          setSelectedImage(selectedImage!);  // Adjust this logic if you want to handle the captured image differently
        }
      });
    }
  }

  void _onLongPressStart(LongPressStartDetails details) {
    _startRecording();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _stopRecording();
  }

  void _openGallerySheet() {
    setState(() {
      _isGallerySheetOpen = true;
    });
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 1.0,
          builder: (context, scrollController) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.grey[800],
                borderRadius: BorderRadius.vertical(top: Radius.circular(16.0)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.symmetric(vertical: 8.0),
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.5),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () {
                      setState(() {
                        _isGallerySheetOpen = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _galleryImages.length,
                      itemBuilder: (context, index) {
                        AssetEntity asset = _galleryImages[index];
                        return GestureDetector(
                          onTap: () async {
                            await setSelectedImage(asset);
                            Navigator.pop(context);
                          },
                          child: Stack(
                            children: [
                              FutureBuilder(
                                future: asset.thumbnailDataWithSize(ThumbnailSize(200, 200)),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done &&
                                      snapshot.hasData) {
                                    return Image.memory(
                                      snapshot.data as Uint8List,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    );
                                  }
                                  return Container(color: Colors.black);
                                },
                              ),
                              if (asset.type == AssetType.video)
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: Icon(
                                    Icons.videocam,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (selectedImage != null) {
          clearSelectedImage();
          return false;
        }
        return true;
      },
      child: Stack(
        children: [
          if (!_isGallerySheetOpen)
            if (_isCameraPermissionGranted && _isCameraInitialized && selectedImage == null)
              Positioned.fill(
                child: CameraPreview(_cameraController!),
              )
            else if (selectedImage != null)
              Positioned.fill(
                child: selectedImage!.type == AssetType.video
                    ? (_videoPlayerController != null && _videoPlayerController!.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _videoPlayerController!.value.aspectRatio,
                            child: VideoPlayer(_videoPlayerController!),
                          )
                        : Center(child: CircularProgressIndicator()))
                    : FutureBuilder(
                        future: selectedImage!.thumbnailDataWithSize(ThumbnailSize(500, 500)),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.done && snapshot.hasData) {
                            return Image.memory(
                              snapshot.data as Uint8List,
                              fit: BoxFit.contain,
                            );
                          }
                          return Container(color: Colors.black);
                        },
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
                          value: _progressAnimation.value,
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
