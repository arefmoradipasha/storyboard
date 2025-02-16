import 'dart:io';
import 'package:flutter/material.dart';
import 'package:storyboard/widget/uploads/challenges/ChallengeSelection.dart';
import 'package:video_player/video_player.dart';


class FinalMediaScreen extends StatefulWidget {
  final String mediaPath;

  const FinalMediaScreen({Key? key, required this.mediaPath}) : super(key: key);

  @override
  _FinalMediaScreenState createState() => _FinalMediaScreenState();
}

class _FinalMediaScreenState extends State<FinalMediaScreen> {
  VideoPlayerController? _videoController;
  double _currentPosition = 0.0;
  bool _showPlayPauseIcon = false;
  bool _isPlaying = false; // برای ذخیره وضعیت پخش

  bool _isVideo(String path) {
    return path.toLowerCase().endsWith('.mp4') ||
        path.toLowerCase().endsWith('.temp');
  }

  @override
  void initState() {
    super.initState();
    if (_isVideo(widget.mediaPath)) {
      _videoController = VideoPlayerController.file(File(widget.mediaPath))
        ..initialize().then((_) {
          setState(() {});
          _videoController!.play();
          _isPlaying = true;
          _videoController!.addListener(() {
            if (_videoController!.value.isInitialized) {
              setState(() {
                _currentPosition =
                    _videoController!.value.position.inMilliseconds.toDouble();
              });
            }
          });
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  void _togglePlayback() {
    if (_videoController != null && _videoController!.value.isInitialized) {
      setState(() {
        _isPlaying = !_isPlaying;
        _showPlayPauseIcon = true; // نمایش آیکون پخش/توقف در وسط صفحه
      });

      if (_isPlaying) {
        _videoController!.play();
      } else {
        _videoController!.pause();
      }

      // بعد از 1.5 ثانیه آیکون را مخفی کن
      Future.delayed(const Duration(milliseconds: 1500), () {
        setState(() {
          _showPlayPauseIcon = false;
        });
      });
    }
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return "${twoDigits(minutes)}:${twoDigits(seconds)}";
  }

  @override
  Widget build(BuildContext context) {
    if (_isVideo(widget.mediaPath)) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: GestureDetector(
            onTap: _togglePlayback, // کلیک روی ویدیو برای پاز/پلی
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_videoController != null &&
                    _videoController!.value.isInitialized)
                  AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  )
                else
                  const CircularProgressIndicator(),
                if (_showPlayPauseIcon)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Icon(
                      _isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.pop(context); // بازگشت به صفحه قبلی
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _videoController != null &&
                _videoController!.value.isInitialized
            ? Container(
                decoration: const BoxDecoration(
                  color: Color.fromARGB(255, 12, 9, 26),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                  border: Border(
                    top: BorderSide(color: Colors.white, width: 1),
                  ),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _formatDuration(_videoController!.value.position),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                          Text(
                            _formatDuration(_videoController!.value.duration),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: Slider(
                            min: 0,
                            max: _videoController!.value.duration.inMilliseconds
                                .toDouble(),
                            value: _currentPosition.clamp(
                              0,
                              _videoController!.value.duration.inMilliseconds
                                  .toDouble(),
                            ),
                            onChanged: (value) {
                              setState(() {
                                _currentPosition = value;
                              });
                              _videoController!.seekTo(
                                  Duration(milliseconds: value.toInt()));
                            },
                            activeColor: Colors.white,
                            inactiveColor: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () {
                                print("بعدی pressed");
                              },
                              child: const Text("بعدی",
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    const Color.fromARGB(255, 29, 26, 41),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Container(
                            height: 38,
                            child: ElevatedButton(
                              onPressed: () {
                                // توقف ویدیو قبل از نمایش چالش
                                if (_videoController != null &&
                                    _videoController!.value.isPlaying) {
                                  setState(() {
                                    _videoController!.pause();
                                    _isPlaying = false;
                                  });
                                }
                                // نمایش لیست چالش‌ها به‌صورت Bottom Sheet
                                ChallengeSelection.show(context);
                              },
                              child: const Text("انتخاب چالش",
                                  style: TextStyle(
                                      color: Color.fromARGB(255, 9, 25, 100),
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )
            : null,
      );
    } else {
      // اگر عکس باشد، فقط نمایش تصویر است
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Image.file(
            File(widget.mediaPath),
            fit: BoxFit.contain,
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            color: Color.fromARGB(255, 12, 9, 26),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
            border: Border(
              top: BorderSide(color: Colors.white, width: 1),
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      print("بعدی pressed");
                    },
                    child: const Text("بعدی",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color.fromARGB(255, 29, 26, 41),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 38,
                  child: ElevatedButton(
                    onPressed: () {
                      // نمایش چالش‌ها به‌صورت Bottom Sheet (نیاز به اجرای همان عمل انتخاب چالش که در ویدیو هست)
                      ChallengeSelection.show(context);
                    },
                    child: const Text("انتخاب چالش",
                        style: TextStyle(
                            color: Color.fromARGB(255, 9, 25, 100),
                            fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}
