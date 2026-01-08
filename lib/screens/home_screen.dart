import 'package:flutter/material.dart';
import 'package:bookit_app/screens/intro_chat_screen.dart';
// 🔸 1. 게시판 화면 임포트 추가 (파일 경로를 확인해주세요)
import 'package:bookit_app/screens/post_board_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  TextStyle _ptStyle({
    required double size,
    required FontWeight weight,
    Color color = const Color(0xFF222222),
    double height = 1.4,
  }) {
    return TextStyle(
      fontFamily: 'Pretendard',
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
      letterSpacing: size * -0.025,
    );
  }

  // 🔸 2. 네비게이션 탭 클릭 로직 수정
  void _onItemTapped(int index) {
    // 검색 탭 (인덱스 1)
    if (index == 1) {
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const IntroChatScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ),
      );
    }
    // 🔥 3. 글쓰기 탭 (인덱스 2) 클릭 시 게시판 화면으로 이동
    else if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PostBoardScreen()),
      );
    }
    else {
      setState(() { _selectedIndex = index; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(onPressed: () {}, icon: const Icon(Icons.menu, color: Colors.white)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.search, color: Colors.white)),
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(onPressed: () => Navigator.pushNamed(context, '/cart'), icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white)),
              Positioned(top: 10, right: 8, child: _buildBadge("3")),
            ],
          ),
          IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none, color: Colors.white)),
        ],
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),

      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildTopRecommendation(),
            const SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('이번달 베스트 셀러', style: _ptStyle(size: 20, weight: FontWeight.w600)),
                  Text('더보기', style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF767676))),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _buildBestsellerItem(rank: '01', title: '그 시절 내가 좋아했던', author: '김민수', imageUrl: 'https://i.ibb.co/b6yFp7G/book1.jpg', rating: '4.7', reviewCount: '13'),
            _buildBestsellerItem(rank: '02', title: '장난 꾸러기 고양이 카를로스', author: '아스 트릭스', imageUrl: 'https://i.ibb.co/bK6D1ff/book2.jpg', rating: '4.8', reviewCount: '127'),
            _buildBestsellerItem(rank: '03', title: '사일런트', author: '매튜 조니', imageUrl: 'https://i.ibb.co/hL7g6Jt/book3.jpg', rating: '4.2', reviewCount: '91'),
            const SizedBox(height: 10),
            _buildSpecialBanner(),
            const SizedBox(height: 40),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: const Color(0xFFB8B8B8),
        showSelectedLabels: false,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '홈'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: '검색'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_outlined), label: '글쓰기'), // 🔸 index 2
          BottomNavigationBarItem(icon: Icon(Icons.bookmark_border), label: '서재'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: '내정보'),
        ],
      ),
    );
  }

  // ... (이하 _buildTopRecommendation, _buildPickCard 등 빌더 함수들은 기존과 동일) ...
  Widget _buildTopRecommendation() {
    return Container(
      width: double.infinity,
      height: 420,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Color(0x99999999), Color(0xB2222222)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 100),
          Text('이번주 추천 Pick!', style: _ptStyle(size: 22, weight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 30),
          SizedBox(
            height: 200,
            child: PageView.builder(
              itemCount: 6,
              controller: PageController(viewportFraction: 0.6),
              itemBuilder: (context, index) => _buildPickCard(),
            ),
          ),
          const SizedBox(height: 20),
          Text('1 / 6', style: _ptStyle(size: 16, weight: FontWeight.w600, color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildPickCard() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(-10, 15))],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Image.network('https://i.ibb.co/3sHHDq2/paradox-cover.jpg', fit: BoxFit.cover),
      ),
    );
  }

  Widget _buildBestsellerItem({required String rank, required String title, required String author, required String imageUrl, required String rating, required String reviewCount}) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: Row(
        children: [
          ClipRRect(borderRadius: BorderRadius.circular(6), child: Image.network(imageUrl, width: 73, height: 110, fit: BoxFit.cover)),
          const SizedBox(width: 27),
          Text(rank, style: _ptStyle(size: 20, weight: FontWeight.w600)),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: _ptStyle(size: 16, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Text(author, style: _ptStyle(size: 14, weight: FontWeight.w400, color: const Color(0xFF777777))),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFBBC05), size: 14),
                    const SizedBox(width: 4),
                    Text(rating, style: _ptStyle(size: 12, weight: FontWeight.w600, color: const Color(0xFFFBBC05))),
                    Text(' ($reviewCount)', style: _ptStyle(size: 12, weight: FontWeight.w400, color: const Color(0xFF777777))),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecialBanner() {
    return Container(
      width: 326, height: 150,
      margin: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: const Color(0xFF21212F), borderRadius: BorderRadius.circular(32)),
      child: Stack(
        children: [
          Positioned(
            left: 32, top: 36,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('여러분들을 위해\n지금 준비 했어요!', style: _ptStyle(size: 20, weight: FontWeight.w600, color: Colors.white, height: 1.2)),
                const SizedBox(height: 12),
                Text('다신 오지 않는 특별한 기획', style: _ptStyle(size: 14, weight: FontWeight.w400, color: Colors.white)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String count) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(color: Color(0xFFEA4335), shape: BoxShape.circle),
      child: Text(count, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
    );
  }
}