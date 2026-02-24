import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // 🌟 파이어베이스 함수 패키지
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🌟 [1] 채팅 메시지 데이터 모델 (bookId 추가)
class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;
  final String? bookId; // 🌟 추천받은 책의 ID (책 보러가기 버튼용)

  ChatMessage({
    required this.text,
    required this.isMe,
    required this.timestamp,
    this.bookId,
  });
}

// 🌟 [2] 상태 클래스
class ChatState {
  final List<ChatMessage> messages;
  final bool isLoading;

  ChatState({this.messages = const [], this.isLoading = false});

  ChatState copyWith({List<ChatMessage>? messages, bool? isLoading}) {
    return ChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// 🌟 [3] 컨트롤러: 파이어베이스 서버(Cloud Functions) 호출
class ChatController extends Notifier<ChatState> {
  // 🚨 더 이상 플러터 앱에 OpenAI API 키를 적지 않습니다! (보안 100% 완벽)

  @override
  ChatState build() {
    return ChatState(
      messages: [
        ChatMessage(
          text: "안녕하세요! Bookit AI 사서 '부기'입니다. 🐢\n어떤 기분이나 상황인지 말씀해주시면, 저희 도서관에 있는 최고의 책을 찾아드릴게요!",
          isMe: false,
          timestamp: DateTime.now(),
        ),
      ],
    );
  }

  // ✉️ 유저가 메시지를 보냈을 때 실행
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    final userMsg = ChatMessage(text: text, isMe: true, timestamp: DateTime.now());
    state = state.copyWith(messages: [...state.messages, userMsg], isLoading: true);

    try {
      final bookListText = await _fetchBooksFromFirestore();

      // 서버에서 AI 답변 받아오기
      String aiResponse = await _askToChatGPT(text, bookListText);

      // 🌟 [핵심] AI 대답에서 [BOOK_ID:...] 부분만 쏙 빼내서 해독하기
      String? recommendedBookId;
      final RegExp regex = RegExp(r'\[BOOK_ID:(.*?)\]');
      final match = regex.firstMatch(aiResponse);

      if (match != null) {
        recommendedBookId = match.group(1); // 아이디 추출 완료
        aiResponse = aiResponse.replaceAll(regex, '').trim(); // 화면에 보일 텍스트에서는 지우기
      }

      // 해독한 bookId를 넣어서 메시지 저장
      final aiMsg = ChatMessage(
        text: aiResponse,
        isMe: false,
        timestamp: DateTime.now(),
        bookId: recommendedBookId,
      );

      state = state.copyWith(messages: [...state.messages, aiMsg], isLoading: false);
    } catch (e) {
      final errorMsg = ChatMessage(
          text: "앗! 부기가 책을 찾다가 넘어졌어요. 다시 한 번 말씀해주시겠어요? 🥲\n(에러: $e)",
          isMe: false,
          timestamp: DateTime.now()
      );
      state = state.copyWith(messages: [...state.messages, errorMsg], isLoading: false);
    }
  }

  // 📖 Firestore에서 책 데이터를 가져올 때 문서 ID도 같이 가져오기
  Future<String> _fetchBooksFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('books').limit(50).get();

    if (snapshot.docs.isEmpty) return "현재 등록된 책이 없습니다.";

    StringBuffer buffer = StringBuffer();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      buffer.writeln("- ID: ${doc.id}"); // 🌟 AI가 책을 특정할 수 있도록 문서 ID 전달
      buffer.writeln("  제목: ${data['title']}");
      buffer.writeln("  작가: ${data['author']}");
      buffer.writeln("  카테고리: ${data['category']}");
      buffer.writeln("  줄거리: ${data['description']}");
      buffer.writeln("---");
    }
    return buffer.toString();
  }

  // 🤖 파이어베이스 서버(Cloud Functions)와 통신하는 함수
  Future<String> _askToChatGPT(String userText, String bookList) async {
    try {
      // 🌟 HTTP 통신 대신, 우리가 방금 배포한 파이어베이스 함수를 직접 호출!
      final result = await FirebaseFunctions.instance
          .httpsCallable('askToChatGPT')
          .call({
        'userText': userText,
        'bookList': bookList,
      });

      // 파이어베이스 서버가 돌려준 AI의 대답
      return result.data['result'] as String;
    } catch (e) {
      throw Exception("서버 통신 실패: $e");
    }
  }
}

// 🌟 [4] Provider 생성
final chatControllerProvider = NotifierProvider<ChatController, ChatState>(() {
  return ChatController();
});