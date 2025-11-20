#!/bin/bash
# 시연 롤백: 가을 테마로 복구

echo "=========================================="
echo "  시연 롤백: 가을 테마로 복구"
echo "=========================================="
echo ""

echo "브라우저에서 다음 명령어 실행:"
echo ""
echo "1. 테마 롤백:"
echo "   changeTheme('autumn')"
echo ""
echo "2. 이벤트 배너 표시:"
echo "   localStorage.removeItem('eventBannerClosed')"
echo "   location.reload()"
echo ""
echo "또는 Git에서 롤백:"
echo "  git checkout HEAD~1 -- frontend/index.html frontend/list.html"
echo "  git commit -m 'Rollback to autumn theme'"
echo "  git push origin main"

