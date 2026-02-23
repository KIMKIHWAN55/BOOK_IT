import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// 🌟 [1] 채팅 메시지 데이터 모델
class ChatMessage {
  final String text;
  final bool isMe;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.isMe, required this.timestamp});
}

// 🌟 [2] 상태 클래스 (메시지 목록과 로딩 상태 관리)
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

// 🌟 [3] 컨트롤러: OpenAI 통신 및 Firestore 데이터 주입 (RAG)
class ChatController extends Notifier<ChatState> {
  // 🚨 본인의 OpenAI API 키를 여기에 입력하세요 (sk-... 로 시작함)
  final String _openAiApiKey = '여기에_OPENAI_API_키를_넣으세요';

  @override
  ChatState build() {
    // 초기 인사말 세팅
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

  // 유저가 메시지를 보냈을 때 실행되는 함수
  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    // 1. 유저 메시지를 화면에 먼저 추가하고 로딩 스피너 돌리기
    final userMsg = ChatMessage(text: text, isMe: true, timestamp: DateTime.now());
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      isLoading: true,
    );

    try {
      // 2. 🌟 [핵심] Firestore에서 우리 앱에 등록된 책 목록 긁어오기
      final bookListText = await _fetchBooksFromFirestore();

      // 3. OpenAI에 질문 던지기 (가스라이팅 프롬프트 포함)
      final aiResponse = await _askToChatGPT(text, bookListText);

      // 4. AI 답변을 화면에 추가
      final aiMsg = ChatMessage(text: aiResponse, isMe: false, timestamp: DateTime.now());
      state = state.copyWith(
        messages: [...state.messages, aiMsg],
        isLoading: false,
      );
    } catch (e) {
      // 에러 처리
      final errorMsg = ChatMessage(text: "앗! 부기가 책을 찾다가 넘어졌어요. 다시 한 번 말씀해주시겠어요? 🥲\n(에러: $e)", isMe: false, timestamp: DateTime.now());
      state = state.copyWith(
        messages: [...state.messages, errorMsg],
        isLoading: false,
      );
    }
  }

  // 📖 Firestore에서 책 데이터를 텍스트로 변환해서 가져오는 함수
  Future<String> _fetchBooksFromFirestore() async {
    final snapshot = await FirebaseFirestore.instance.collection('books').limit(50).get(); // 요금 방어를 위해 50권만

    if (snapshot.docs.isEmpty) return "현재 등록된 책이 없습니다.";

    // GPT가 읽기 편하게 "1. 데미안 (카테고리: 소설) - 줄거리: ..." 형태로 문자열 압축
    StringBuffer buffer = StringBuffer();
    for (var doc in snapshot.docs) {
      final data = doc.data();
      buffer.writeln("- 제목: ${data['title']}");
      buffer.writeln("  작가: ${data['author']}");
      buffer.writeln("  카테고리: ${data['category']}");
      buffer.writeln("  줄거리: ${data['description']}");
      buffer.writeln("---");
    }
    return buffer.toString();
  }

  // 🤖 OpenAI API와 통신하는 함수
  Future<String> _askToChatGPT(String userText, String bookList) async {
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // 🌟 [최강의 시스템 프롬프트] GPT 멱살 잡기
    final systemPrompt = """
너는 'Bookit(북잇)' 앱의 친절한 인공지능 사서 꼬부기 캐릭터 '부기'야. 🐢 
사용자가 상황을 말하면 아래 제공된 [보유 도서 목록] 안에서만 가장 잘 어울리는 책을 딱 1~2권만 골라서 추천해줘.

[절대 규칙]
1. 반드시 [보유 도서 목록]에 있는 책만 추천할 것. 세상에 있는 다른 유명한 책을 지어내서 추천하면 절대 안 돼.
2. 목록에 어울리는 책이 없다면 "현재 도서관에는 딱 맞는 책이 없네요 ㅠ_ㅠ 대신 이 책은 어떠세요?" 하고 목록 내에서 가장 비슷한 걸 추천해.
3. 말투는 친절하고 귀여운 사서처럼 해줘. 문장 끝에 가끔 이모지(🐢, 📚, ✨)를 써줘.

[보유 도서 목록]
$bookList
""";

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=utf-8',
        'Authorization': 'Bearer $_openAiApiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini", // 빠르고 가성비 좋은 최신 모델
        "messages": [
          {"role": "system", "content": systemPrompt},
          {"role": "user", "content": userText}
        ],
        "temperature": 0.7, // 창의성 조절 (1에 가까울수록 아무말 대잔치)
      }),
    );

    if (response.statusCode == 200) {
      // 한글 깨짐 방지를 위해 utf8.decode 사용
      final responseData = jsonDecode(utf8.decode(response.bodyBytes));
      return responseData['choices'][0]['message']['content'];
    } else {
      throw Exception("GPT 서버 통신 실패");
    }
  }
}

// 🌟 [4] Provider 생성
final chatControllerProvider = NotifierProvider<ChatController, ChatState>(() {
  return ChatController();
});