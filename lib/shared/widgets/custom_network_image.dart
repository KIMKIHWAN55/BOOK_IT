import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';

class CustomNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CustomNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (imageUrl.isEmpty) {
      return _buildErrorPlaceholder();
    }

    // HTTP를 HTTPS로 변환
    String secureUrl = imageUrl;
    if (imageUrl.startsWith('http://')) {
      secureUrl = imageUrl.replaceFirst('http://', 'https://');
    }

    if (kIsWeb) {
      // 프록시 URL 적용
      final targetUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(secureUrl)}';

      // 웹에서는 Image.network사용
      return Image.network(
        targetUrl,
        width: width,
        height: height,
        fit: fit,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child; // 로딩 완료
          return _buildLoadingPlaceholder();
        },
        errorBuilder: (context, error, stackTrace) => _buildErrorPlaceholder(),
      );
    } else {
      return CachedNetworkImage(
        imageUrl: secureUrl,
        width: width,
        height: height,
        fit: fit,
        placeholder: (context, url) => _buildLoadingPlaceholder(),
        errorWidget: (context, url, error) => _buildErrorPlaceholder(),
      );
    }
  }

  // 로딩 중일 때 보여줄 UI
  Widget _buildLoadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2.0),
      ),
    );
  }

  // 에러 났을 때 보여줄 UI
  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.book, color: Colors.grey, size: 30),
    );
  }
}