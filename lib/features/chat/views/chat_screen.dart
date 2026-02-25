import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/chat_controller.dart';
import '../../board/controllers/board_controller.dart';
import '../../book/views/book_detail_screen.dart';

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

  void _handleSubmitted(String text) {
    if (text.trim().isEmpty) return;

    FocusScope.of(context).unfocus();

    _textController.clear();

    ref.read(chatControllerProvider.notifier).sendMessage(text);

    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent + 100,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final chatState = ref.watch(chatControllerProvider);
    final messages = chatState.messages;
    final isLoading = chatState.isLoading;

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

          // 로딩 중일 때 부기가 타이핑 치는 듯한 인디케이터 표시
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

// 말풍선 및 책 보러가기 버튼
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
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // 기존 AI 텍스트
                            Text(message.text, style: TextStyle(color: message.isMe ? Colors.white : Colors.black, fontSize: 15, height: 1.4)),

                            // 책 ID가 존재한다면 '책 보러가기' 버튼 띄우기
                            if (message.bookId != null) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    try {
                                      final book = await ref.read(boardControllerProvider).getBookDetail(message.bookId!);

                                      if (book != null && context.mounted) {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => BookDetailScreen(book: book)),
                                        );
                                      } else if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("책 정보를 찾을 수 없습니다.")));
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("오류가 발생했습니다.")));
                                      }
                                    }
                                  },
                                  icon: const Icon(Icons.auto_stories, size: 18),
                                  label: const Text("책 보러가기", style: TextStyle(fontWeight: FontWeight.bold)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFD45858),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                ),
                              ),
                            ]
                          ],
                        ),
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

  // 하단 입력창
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
                enabled: !isLoading, // gpt답변중에는 타자못치게하기
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