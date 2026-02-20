import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/views/login_screen.dart';
import '../../admin/views/admin_book_list_screen.dart';
import '../../admin/views/admin_add_book_screen.dart';
import '../models/user_model.dart';
import '../controllers/profile_controller.dart';
import 'profile_edit_screen.dart';
import 'settings_screen.dart';
import 'liked_books_screen.dart';
import '../../board/controllers/board_controller.dart';
import 'package:bookit_app/shared/widgets/post_card.dart';
import '../../book/models/book_model.dart';
import '../../book/views/book_detail_screen.dart';

// 🌟 [추가] 분리해둔 공통 상단 바 위젯 Import
import '../../../shared/widgets/custom_app_bar.dart';

// 🌟 [추가] 개별 책의 상세 정보를 캐싱하고 불러오기 위한 Provider
final bookItemDetailProvider = FutureProvider.family<BookModel?, String>((ref, bookId) async {
  return await ref.read(profileActionControllerProvider).getBookDetail(bookId);
});

// 🌟 [추가] 좋아요한 책들의 '실제 데이터'를 조회해 가장 많이 나온 장르 3개를 뽑아주는 Provider
final topGenresProvider = FutureProvider.autoDispose<List<String>?>((ref) async {
  // 1. 좋아요한 책 목록(요약본) 불러오기
  final likedBooksSnapshot = await ref.watch(likedBooksProvider.future);
  final docs = likedBooksSnapshot.docs;

  // 좋아요한 책이 하나도 없으면 null 반환
  if (docs.isEmpty) return null;

  Map<String, int> tagCounts = {};
  final profileController = ref.read(profileActionControllerProvider);

  // 2. 각 책의 '전체 상세 정보'를 가져와서 태그(장르) 수집
  for (var doc in docs) {
    BookModel listBookModel = BookModel.fromFirestore(doc);
    final fullBook = await profileController.getBookDetail(listBookModel.id);

    if (fullBook != null) {
      final tags = fullBook.tags;

      if (tags.isNotEmpty) {
        for (var tag in tags) {
          final cleanTag = tag.replaceAll('#', '').trim();
          if (cleanTag.isNotEmpty) {
            tagCounts[cleanTag] = (tagCounts[cleanTag] ?? 0) + 1;
          }
        }
      }
    }
  }

  // 전체 정보를 다 뒤져봐도 태그가 없으면 빈 리스트 반환
  if (tagCounts.isEmpty) return [];

  // 빈도수가 높은 순으로 정렬 후 상위 3개 추출
  var sortedTags = tagCounts.keys.toList()
    ..sort((a, b) => tagCounts[b]!.compareTo(tagCounts[a]!));

  return sortedTags.take(3).toList();
});

class MyPageScreen extends ConsumerStatefulWidget {
  const MyPageScreen({super.key});

  @override
  ConsumerState<MyPageScreen> createState() => _MyPageScreenState();
}

// 탭 컨트롤러를 유지해야 하므로 ConsumerStatefulWidget 사용
class _MyPageScreenState extends ConsumerState<MyPageScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // 로그아웃 처리
  Future<void> _handleLogout() async {
    await ref.read(profileActionControllerProvider).logout();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
            (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 실시간 유저 정보 구독 (Riverpod)
    final userProfileAsync = ref.watch(userProfileProvider);

    return userProfileAsync.when(
      data: (userModel) {
        if (userModel == null) {
          return const Scaffold(body: Center(child: Text("로그인이 필요합니다.")));
        }

        // 관리자 권한 확인
        final bool isAdmin = userModel.role == 'admin';

        if (isAdmin) {
          return _buildAdminLayout(userModel);
        }
        return _buildUserLayout(userModel);
      },
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, st) => Scaffold(body: Center(child: Text("사용자 정보를 불러오지 못했습니다.\n$e"))),
    );
  }

  // ============================================================
  //  1. 관리자(Admin) 레이아웃
  // ============================================================
  Widget _buildAdminLayout(UserModel userModel) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),

      // 🌟 [적용 완료] 한 줄로 깔끔해진 관리자 페이지 상단바
      appBar: const CustomAppBar(
        title: "관리자 페이지",
        showSearch: false,
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            _buildInfoCard(
              child: Row(
                children: [
                  _buildProfileImage(userModel, size: 50),
                  const SizedBox(width: 14),
                  const Text(
                    '관리자',
                    style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminAddBookScreen())),
              child: _buildInfoCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('도서 등록', style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                    Icon(Icons.chevron_right, size: 24, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminBookListScreen())),
              child: _buildInfoCard(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('도서 수정', style: TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222))),
                    Icon(Icons.chevron_right, size: 24, color: Colors.black),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
            _buildLogoutButton(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  //  2. 일반 사용자(User) 레이아웃
  // ============================================================
  Widget _buildUserLayout(UserModel userModel) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F1F5),

      // 🌟 [적용 완료] 한 줄로 깔끔해진 유저 마이페이지 상단바
      appBar: const CustomAppBar(
        title: "내 정보",
        showSearch: false,
      ),

      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    GestureDetector(
                      onTap: () {
                        // 수정 페이지에서 돌아와도 StreamProvider가 자동으로 최신화해 줌
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const ProfileEditScreen()),
                        );
                      },
                      child: _buildInfoCard(
                        child: Row(
                          children: [
                            _buildProfileImage(userModel, size: 50),
                            const SizedBox(width: 14),
                            Text(
                              userModel.nickname,
                              style: const TextStyle(fontFamily: 'Pretendard', fontSize: 18, fontWeight: FontWeight.w500, color: Color(0xFF222222)),
                            ),
                            const Spacer(),
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // 🌟 수정된 부분: 동적 소개글 및 태그 렌더링
                    _buildInfoCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 1. 내가 작성한 소개글 (bio)
                          Text(
                            userModel.bio.isNotEmpty
                                ? userModel.bio
                                : "안녕 나는 ${userModel.nickname}이야 반가워", // 소개글이 없을 때 기본값
                            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF222222)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),

                          // 🌟 2. 새로 만든 topGenresProvider를 사용해 진짜 장르 불러오기
                          ref.watch(topGenresProvider).when(
                            data: (topTags) {
                              if (topTags == null) {
                                return const Text(
                                  "아직 좋아하는 책이 없어요",
                                  style: TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF196DF8)),
                                );
                              }
                              if (topTags.isEmpty) {
                                return const Text(
                                  "장르를 분석할 수 없어요",
                                  style: TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF196DF8)),
                                );
                              }

                              final tagsText = "${topTags.map((t) => "#$t").join(" ")} 장르 좋아해";

                              return Text(
                                tagsText,
                                style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, color: Color(0xFF196DF8)),
                              );
                            },
                            loading: () => const Text("선호 장르 분석 중...", style: TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Colors.grey)),
                            error: (_, __) => const Text("장르를 불러올 수 없어요", style: TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Colors.grey)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: const Color(0xFF000000),
                  unselectedLabelColor: const Color(0xFF767676),
                  indicatorColor: const Color(0xFFED7777),
                  indicatorWeight: 2,
                  labelStyle: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w600),
                  tabs: const [
                    Tab(text: "좋아요한 책"),
                    Tab(text: "좋아요한 피드"),
                  ],
                ),
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildLikedBooksList(), // 좋아요한 책 스트림 위젯
            _buildLikedFeedsList(), // 피드 목록
          ],
        ),
      ),
    );
  }

  // 🌟 고정 높이(height)를 제거하고 위아래 패딩(vertical)을 추가해 내용에 맞게 유연하게 조절
  Widget _buildInfoCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            offset: const Offset(1, 1),
            blurRadius: 1,
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildProfileImage(UserModel userModel, {required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F4),
        shape: BoxShape.circle,
        image: userModel.profileImage != null && userModel.profileImage!.isNotEmpty
            ? DecorationImage(image: NetworkImage(userModel.profileImage!), fit: BoxFit.cover)
            : null,
      ),
      child: userModel.profileImage == null || userModel.profileImage!.isEmpty
          ? Icon(Icons.person, size: size * 0.6, color: Colors.grey)
          : null,
    );
  }

  // 🌟 [수정] 위젯 분리를 통해 훨씬 짧아진 좋아요한 책 리스트 코드
  Widget _buildLikedBooksList() {
    final likedBooksAsync = ref.watch(likedBooksProvider);

    return likedBooksAsync.when(
      data: (snapshot) {
        final docs = snapshot.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("좋아요한 책이 없습니다.", style: TextStyle(color: Colors.grey)));
        }

        final bool hasMore = docs.length > 4;
        final int displayCount = hasMore ? 4 : docs.length;

        return ListView.builder(
          padding: const EdgeInsets.only(top: 10, bottom: 20),
          itemCount: hasMore ? displayCount + 1 : displayCount,
          itemBuilder: (context, index) {
            // 더보기 버튼
            if (hasMore && index == displayCount) {
              return Container(
                margin: const EdgeInsets.only(top: 10),
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const LikedBooksScreen()),
                    );
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Text("더보기", style: TextStyle(color: Color(0xFF767676), fontSize: 14)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_forward_ios, size: 12, color: Color(0xFF767676)),
                    ],
                  ),
                ),
              );
            }

            // Firestore 요약 문서를 넘겨서, 진짜 평점과 데이터를 가져오는 LikedBookListItem 위젯 호출
            var doc = docs[index];
            BookModel listBookModel = BookModel.fromFirestore(doc);

            return LikedBookListItem(summaryBook: listBookModel);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => const Center(child: Text("데이터를 불러오는 중 오류가 발생했습니다.")),
    );
  }

  Widget _buildLikedFeedsList() {
    final likedPostsAsync = ref.watch(likedPostsProvider);

    return likedPostsAsync.when(
      data: (posts) {
        if (posts.isEmpty) {
          return const Center(
            child: Text("좋아요한 피드가 없습니다.", style: TextStyle(color: Colors.grey)),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.only(top: 16, bottom: 20, left: 16, right: 16),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 24),
          itemBuilder: (context, index) {
            return PostCard(post: posts[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(child: Text("오류가 발생했습니다.\n$e")),
    );
  }

  Widget _buildLogoutButton() {
    return TextButton(
      onPressed: _handleLogout,
      child: const Text("로그아웃", style: TextStyle(color: Colors.grey, decoration: TextDecoration.underline)),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;
  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: const Color(0xFFF1F1F5),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
        ),
        child: _tabBar,
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

// ============================================================
// 🌟 [추가] 진짜 평점과 리뷰 수를 표시해 줄 분리된 리스트 아이템 위젯
// ============================================================
class LikedBookListItem extends ConsumerWidget {
  final BookModel summaryBook;
  const LikedBookListItem({super.key, required this.summaryBook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🌟 Provider를 통해 전체 책 데이터를 실시간으로 가져옵니다 (스크롤 시 중복 호출 방지 캐싱)
    final fullBookAsync = ref.watch(bookItemDetailProvider(summaryBook.id));

    // 로딩 중일 때는 요약본(summaryBook)을, 데이터가 성공적으로 오면 전체 데이터(fullBookAsync.value)를 보여줍니다.
    final displayBook = fullBookAsync.value ?? summaryBook;

    return GestureDetector(
      onTap: () {
        // 데이터를 다 불러온 상태라면 로딩 다이얼로그 없이 즉시 상세 페이지로 이동합니다.
        if (fullBookAsync.value != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BookDetailScreen(book: fullBookAsync.value!),
            ),
          );
        } else {
          // 혹시 아직 불러오는 중이라면 띄워주는 안내 메시지
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("책 상세 정보를 불러오는 중입니다. 잠시만 기다려주세요.")),
          );
        }
      },
      child: Container(
        height: 136,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(bottom: BorderSide(color: const Color(0xFFD1D1D1).withOpacity(0.5), width: 0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
          child: Row(
            children: [
              // 책 이미지
              Container(
                width: 73,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.grey[200],
                  image: displayBook.imageUrl.isNotEmpty
                      ? DecorationImage(
                    image: NetworkImage(displayBook.imageUrl),
                    fit: BoxFit.cover,
                    onError: (e, s) {},
                  )
                      : null,
                ),
                child: displayBook.imageUrl.isEmpty
                    ? const Icon(Icons.book, color: Colors.grey)
                    : null,
              ),
              const SizedBox(width: 20),
              // 책 텍스트 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayBook.title.isNotEmpty ? displayBook.title : '제목 없음',
                      style: const TextStyle(fontFamily: 'Pretendard', fontSize: 16, fontWeight: FontWeight.w500, letterSpacing: -0.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      displayBook.author.isNotEmpty ? displayBook.author : '저자 미상',
                      style: const TextStyle(fontFamily: 'Pretendard', fontSize: 14, color: Color(0xFF777777), letterSpacing: -0.5),
                      maxLines: 1, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    // 🌟 드디어 실제 평점과 리뷰수가 제대로 연동되어 뜹니다!
                    Row(
                      children: [
                        const Icon(Icons.star, size: 14, color: Color(0xFFFBBC05)),
                        const SizedBox(width: 2),
                        Text(
                            displayBook.rating.isNotEmpty ? displayBook.rating : "0.0",
                            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 12, fontWeight: FontWeight.w400)
                        ),
                        const SizedBox(width: 4),
                        Text(
                            "(${displayBook.reviewCount.isNotEmpty ? displayBook.reviewCount : "0"})",
                            style: const TextStyle(fontFamily: 'Pretendard', fontSize: 12, color: Color(0xFF777777))
                        ),
                      ],
                    )
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}