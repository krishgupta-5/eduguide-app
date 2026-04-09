import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:eduguide/features/professors/services/image_cache_manager.dart';

class CustomNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;
  final bool enableCache;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
    this.enableCache = true,
  });

  @override
  State<CustomNetworkImage> createState() => _CustomNetworkImageState();
}

class _CustomNetworkImageState extends State<CustomNetworkImage> {
  Uint8List? _imageBytes;
  bool _isLoading = false;
  bool _hasError = false;
  String? _lastImageUrl;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(CustomNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    if (!mounted || widget.imageUrl.isEmpty) return;

    // Avoid reloading the same image
    if (_lastImageUrl == widget.imageUrl && _imageBytes != null) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _lastImageUrl = widget.imageUrl;
    });

    try {
      final bytes = await CustomImageLoader.loadImageBytes(widget.imageUrl);
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _isLoading = false;
        _hasError = bytes == null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          SizedBox(
            width: widget.width,
            height: widget.height,
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          );
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            color: Colors.grey[200],
            child: const Icon(Icons.person, color: Colors.grey),
          );
    }

    return Image.memory(
      _imageBytes!,
      width: widget.width,
      height: widget.height,
      fit: widget.fit ?? BoxFit.cover,
      gaplessPlayback: true,
      errorBuilder: (context, error, stackTrace) {
        return widget.errorWidget ??
            Container(
              width: widget.width,
              height: widget.height,
              color: Colors.grey[200],
              child: const Icon(Icons.person, color: Colors.grey),
            );
      },
    );
  }
}
