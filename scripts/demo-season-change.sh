#!/bin/bash
# 시연용: 가을 → 겨울 테마 전환 시나리오

echo "=========================================="
echo "  시연: 가을 → 겨울 테마 전환"
echo "=========================================="
echo ""

echo "1단계: 현재 테마 확인..."
echo "  브라우저에서 localStorage.getItem('theme') 확인"
echo ""

echo "2단계: 겨울 테마로 전환..."
echo "  브라우저 콘솔에서 실행:"
echo "    changeTheme('winter')"
echo ""

echo "3단계: 로그인 후 이벤트 배너 확인"
echo "  - list.html 페이지에서 '겨울 맞이 이벤트' 배너 표시"
echo ""

echo "4단계: 룰렛 페이지 접속"
echo "  - 배너의 '참여하기' 버튼 클릭"
echo "  - 또는 직접: http://your-site/roulette"
echo ""

echo "5단계: 룰렛 돌리기"
echo "  - '룰렛 돌리기' 버튼 클릭"
echo "  - 결과 확인 및 저장"
echo ""

echo "=========================================="
echo "  롤백 방법"
echo "=========================================="
echo ""
echo "테마 롤백:"
echo "  브라우저 콘솔: changeTheme('autumn')"
echo ""
echo "이벤트 배너 숨김:"
echo "  localStorage.setItem('eventBannerClosed', 'true')"
echo "  페이지 새로고침"
echo ""

