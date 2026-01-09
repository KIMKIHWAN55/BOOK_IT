import 'package:flutter/material.dart';
import 'package:bookit_app/screens/write_post_screen.dart';

class PostBoardScreen extends StatefulWidget {
  const PostBoardScreen({super.key});

  @override
  State<PostBoardScreen> createState() => _PostBoardScreenState();
}

class _PostBoardScreenState extends State<PostBoardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  // 🔸 피그마 CSS 기반 공통 스타일
  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF222222),
    double? height = 1.4,
    double spacing = -0.025,
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * spacing,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildRecentFeed(), // 최근 소식 탭
                const Center(child: Text("좋아요 콘텐츠")),
                const Center(child: Text("나의 글 콘텐츠")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- 상단 앱바 ---
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      // 🔸 메인 탭이므로 leading(뒤로가기) 버튼 삭제
      automaticallyImplyLeading: false, // 자동으로 뒤로가기 버튼 생기는 것 방지
      actions: [
        IconButton(icon: const Icon(Icons.search, color: Colors.black), onPressed: () {}),
        IconButton(icon: const Icon(Icons.notifications_none, color: Colors.black), onPressed: () {}),
        IconButton(
          icon: const Icon(Icons.edit_square, color: Colors.black, size: 24),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const WritePostScreen()),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // --- 상단 탭바 ---
  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      height: 60,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFFD45858),
        indicatorWeight: 2,
        labelColor: const Color(0xFFD45858),
        unselectedLabelColor: Colors.black,
        labelStyle: _ptStyle(size: 17, weight: FontWeight.w400),
        tabs: const [
          Tab(text: "최근 소식"),
          Tab(text: "좋아요"),
          Tab(text: "나의 글"),
        ],
      ),
    );
  }

  // --- 최근 소식 피드 리스트 ---
  Widget _buildRecentFeed() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      children: [
        // 피드 1
        _buildPostCard(
          userName: "책돌이",
          userRank: "팔로워 2K명 • 방금",
          recTitle: "🌟 이번 주 추천도서",
          content: "봄이 오는 길목에서 읽기 좋은 감성 소설을 추천드려요. 일상 속 작은 행복을 발견하게 해주는 따뜻한 이야기입니다.",
          hashtags: "#감성소설 #봄 #힐링",
          bookTitle: "그 시절 내가 좋아했던",
          bookAuthor: "김민수",
          bookRating: "4.7",
          bookReviewCount: "13",
          bookImageUrl: 'https://i.ibb.co/b6yFp7G/book1.jpg',
          likes: "11", comments: "6", shares: "8",
        ),
        const SizedBox(height: 24),
        // 피드 2
        _buildPostCard(
          userName: "booklover_33",
          userRank: "팔로워 768명 • 30분전",
          recTitle: "“시간의 틈새에서 진실을 마주하다”",
          content: "처음엔 복잡한 시간 개념 때문에 따라가기 어려웠지만, 갈수록 철학적인 질문이 마음에 남았다. “내가 내 과거를 바꿀 수 있다면, 과연 지금의 나는 존재할 수 있을까?”",
          hashtags: "#SF #반전 #미스테리",
          bookTitle: "Paradox",
          bookAuthor: "호베루투 카를로스",
          bookRating: "4.8",
          bookReviewCount: "762",
          bookImageUrl: 'https://i.ibb.co/3sHHDq2/paradox-cover.jpg',
          likes: "126", comments: "47", shares: "82",
        ),
      ],
    );
  }

  // --- 공통 포스트 카드 위젯 ---
  Widget _buildPostCard({
    required String userName, required String userRank, required String recTitle,
    required String content, required String hashtags, required String bookTitle,
    required String bookAuthor, required String bookRating, required String bookReviewCount,
    required String bookImageUrl, required String likes, required String comments, required String shares,
  }) {
    return Container(
      width: 358,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50, height: 50,
                decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFDBDBDB)),
                child: const Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(userName, style: _ptStyle(size: 14, weight: FontWeight.w500)),
                  Text(userRank, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(recTitle, style: _ptStyle(size: 16, weight: FontWeight.w400)),
          const SizedBox(height: 12),
          Text(content, style: _ptStyle(size: 16, weight: FontWeight.w400, height: 1.4)),
          const SizedBox(height: 20),
          Text(hashtags, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF196DF8))),
          const SizedBox(height: 20),
          Container(
            height: 110,
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFFF1F1F5)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(bookImageUrl, width: 73, height: 110, fit: BoxFit.cover),
                    ),
                    const SizedBox(width: 40),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(bookTitle, style: _ptStyle(size: 16, weight: FontWeight.w500)),
                        Text(bookAuthor, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF777777))),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                            const SizedBox(width: 2),
                            Text(bookRating, style: _ptStyle(size: 12, weight: FontWeight.w400, color: const Color(0xFFFBBC05))),
                            Text(" ($bookReviewCount)", style: _ptStyle(size: 12, weight: FontWeight.w400, color: const Color(0xFF777777))),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
                Positioned(
                  right: 10, bottom: 10,
                  child: Row(
                    children: [
                      Text("책 보러가기", style: _ptStyle(size: 16, weight: FontWeight.w400, color: const Color(0xFF111111))),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              _buildInteractionItem(Icons.favorite_border, likes),
              const SizedBox(width: 30),
              _buildInteractionItem(Icons.chat_bubble_outline, comments),
              const SizedBox(width: 30),
              _buildInteractionItem(Icons.send_outlined, shares),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionItem(IconData icon, String count) {
    return Row(
      children: [
        Icon(icon, size: 24, color: const Color(0xFF222222)),
        const SizedBox(width: 4),
        Text(count, style: _ptStyle(size: 12, weight: FontWeight.w400)),
      ],
    );
  }
}