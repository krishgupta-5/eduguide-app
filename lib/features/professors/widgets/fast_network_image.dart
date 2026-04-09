import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:eduguide/features/professors/services/image_cache_manager.dart';
import 'package:eduguide/core/utils/image_utils.dart';

class FastNetworkImage extends StatefulWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Widget? placeholder;
  final Widget? errorWidget;

  const FastNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit,
    this.placeholder,
    this.errorWidget,
  });

  @override
  State<FastNetworkImage> createState() => _FastNetworkImageState();
}

class _FastNetworkImageState extends State<FastNetworkImage> {
  Uint8List? _imageBytes;
  bool _hasError = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(FastNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.imageUrl != oldWidget.imageUrl) {
      _loadImage();
    }
  }

  void _loadImage() async {
    if (!mounted ||
        widget.imageUrl.isEmpty ||
        !isValidImageUrl(widget.imageUrl)) {
      print('FastNetworkImage: Invalid URL rejected: ${widget.imageUrl}');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _hasError = true;
      });
      return;
    }

    print('FastNetworkImage: Loading valid URL: ${widget.imageUrl}');
    setState(() {
      _isLoading = true;
      _hasError = false;
    });

    try {
      final bytes = await CustomImageLoader.loadImageBytes(widget.imageUrl);
      if (!mounted) return;

      setState(() {
        _imageBytes = bytes;
        _hasError = bytes == null;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return widget.placeholder ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.grey, size: 24),
          );
    }

    if (_hasError || _imageBytes == null) {
      return widget.errorWidget ??
          Container(
            width: widget.width,
            height: widget.height,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person, color: Colors.grey, size: 24),
          );
    }

    return ClipOval(
      child: Image.memory(
        _imageBytes!,
        width: widget.width,
        height: widget.height,
        fit: widget.fit ?? BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return widget.errorWidget ??
              Container(
                width: widget.width,
                height: widget.height,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person, color: Colors.grey, size: 24),
              );
        },
      ),
    );
  }
}
