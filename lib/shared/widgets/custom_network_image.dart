import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart'; // 🌟 웹/앱 구분을 위해 반드시 추가!

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

    // 🌟🌟🌟 2. [추가된 핵심 코드]
    // 모바일 OS(안드로이드/iOS)의 HTTP 차단 보안 정책을 피하기 위해 강제로 HTTPS로 변환합니다.
    String secureUrl = imageUrl;
    if (imageUrl.startsWith('http://')) {
      secureUrl = imageUrl.replaceFirst('http://', 'https://');
    }

    // 🌟 3. [완벽 수정] 이 위젯 내부에서 웹과 앱을 한 번에 처리합니다!
    // 웹(Web)일 때만 CORS 우회 프록시를 사용하고, 앱(Mobile)일 때는 위에서 보안 처리된 secureUrl을 그대로 씁니다.
    final targetUrl = kIsWeb
        ? 'https://wsrv.nl/?url=${Uri.encodeComponent(secureUrl)}'
        : secureUrl;

    // 4. Image.network 대신 CachedNetworkImage 사용 (캐싱 + 부드러운 로딩)
    return CachedNetworkImage(
      imageUrl: targetUrl, // 🌟 변환된 최종 URL 전달
      width: width,
      height: height,
      fit: fit,
      // 5. 로딩 중일 때 보여줄 UI (빙글빙글)
      placeholder: (context, url) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Center(child: CircularProgressIndicator(strokeWidth: 2.0)),
      ),
      // 6. 로딩 실패 시 앱 터짐 방지
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