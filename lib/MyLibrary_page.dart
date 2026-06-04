import 'package:flutter/material.dart';
import 'package:project_1/Borrow_page.dart';
import 'package:project_1/History_page.dart';
import 'package:project_1/Reserve_page.dart';
import 'package:project_1/Wishlist_page.dart';
import 'package:project_1/Home_page.dart';
import 'package:project_1/Profile_page.dart';

const kRed = Color(0xFFE53935);
const kRedLight = Color(0xFFFFEBEE);

class MyLibraryPage extends StatelessWidget {
  final bool fromProfile;

  const MyLibraryPage({super.key, this.fromProfile = false});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: const Color(0xFFF6F6F2),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (fromProfile) {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProfilePage(),
                                ),
                              );
                            } else {
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const HomePage(),
                                ),
                                (route) => false,
                              );
                            }
                          },
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFFEEEEEE),
                              ),
                            ),
                            child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              size: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'My Library',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Tab bar — 4 tabs
                  const TabBar(
                    labelColor: kRed,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: kRed,
                    indicatorWeight: 2.5,
                    labelPadding: EdgeInsets.symmetric(horizontal: 6),
                    labelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                    unselectedLabelStyle: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                    tabs: [
                      Tab(text: 'Borrowed'),
                      Tab(text: 'Reserved'),
                      Tab(text: 'History'),
                      Tab(text: 'Wishlist'),
                    ],
                  ),

                  // Tab view
                  Expanded(
                    child: TabBarView(
                      children: [
                        BorrowPage(),
                        ReservePage(),
                        HistoryPage(),
                        WishlistPage(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Bottom nav
        bottomNavigationBar: _buildBottomNav(context),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    final items = [
      {'icon': Icons.home_rounded, 'label': 'Home'},
      {'icon': Icons.collections_bookmark_outlined, 'label': 'My Library'},
      {'icon': Icons.person_outline_rounded, 'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (i) {
          final active = i == 1;
          return GestureDetector(
            onTap: () {
              if (i == 0) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const HomePage()),
                  (route) => false,
                );
              } else if (i == 2) {
                // Profile এ যাও
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
              decoration: BoxDecoration(
                color: active ? kRedLight : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    items[i]['icon'] as IconData,
                    color: active ? kRed : const Color(0xFFBBBBBB),
                    size: 22,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    items[i]['label'] as String,
                    style: TextStyle(
                      color: active ? kRed : const Color(0xFFBBBBBB),
                      fontSize: 10,
                      fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
