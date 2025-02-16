import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_trimmer/video_trimmer.dart';
import 'FinalMediaScreen.dart';

class MediaPreviewScreen extends StatefulWidget {
  final String mediaPath;

  const MediaPreviewScreen({Key? key, required this.mediaPath}) : super(key: key);

  @override
  _MediaPreviewScreenState createState() => _MediaPreviewScreenState();
}

class _MediaPreviewScreenState extends State<MediaPreviewScreen> {
  bool _progressVisibility = false;
  String? _outputPath; // مسیر ویدیوی برش‌خورده

  final Trimmer _trimmer = Trimmer();
  double _startValue = 0.0;
  double _endValue = 0.0;
  bool _isPlaying = false;
  bool _isIconVisible = false; // برای کنترل نمایش آیکون

  // تابع بررسی نوع فایل (ویدیو یا عکس)
  bool _isVideo(String path) {
    return path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.temp');
  }

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.mediaPath)) {
      _loadVideo();
    }
  }

  @override
  void dispose() {
    _trimmer.dispose();
    super.dispose();
  }

  // بارگذاری ویدیو برای تریم
  Future<void> _loadVideo() async {
    try {
      await _trimmer.loadVideo(videoFile: File(widget.mediaPath));
      setState(() {
        _endValue =
            _trimmer.videoPlayerController!.value.duration.inSeconds.toDouble();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("بارگذاری ویدیو با مشکل مواجه شد.")),
      );
    }
  }

  // ذخیره ویدیو برش‌خورده
  Future<void> _saveTrimmedVideo() async {
    setState(() {
      _progressVisibility = true;
    });

    final String formattedDate =
        DateTime.now().toString().replaceAll(RegExp(r'[:.-]'), '');

    await _trimmer.saveTrimmedVideo(
      startValue: _startValue,
      endValue: _endValue,
      videoFileName: "Trimmed_${formattedDate}.mp4",
      storageDir: StorageDir.temporaryDirectory,
      onSave: (String? outputPath) async {
        if (outputPath != null) {
          setState(() {
            _outputPath = outputPath;
            _progressVisibility = false;
          });

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => FinalMediaScreen(mediaPath: _outputPath!),
            ),
          );
        } else {
          setState(() {
            _progressVisibility = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("برش ویدیو با مشکل مواجه شد.")),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.mediaPath)) {
      return Scaffold(
        body: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      onTap: () async {
                        setState(() {
                          _isIconVisible = true;
                        });

                        bool playbackState = await _trimmer.videoPlaybackControl(
                          startValue: _startValue,
                          endValue: _endValue,
                        );
                        setState(() {
                          _isPlaying = playbackState;
                        });

                        await Future.delayed(Duration(seconds: 2));
                        setState(() {
                          _isIconVisible = false;
                        });
                      },
                      child: Stack(
                        children: [
                          VideoViewer(trimmer: _trimmer),
                          if (_isIconVisible)
                            Center(
                              child: Container(
                                padding: EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _isPlaying ? Icons.pause : Icons.play_arrow,
                                  size: 40.0,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                // قرار دادن بخش پایین در SafeArea برای بچسباندن به پایین صفحه
                SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color.fromARGB(255, 12, 9, 26),
                      border: Border(
                        top: BorderSide(color: Colors.white, width: 2),
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(10),
                        topRight: Radius.circular(10),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TrimViewer(
                          trimmer: _trimmer,
                          durationStyle: DurationStyle.FORMAT_MM_SS,
                          durationTextStyle: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                          viewerHeight: 55.0,
                          viewerWidth: MediaQuery.of(context).size.width,
                          maxVideoLength: Duration(seconds: 30),
                          editorProperties: TrimEditorProperties(
                            sideTapSize: 10,
                            borderPaintColor:
                                const Color.fromARGB(255, 225, 225, 225),
                            borderWidth: 0.6,
                            borderRadius: 10,
                            circlePaintColor:
                                const Color.fromARGB(255, 200, 80, 207),
                            circleSize: 10,
                          ),
                          areaProperties: TrimAreaProperties.edgeBlur(
                            thumbnailQuality: 100,
                            blurEdges: true,
                            blurColor: Colors.black,
                            thumbnailFit: BoxFit.cover,
                          ),
                          onChangeStart: (value) =>
                              setState(() => _startValue = value),
                          onChangeEnd: (value) =>
                              setState(() => _endValue = value),
                          onChangePlaybackState: (value) =>
                              setState(() => _isPlaying = value),
                        ),
                        Container(
                          margin: EdgeInsets.only(top: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                height: 30,
                                child: ElevatedButton(
                                  onPressed: _progressVisibility
                                      ? null
                                      : _saveTrimmedVideo,
                                  child: Text(
                                    "تمام",
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 225, 225, 225),
                                  ),
                                ),
                              ),
                              Text(
                                "برای تنظیم ویدیو بکشید",
                                style: TextStyle(
                                    color:
                                        Color.fromARGB(255, 67, 70, 75)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            if (_progressVisibility)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
              ),
            // دکمه ضربدر در بالای سمت راست (با SafeArea)
            SafeArea(
              child: Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    icon: Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: Center(child: Text("هیچ رسانه‌ای پیدا نشد")),
      );
    }
  }
}
