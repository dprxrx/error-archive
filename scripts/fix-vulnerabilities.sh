#!/bin/bash
# 취약점 해결 스크립트

echo "=== 취약점 해결 스크립트 ==="
echo ""

# 1. npm 의존성 취약점 확인 및 수정
if [ -f "backend/package.json" ]; then
    echo "1. Backend npm 취약점 확인 중..."
    cd backend
    npm audit 2>/dev/null || echo "npm audit를 실행할 수 없습니다."
    echo ""
    echo "자동 수정하려면: npm audit fix"
    cd ..
fi

# 2. Dockerfile 보안 강화 적용
echo "2. 보안 강화 Dockerfile 적용..."
if [ -f "backend/Dockerfile.secure" ] && [ -f "frontend/Dockerfile.secure" ]; then
    read -p "보안 강화 Dockerfile을 적용하시겠습니까? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        ./scripts/apply-secure-dockerfiles.sh
    fi
else
    echo "보안 강화 Dockerfile이 없습니다."
fi

# 3. Harbor 스캔 결과 확인 안내
echo ""
echo "3. Harbor에서 스캔 재실행:"
echo "   - Harbor UI 접속: http://192.168.0.169:443"
echo "   - 프로젝트 → 이미지 선택 → 스캔 실행"
echo ""
echo "4. 로컬에서 Trivy 스캔 (선택사항):"
echo "   docker run --rm aquasec/trivy:latest image 192.168.0.169:443/project/error-archive-backend:latest"

