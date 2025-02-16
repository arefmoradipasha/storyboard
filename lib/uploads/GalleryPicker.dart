import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:storyboard/uploads/CameraScreen.dart';
import 'package:storyboard/uploads/FinalMediaScreen.dart';
import 'package:storyboard/uploads/VideoTrimmer.dart';
import 'package:storyboard/widget/uploads/tabs/music_tab.dart';
import 'package:storyboard/widget/uploads/tabs/post_tab.dart';
import 'package:storyboard/widget/uploads/tabs/story_tab.dart';


class GalleryScreen extends StatefulWidget {
  @override
  _GalleryScreenState createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final List<String> bottomItems = ["پست", "موسیقی", "داستان"];
  int activeBottomItemIndex = 0;
  late final PageController _pageController = PageController(
    initialPage: 500,
    viewportFraction: 0.35,
  );

  List<AssetPathEntity> postAlbums = [];
  AssetPathEntity? selectedPostAlbum;
  final GlobalKey<PostTabState> _postTabKey = GlobalKey<PostTabState>();
  final GlobalKey<StoryTabState> _storyTabKey = GlobalKey<StoryTabState>();

  bool _isAnimating = false;
  AssetEntity? fixedBottomAsset; // برای تب داستان

  // متغیر جهت نگهداری مسیر رسانه انتخاب‌شده
  String? _selectedMediaPath;

  void _onPostAlbumsLoaded(List<AssetPathEntity> albums, AssetPathEntity selectedAlbum) {
    setState(() {
      postAlbums = albums;
      selectedPostAlbum = selectedAlbum;
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchFixedBottomAsset();
  }

  Future<void> _fetchFixedBottomAsset() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (permitted.isAuth) {
      List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.all);
      if (albums.isNotEmpty) {
        AssetPathEntity album = albums.first;
        List<AssetEntity> assets = await album.getAssetListPaged(page: 0, size: 9999);
        if (assets.isNotEmpty) {
          assets.shuffle(Random());
          setState(() {
            fixedBottomAsset = assets.first;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildContent() {
    switch (activeBottomItemIndex) {
      case 0:
        return PostTab(
          key: _postTabKey,
          onAlbumsLoaded: _onPostAlbumsLoaded,
          onMediaSelected: (mediaPath) {
            setState(() {
              _selectedMediaPath = mediaPath;
            });
          },
        );
      case 1:
        return MusicTab();
      case 2:
        return StoryTab(
          key: _storyTabKey,
          onMediaSelected: (asset) {
            // در صورت نیاز می‌توانید رسانه انتخاب‌شده برای داستان را دریافت کنید.
          },
        );
      default:
        return Container();
    }
  }

  Future<bool> _onWillPop() async {
    if (activeBottomItemIndex == 2 &&
        _storyTabKey.currentState != null &&
        _storyTabKey.currentState!.selectedImage != null) {
      _storyTabKey.currentState?.clearSelectedImage();
      return false;
    }
    return true;
  }

  void _openStoryGallerySheet() {
    if (_storyTabKey.currentState == null ||
        _storyTabKey.currentState!.galleryImages.isEmpty) {
      print("گالری در حال بارگذاری است");
      return;
    }
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
                  Expanded(
                    child: GridView.builder(
                      controller: scrollController,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 2,
                        mainAxisSpacing: 2,
                      ),
                      itemCount: _storyTabKey.currentState!.galleryImages.length,
                      itemBuilder: (context, index) {
                        AssetEntity asset = _storyTabKey.currentState!.galleryImages[index];
                        return GestureDetector(
                          onTap: () async {
                            await _storyTabKey.currentState?.setSelectedImage(asset);
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
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: activeBottomItemIndex == 2
            ? null
            : AppBar(
                leading: activeBottomItemIndex == 0
                    ? null
                    : Padding(
                        padding: EdgeInsets.only(top: 8.0), // تغییر در فاصله
                        child: IconButton(
                          icon: Icon(Icons.photo_library, color: Colors.white),
                          onPressed: () {},
                        ),
                      ),
                title: activeBottomItemIndex == 0
                    ? (postAlbums.isNotEmpty && selectedPostAlbum != null
                        ? Padding(
                            padding: EdgeInsets.only(top: 8.0), // تغییر در فاصله
                            child: Container(
                              width: 120,
                              child: DropdownButton<AssetPathEntity>(
                                isExpanded: true,
                                value: selectedPostAlbum,
                                dropdownColor: Colors.grey[800],
                                style: TextStyle(color: Colors.white),
                                iconEnabledColor: Colors.white,
                                underline: Container(),
                                items: postAlbums
                                    .map((album) => DropdownMenuItem(
                                          value: album,
                                          child: Text(
                                            album.name,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (newAlbum) {
                                  setState(() {
                                    selectedPostAlbum = newAlbum;
                                  });
                                  _postTabKey.currentState?.setSelectedAlbum(newAlbum);
                                },
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.only(top: 8.0), // تغییر در فاصله
                            child: Text("انتخاب پوشه"),
                          ))
                    : Text(bottomItems[activeBottomItemIndex]),
                actions: [
                  Padding(
                    padding: EdgeInsets.only(top: 8.0), // تغییر در فاصله
                    child: IconButton(
                      icon: Icon(Icons.close, size: 26),
                      onPressed: () {
                        // Navigator.of(context).pop();
                      },
                    ),
                  ),
                ],
              ),
        backgroundColor: Colors.black,
        body: _buildContent(),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Color.fromARGB(255, 12, 9, 26),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.0),
              topRight: Radius.circular(16.0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.white,
                spreadRadius: 0.5,
                blurRadius: 0,
                offset: Offset(0, -1),
              ),
            ],
          ),
          padding: EdgeInsets.all(8.0),
          child: Row(
            children: [
              activeBottomItemIndex == 2
                  ? GestureDetector(
                      onTap: _openStoryGallerySheet,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.grey,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Builder(
                          builder: (context) {
                            if (fixedBottomAsset != null) {
                              return FutureBuilder(
                                future: fixedBottomAsset!.thumbnailDataWithSize(ThumbnailSize(100, 100)),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.done &&
                                      snapshot.hasData) {
                                    return ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.memory(
                                        snapshot.data as Uint8List,
                                        fit: BoxFit.cover,
                                      ),
                                    );
                                  }
                                  return Container();
                                },
                              );
                            } else {
                              return Icon(Icons.camera_alt, color: Colors.white);
                            }
                          },
                        ),
                      ),
                    )
                  : ElevatedButton(
                      onPressed: () {
                        if (activeBottomItemIndex == 0) {
                          _postTabKey.currentState?.stopVideoPlayback();

                          if (_selectedMediaPath != null) {
                            if (_selectedMediaPath!.toLowerCase().endsWith('.mp4') ||
                                _selectedMediaPath!.toLowerCase().endsWith('.temp')) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => MediaPreviewScreen(mediaPath: _selectedMediaPath!),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FinalMediaScreen(mediaPath: _selectedMediaPath!),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text("لطفاً ابتدا یک عکس یا ویدیو انتخاب کنید.")),
                            );
                          }
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CameraScreenA(),
                            ),
                          ).then((capturedMediaPath) {
                            if (capturedMediaPath != null) {
                              setState(() {
                                _selectedMediaPath = capturedMediaPath;
                              });
                              _postTabKey.currentState?.setExternalMedia(capturedMediaPath);
                            }
                          });
                        }
                      },
                      child: Text(
                        "بعدی",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color.fromARGB(255, 12, 9, 26),
                        ),
                      ),
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.all(Colors.white),
                        shape: MaterialStateProperty.all(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
              SizedBox(width: 8),
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: PageView.builder(
                    controller: _pageController,
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final actualIndex = index % bottomItems.length;
                      bool isActive = (actualIndex == activeBottomItemIndex);
                      return AnimatedContainer(
                        duration: Duration(milliseconds: 300),
                        margin: EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: isActive ? Color.fromARGB(255, 24, 18, 48) : Colors.transparent,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          bottomItems[actualIndex],
                          style: TextStyle(
                            color: isActive ? Colors.white : Color.fromARGB(255, 102, 102, 102),
                          ),
                        ),
                      );
                    },
                    onPageChanged: (page) {
                      int actualIndex = page % bottomItems.length;
                      setState(() {
                        activeBottomItemIndex = actualIndex;
                      });
                      if (!_isAnimating) {
                        HapticFeedback.vibrate();
                      }
                    },
                  ),
                ),
              ),
              SizedBox(width: 8),
              activeBottomItemIndex == 2
                  ? IconButton(
                      onPressed: () {
                        _storyTabKey.currentState?.flipCamera();
                      },
                      icon: Icon(Icons.cameraswitch, color: Colors.white),
                    )
                  : IconButton(
                      onPressed: () {
                        _postTabKey.currentState?.stopVideoPlayback();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CameraScreenA(),
                          ),
                        ).then((capturedMediaPath) {
                          if (capturedMediaPath != null) {
                            setState(() {
                              _selectedMediaPath = capturedMediaPath;
                            });
                            _postTabKey.currentState?.setExternalMedia(capturedMediaPath);
                          }
                        });
                      },
                      icon: Icon(Icons.camera_alt, color: Colors.white),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
