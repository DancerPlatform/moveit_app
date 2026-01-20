import '../models/dance_studio.dart';

class MockData {
  MockData._();

  static const List<DanceStudio> studios = [
    DanceStudio(
      id: '1',
      name: '원밀리언 댄스 스튜디오',
      imageUrl: 'https://images.unsplash.com/photo-1508700929628-666bc8bd84ea?w=400',
      rating: 4.9,
      reviewCount: 328,
      location: '마포구 합정동',
      distance: '350m',
      pricePerMonth: 150000,
      genres: ['K-pop', '힙합', '코레오'],
      hasDiscount: true,
      discountPercent: 30,
    ),
    DanceStudio(
      id: '2',
      name: '저스트 댄스 아카데미',
      imageUrl: 'https://images.unsplash.com/photo-1535525153412-5a42439a210d?w=400',
      rating: 4.7,
      reviewCount: 156,
      location: '마포구 상수동',
      distance: '500m',
      pricePerMonth: 120000,
      genres: ['방송댄스', '걸스힙합'],
      hasDiscount: true,
      discountPercent: 20,
    ),
    DanceStudio(
      id: '3',
      name: '뮤즈 댄스 스쿨',
      imageUrl: 'https://images.unsplash.com/photo-1547153760-18fc86324498?w=400',
      rating: 4.8,
      reviewCount: 89,
      location: '마포구 망원동',
      distance: '800m',
      pricePerMonth: 100000,
      genres: ['재즈', '현대무용', '발레'],
      hasDiscount: false,
    ),
    DanceStudio(
      id: '4',
      name: '스트릿 킹 댄스',
      imageUrl: 'https://images.unsplash.com/photo-1504609813442-a8924e83f76e?w=400',
      rating: 4.6,
      reviewCount: 201,
      location: '마포구 연남동',
      distance: '1.2km',
      pricePerMonth: 130000,
      genres: ['힙합', '팝핀', '락킹'],
      hasDiscount: true,
      discountPercent: 15,
    ),
    DanceStudio(
      id: '5',
      name: '플로우 댄스 스튜디오',
      imageUrl: 'https://images.unsplash.com/photo-1518834107812-67b0b7c58434?w=400',
      rating: 4.5,
      reviewCount: 67,
      location: '마포구 서교동',
      distance: '600m',
      pricePerMonth: 90000,
      genres: ['왁킹', '보깅', '하우스'],
      hasDiscount: false,
    ),
  ];

  static const List<Promotion> promotions = [
    Promotion(
      id: '1',
      title: '댄스학원 3곳을\n1곳 가격으로 다니는 법',
      subtitle: '통합회원권 서비스 소개',
      imageUrl: '',
      backgroundColor: '#6C5CE7',
      discountPercent: 80,
    ),
    Promotion(
      id: '2',
      title: '첫 체험 수업\n무료 이벤트',
      subtitle: '신규 회원 한정',
      imageUrl: '',
      backgroundColor: '#E91E63',
      discountPercent: 100,
    ),
    Promotion(
      id: '3',
      title: '친구 추천하면\n1만원 할인',
      subtitle: '추천인도 함께 할인',
      imageUrl: '',
      backgroundColor: '#00B894',
    ),
  ];
}
