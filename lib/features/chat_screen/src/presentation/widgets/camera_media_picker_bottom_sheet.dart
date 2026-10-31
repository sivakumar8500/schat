import 'dart:io';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';
import 'package:schat/utils/common_colors.dart';
import 'package:schat/utils/common_fontstyles.dart';

class CameraMediaPickerBottomSheet extends StatefulWidget {
  final VoidCallback onTakePhoto;
  final VoidCallback onRecordVideo;
  final VoidCallback onOpenGallery;
  final void Function(File file, bool isVideo) onMediaSelected;

  const CameraMediaPickerBottomSheet({
    super.key,
    required this.onTakePhoto,
    required this.onRecordVideo,
    required this.onOpenGallery,
    required this.onMediaSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required VoidCallback onTakePhoto,
    required VoidCallback onRecordVideo,
    required VoidCallback onOpenGallery,
    required void Function(File file, bool isVideo) onMediaSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CameraMediaPickerBottomSheet(
        onTakePhoto: onTakePhoto,
        onRecordVideo: onRecordVideo,
        onOpenGallery: onOpenGallery,
        onMediaSelected: onMediaSelected,
      ),
    );
  }

  @override
  State<CameraMediaPickerBottomSheet> createState() => _CameraMediaPickerBottomSheetState();
}

class _CameraMediaPickerBottomSheetState extends State<CameraMediaPickerBottomSheet> {
  List<AssetEntity> _assets = [];
  bool _isLoading = true;
  bool _hasPermission = false;
  String? _loadingAssetId;

  @override
  void initState() {
    super.initState();
    _loadRecentAssets();
  }

  Future<void> _loadRecentAssets() async {
    try {
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      if (!mounted) return;

      if (permission.isAuth || permission.hasAccess) {
        setState(() {
          _hasPermission = true;
          _isLoading = true;
        });

        final List<AssetPathEntity> paths = await PhotoManager.getAssetPathList(
          type: RequestType.common,
          onlyAll: true,
        );

        if (paths.isNotEmpty) {
          final List<AssetEntity> entities = await paths.first.getAssetListRange(
            start: 0,
            end: 80,
          );
          if (mounted) {
            setState(() {
              _assets = entities;
              _isLoading = false;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _assets = [];
              _isLoading = false;
            });
          }
        }
      } else {
        if (mounted) {
          setState(() {
            _hasPermission = false;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading media assets: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _onAssetTapped(AssetEntity asset) async {
    if (_loadingAssetId != null) return;
    setState(() => _loadingAssetId = asset.id);

    try {
      final File? file = await asset.file;
      if (!mounted) return;

      if (file != null) {
        final isVideo = asset.type == AssetType.video;
        Navigator.pop(context);
        widget.onMediaSelected(file, isVideo);
      } else {
        setState(() => _loadingAssetId = null);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load media file')),
        );
      }
    } catch (e) {
      debugPrint('Error getting asset file: $e');
      if (mounted) {
        setState(() => _loadingAssetId = null);
      }
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final isDark = colors.isDark;
    final sheetHeight = MediaQuery.of(context).size.height * 0.72;

    return Container(
      height: sheetHeight,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 8),
                width: 38,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Two Action Buttons Row: Take Photo & Record Video
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: 'Take Photo',
                      subtitle: 'Camera',
                      icon: Icons.photo_camera_rounded,
                      iconColor: const Color(0xFF9E00FF),
                      backgroundColor: const Color(0xFF9E00FF).withValues(alpha: 0.1),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onTakePhoto();
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionCard(
                      context: context,
                      title: 'Record Video',
                      subtitle: 'Video',
                      icon: Icons.videocam_rounded,
                      iconColor: const Color(0xFFF04438),
                      backgroundColor: const Color(0xFFF04438).withValues(alpha: 0.1),
                      onTap: () {
                        Navigator.pop(context);
                        widget.onRecordVideo();
                      },
                    ),
                  ),
                ],
              ),
            ),

            // Section Header: Recent Photos & Videos with Gallery action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Photos',
                    style: context.bodyLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      widget.onOpenGallery();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: colors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.photo_library_rounded, size: 16, color: colors.primary),
                          const SizedBox(width: 5),
                          Text(
                            'Gallery',
                            style: context.bodySmall.copyWith(
                              color: colors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 4),

            // Gallery Grid / Content
            Expanded(
              child: _buildGalleryContent(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    final colors = context.colors;
    final isDark = colors.isDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F4F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: context.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: context.bodySmall.copyWith(
                        color: colors.textHint,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGalleryContent(BuildContext context) {
    final colors = context.colors;

    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colors.primary,
        ),
      );
    }

    if (!_hasPermission) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.photo_library_outlined, size: 30, color: colors.primary),
              ),
              const SizedBox(height: 16),
              Text(
                'Access Your Photos',
                style: context.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                'Allow access to your photo library to share photos and videos directly from chat.',
                textAlign: TextAlign.center,
                style: context.bodySmall.copyWith(color: colors.textHint),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => PhotoManager.openSetting(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                child: const Text('Open Settings', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  widget.onOpenGallery();
                },
                child: Text('Choose from Gallery Picker', style: TextStyle(color: colors.primary)),
              ),
            ],
          ),
        ),
      );
    }

    if (_assets.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.photo_library_outlined, size: 48, color: colors.textHint.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text(
              'No photos or videos found',
              style: context.bodyMedium.copyWith(color: colors.textHint),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () {
                Navigator.pop(context);
                widget.onOpenGallery();
              },
              icon: const Icon(Icons.folder_open_rounded, size: 18),
              label: const Text('Browse Files'),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1.0,
      ),
      itemCount: _assets.length,
      itemBuilder: (context, index) {
        final asset = _assets[index];
        final isVideo = asset.type == AssetType.video;
        final isSelected = _loadingAssetId == asset.id;

        return ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Media Thumbnail using AssetEntityImageProvider
              AssetEntityImage(
                asset,
                isOriginal: false,
                thumbnailSize: const ThumbnailSize.square(250),
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey.shade300,
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  );
                },
              ),

              // Video overlay badge
              if (isVideo)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.65),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.videocam_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatDuration(asset.duration),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Loading overlay when selected
              if (isSelected)
                Container(
                  color: Colors.black45,
                  child: const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // InkWell for ripple and tap
              Positioned.fill(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _onAssetTapped(asset),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

