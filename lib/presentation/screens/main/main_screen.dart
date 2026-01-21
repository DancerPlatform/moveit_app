import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings.dart';
import '../home/home_screen.dart';
import '../academy/academy_map_screen.dart';
import '../instructors/instructors_screen.dart';
import '../schedule/schedule_screen.dart';
import '../profile/profile_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  /// Navigate to a specific tab from anywhere in the app
  static void navigateToTab(BuildContext context, int index) {
    final state = context.findAncestorStateOfType<_MainScreenState>();
    state?._setTab(index);
  }

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void _setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  // Navigator keys for each tab to maintain separate navigation stacks
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  // Root screens for each tab
  final List<Widget Function()> _screenBuilders = [
    () => const HomeScreen(),
    () => const AcademyMapScreen(),
    () => const InstructorsScreen(),
    () => const ScheduleScreen(),
    () => const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Try to pop the current tab's navigator first
        final currentNavigator = _navigatorKeys[_currentIndex].currentState;
        if (currentNavigator != null && currentNavigator.canPop()) {
          currentNavigator.pop();
        }
      },
      child: Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: List.generate(
            _navigatorKeys.length,
            (index) => Navigator(
              key: _navigatorKeys[index],
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (_) => _screenBuilders[index](),
              ),
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(
                color: AppColors.divider,
                width: 0.5,
              ),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: const [
              // 홈
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: AppStrings.home,
              ),
              // 학원 지도
              BottomNavigationBarItem(
                icon: Icon(Icons.location_on_outlined),
                activeIcon: Icon(Icons.location_on),
                label: AppStrings.danceStudios,
              ),
              // 강사
              BottomNavigationBarItem(
                icon: Icon(Icons.person_search_outlined),
                activeIcon: Icon(Icons.person_search),
                label: AppStrings.instructors,
              ),
              // 일정
              BottomNavigationBarItem(
                icon: Icon(Icons.calendar_today_outlined),
                activeIcon: Icon(Icons.calendar_today),
                label: AppStrings.schedule,
              ),
              // 마이베이지
              BottomNavigationBarItem(
                icon: Icon(Icons.person_outline),
                activeIcon: Icon(Icons.person),
                label: AppStrings.myPage,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
