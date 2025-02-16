import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:shimmer/shimmer.dart';
import 'package:video_player/video_player.dart';

class PostTab extends StatefulWidget {
  final Function(List<AssetPathEntity>, AssetPathEntity)? onAlbumsLoaded;
  final ValueChanged<String>? onMediaSelected;

  const PostTab({
    Key? key,
    this.onAlbumsLoaded,
    this.onMediaSelected,
  }) : super(key: key);

  @override
  PostTabState createState() => PostTabState();
}

class PostTabState extends State<PostTab> {
  List<AssetEntity> mediaFiles = [];
  List<AssetPathEntity> albums = [];
  AssetEntity? selectedMedia;
  AssetPathEntity? selectedAlbum;
  VideoPlayerController? _videoController;
  bool _isLoading = true;

  // مسیر رسانه گرفته شده از دوربین (external)
  String? externalMediaPath;

  @override
  void initState() {
    super.initState();
    _fetchAlbums();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  Future<void> _fetchAlbums() async {
    final permitted = await PhotoManager.requestPermissionExtend();
    if (permitted.isAuth) {
      final fetchedAlbums = await PhotoManager.getAssetPathList(type: RequestType.all);
      fetchedAlbums.sort((a, b) => a.name.compareTo(b.name));
      setState(() {
        albums = fetchedAlbums;
        selectedAlbum = albums.firstWhere(
          (album) => album.isAll,
          orElse: () => albums.first,
        );
        _fetchMedia();
        widget.onAlbumsLoaded?.call(albums, selectedAlbum!);
      });
    }
  }

  Future<void> _fetchMedia() async {
    if (selectedAlbum != null) {
      final recentMedia = await selectedAlbum!.getAssetListPaged(page: 0, size: 9999);
      final filteredMedia = recentMedia.where((asset) =>
          asset.type == AssetType.image || asset.type == AssetType.video).toList();
      filteredMedia.sort((a, b) => b.createDateTime.compareTo(a.createDateTime));
      setState(() {
        mediaFiles = filteredMedia;
        if (mediaFiles.isNotEmpty) {
          selectedMedia = mediaFiles.first;
          externalMediaPath = null; // حذف حالت خارجی در صورت انتخاب از گالری
          _updateSelectedMedia();
          _notifyMediaSelection();
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _updateSelectedMedia() async {
    if (selectedMedia != null) {
      if (selectedMedia!.type == AssetType.video) {
        final file = await selectedMedia!.file;
        if (file != null) {
          _videoController?.pause();
          _videoController?.dispose();
          _videoController = VideoPlayerController.file(file)
            ..initialize().then((_) {
              setState(() {});
              _videoController!.play();
            });
        }
      } else {
        _videoController?.pause();
        _videoController?.dispose();
        _videoController = null;
      }
    }
  }

  Future<void> _notifyMediaSelection() async {
    if (externalMediaPath != null) {
      widget.onMediaSelected?.call(externalMediaPath!);
    } else if (selectedMedia != null) {
      final file = await selectedMedia!.file;
      if (file != null) {
        widget.onMediaSelected?.call(file.path);
      }
    }
  }

  // متد جهت تغییر آلبوم انتخاب‌شده
  void setSelectedAlbum(AssetPathEntity? newAlbum) {
    setState(() {
      selectedAlbum = newAlbum;
      _isLoading = true;
    });
    _fetchMedia();
  }

  // متد جهت بروزرسانی رسانه خارجی (از دوربین)
  void setExternalMedia(String? path) {
    setState(() {
      externalMediaPath = path;
      selectedMedia = null;
      _videoController?.pause();
      _videoController?.dispose();
      _videoController = null;
    });
  }

  // متد جدید برای توقف پخش ویدیو (تا صدای ویدیو قطع شود)
  void stopVideoPlayback() {
    if (_videoController != null && _videoController!.value.isPlaying) {
      _videoController!.pause();
    }
  }

  Widget _buildMediaPreview() {
    if (externalMediaPath != null) {
      // اگر پسوند فایل externalMediaPath به .mp4 یا .temp ختم شود، آن را به عنوان ویدیو در نظر می‌گیریم
      bool isVideo = externalMediaPath!.toLowerCase().endsWith(".mp4") ||
          externalMediaPath!.toLowerCase().endsWith(".temp");
      if (isVideo) {
        if (_videoController == null) {
          _videoController = VideoPlayerController.file(File(externalMediaPath!))
            ..initialize().then((_) {
              setState(() {});
              _videoController!.play();
            });
        }
        if (_videoController != null && _videoController!.value.isInitialized) {
          return Container(
            height: 340,
            width: double.infinity,
            child: ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),
          );
        } else {
          return Container(
            height: 320,
            color: Colors.black,
          );
        }
      } else {
        return Container(
          height: 320,
          width: double.infinity,
          child: ClipRRect(
            child: Image.file(
              File(externalMediaPath!),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    } else if (selectedMedia != null) {
      if (selectedMedia!.type == AssetType.video &&
          _videoController != null &&
          _videoController!.value.isInitialized) {
        return Container(
          height: 320,
          width: double.infinity,
          child: ClipRect(
            child: FittedBox(
              fit: BoxFit.cover,
              child: SizedBox(
                width: _videoController!.value.size.width,
                height: _videoController!.value.size.height,
                child: VideoPlayer(_videoController!),
              ),
            ),
          ),
        );
      } else {
        return Container(
          height: 320,
          width: double.infinity,
          child: FutureBuilder(
            future: selectedMedia!.thumbnailDataWithSize(ThumbnailSize(500, 500)),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.hasData) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(
                    snapshot.data as Uint8List,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                );
              }
              return Container(color: Colors.black);
            },
          ),
        );
      }
    } else {
      return Container(
        height: 320,
        color: Colors.black,
      );
    }
  }

  Widget _buildMediaGridItem(AssetEntity asset) {
    if (asset.type != AssetType.image && asset.type != AssetType.video) {
      return Container(color: Colors.grey);
    }
    return GestureDetector(
      key: ValueKey(asset.id),
      onTap: () async {
        if (selectedMedia != asset) {
          setState(() {
            selectedMedia = asset;
            externalMediaPath = null;
          });
          await _updateSelectedMedia();
          await _notifyMediaSelection();
        }
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: FutureBuilder(
                future: asset.thumbnailDataWithSize(ThumbnailSize(200, 200)),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.done &&
                      snapshot.hasData) {
                    return Image.memory(
                      snapshot.data as Uint8List,
                      fit: BoxFit.cover,
                    );
                  }
                  return Container(color: Colors.black);
                },
              ),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: Icon(
                asset.type == AssetType.video ? Icons.videocam : Icons.image,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostContent() {
    if (_isLoading) {
      return Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: Column(
          children: [
            Container(height: 320, color: Colors.black),
            Expanded(
              child: GridView.builder(
                gridDelegate:
                    SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
                itemCount: 12,
                itemBuilder: (context, index) => Container(color: Colors.black),
              ),
            ),
          ],
        ),
      );
    }
    return Column(
      children: [
        _buildMediaPreview(),
        SizedBox(height: 2,),
        Expanded(
          child: GridView.builder(
            gridDelegate:
                SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, mainAxisSpacing: 2, crossAxisSpacing: 2, ),
            itemCount: mediaFiles.length,
            itemBuilder: (context, index) => _buildMediaGridItem(mediaFiles[index]),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildPostContent();
  }
}
