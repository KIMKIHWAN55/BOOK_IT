import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
    // 1. 이미지가 비어있으면 바로 에러 박스
    if (imageUrl.isEmpty) {
      return _buildErrorPlaceholder();
    }

    // 2. 기존 핵심 로직 유지: 웹 CORS 에러 방지를 위한 프록시 포장
    final safeUrl = 'https://wsrv.nl/?url=${Uri.encodeComponent(imageUrl)}';

    // 3. Image.network 대신 CachedNetworkImage 사용 (캐싱 + 부드러운 로딩)
    return CachedNetworkImage(
      imageUrl: safeUrl, // 원본 URL이 아닌 안전한 프록시 URL을 전달!
      width: width,
      height: height,
      fit: fit,
      // 4. 로딩 중일 때 보여줄 UI (빙글빙글)
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      ),
      // 5. 로딩 실패 시 앱 터짐 방지
      errorWidget: (context, url, error) => _buildErrorPlaceholder(),
    );
  }

  // 에러 났을 때 보여줄 회색 박스 컴포넌트
  Widget _buildErrorPlaceholder() {
    return Container(
      width: width,
      height: height,
      color: Colors.grey[300],
      child: const Icon(Icons.book, color: Colors.grey, size: 30),
    );
  }
}