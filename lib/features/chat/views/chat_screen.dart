import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/chat_controller.dart'; // 🌟 아까 만든 컨트롤러 임포트

// 🌟 State 대신 ConsumerState를 사용하여 Riverpod 상태 감지
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // 🌟 전송 버튼 누를 때 로직 변경 (Controller 호출)
  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    // 1. 키보드 내리기
    FocusScope.of(context).unfocus();

    // 2. 입력창 비우기
    _textController.clear();

    // 3. 컨트롤러의 sendMessage 호출 (AI에게 질문 전송!)
    ref.read(chatControllerProvider.notifier).sendMessage(text);

    // 4. 스크롤 아래로 부드럽게 내리기
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100, // 조금 더 넉넉하게 스크롤
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 1. ChatController의 상태를 실시간으로 감시!
    final chatState = ref.watch(chatControllerProvider);
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;

    // AI가 답변을 마쳤을 때 스크롤 한 번 더 튕겨주기
    ref.listen(chatControllerProvider, (prev, next) {
      if (prev?.isLoading == true && next.isLoading == false) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('부기와 대화하기', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: const Color(0xFFF2F2F2),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
              itemCount: messages.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) return _buildDateDivider();
                return _buildChatBubble(messages[index - 1]);
              },
            ),
          ),

          // 🌟 로딩 중일 때 부기가 타이핑 치는 듯한 인디케이터 표시
          if (isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
              child: Row(
                children: [
                  CircleAvatar(radius: 14, backgroundImage: AssetImage('assets/images/boogi_final.png'), backgroundColor: Colors.transparent),
                  SizedBox(width: 8),
                  Text("부기가 열심히 책을 찾고 있어요... 🐢🔍", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

          _buildMessageInputArea(isLoading),
        ],
      ),
    );
  }

  // 날짜 구분선
  Widget _buildDateDivider() {
    final formattedDate = DateFormat('yyyy년 M월 d일 EEEE', 'ko_KR').format(DateTime.now());
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(color: Colors.black.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Text(formattedDate, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ),
      ),
    );
  }

  // 말풍선 (기존과 동일)
  Widget _buildChatBubble(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        mainAxisAlignment: message.isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isMe)
            const CircleAvatar(backgroundImage: AssetImage('assets/images/boogi_final.png'), backgroundColor: Colors.transparent, radius: 18),
          if (!message.isMe) const SizedBox(width: 8),

          Flexible(
            child: Column(
              crossAxisAlignment: message.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                if (!message.isMe)
                  const Padding(padding: EdgeInsets.only(bottom: 4.0, left: 4.0), child: Text('부기', style: TextStyle(color: Colors.grey, fontSize: 13))),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (message.isMe)
                      Padding(padding: const EdgeInsets.only(right: 8.0, bottom: 4.0), child: Text(DateFormat('a h:mm', 'ko_KR').format(message.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 11))),

                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                        decoration: BoxDecoration(
                          color: message.isMe ? AppColors.primary : Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                            bottomLeft: message.isMe ? const Radius.circular(20) : Radius.zero,
                            bottomRight: message.isMe ? Radius.zero : const Radius.circular(20),
                          ),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, 2))],
                        ),
                        child: Text(message.text, style: TextStyle(color: message.isMe ? Colors.white : Colors.black, fontSize: 15, height: 1.4)),
                      ),
                    ),

                    if (!message.isMe)
                      Padding(padding: const EdgeInsets.only(left: 8.0, bottom: 4.0), child: Text(DateFormat('a h:mm', 'ko_KR').format(message.timestamp), style: const TextStyle(color: Colors.grey, fontSize: 11))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 하단 입력창 (로딩 중일 땐 입력 막기 추가)
  Widget _buildMessageInputArea(bool isLoading) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE0E0E0)))),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                enabled: !isLoading, // 🌟 GPT가 생각하는 동안엔 타자 못 치게 막기
                decoration: InputDecoration(
                  hintText: isLoading ? '부기가 책을 고르는 중이에요...' : '메시지를 입력하세요...',
                  hintStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24.0), borderSide: BorderSide.none),
                  filled: true, fillColor: const Color(0xFFF2F2F2),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
                ),
                textInputAction: TextInputAction.send,
                onSubmitted: isLoading ? null : _handleSubmitted,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: isLoading ? null : () => _handleSubmitted(_textController.text),
              child: Container(
                padding: const EdgeInsets.all(12.0),
                decoration: BoxDecoration(color: isLoading ? Colors.grey : AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.send, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}