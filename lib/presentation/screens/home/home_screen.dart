import 'package:flutter/material.dart';

import 'widgets/home_header.dart';
import 'widgets/search_bar_widget.dart';
import 'widgets/categories.dart';
import 'widgets/feature_cards_grid.dart';
import 'widgets/promo_banner.dart';
import 'widgets/nearby_studios_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              HomeHeader(),
              // 검색 바
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: SearchBarWidget(),
              ),
              SizedBox(height: 16),
              // 히어로 배너
              PromoBanner(),
              SizedBox(height: 24),
              // 카테고리
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Categories(),
              ),
              SizedBox(height: 24),
              // Feature Grid
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: FeatureCardsGrid(),
              ),
              SizedBox(height: 24),
              // 주변 댄스 학원
              NearbyStudiosList(),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
