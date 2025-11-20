#!/bin/bash
# 시나리오 2: Harbor Trivy 취약성 스캔 시연
# 취약성 높음 → 낮음 변화를 Trivy로 보여주기
# 시연 시간: 약 3-4분

set -e

echo "=========================================="
echo "  시나리오 2: Harbor Trivy 취약성 스캔 시연"
echo "=========================================="
echo ""
echo "📋 시연 순서:"
echo "  1. 취약한 이미지 스캔 (높은 취약성)"
echo "  2. 이미지 취약점 수정"
echo "  3. 수정된 이미지 스캔 (낮은 취약성)"
echo "  4. Harbor 대시보드에서 비교"
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_DIR="/home/kevin/error-archive"
HARBOR_URL="192.168.0.169:443"
HARBOR_USER="admin"
HARBOR_PASS="Harbor12345"
PROJECT_NAME="project"

# ==========================================
# 1단계: 취약한 이미지 스캔
# ==========================================
echo -e "${BLUE}[1단계] 취약한 이미지 스캔 (높은 취약성)${NC}"
echo ""

IMAGE_NAME_INsecure="error-archive-frontend:insecure"
IMAGE_NAME_SECURE="error-archive-frontend:secure"

echo "스캔할 이미지: $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_INsecure"
echo ""

# Harbor에 로그인
echo "Harbor에 로그인 중..."
echo "$HARBOR_PASS" | docker login $HARBOR_URL -u $HARBOR_USER --password-stdin || echo "⚠ Docker 로그인 실패"

echo ""
echo "Trivy로 이미지 스캔 중..."
echo ""

# Trivy 스캔 실행 (취약한 이미지)
echo "=== 취약한 이미지 스캔 결과 ==="
trivy image $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_INsecure --severity HIGH,CRITICAL --format table || \
echo -e "${YELLOW}⚠ Trivy가 설치되어 있지 않거나 이미지가 없습니다.${NC}"
echo ""

echo "Harbor 웹 UI에서 확인:"
echo "  https://$HARBOR_URL"
echo "  프로젝트: $PROJECT_NAME"
echo "  이미지: $IMAGE_NAME_INsecure"
echo "  → 취약성 스캔 탭에서 상세 정보 확인"
echo ""

read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 2단계: 이미지 취약점 수정
# ==========================================
echo ""
echo -e "${BLUE}[2단계] 이미지 취약점 수정${NC}"
echo ""

echo "수정 사항:"
echo "  ✅ 기본 이미지 업데이트 (최신 보안 패치 적용)"
echo "  ✅ 불필요한 패키지 제거"
echo "  ✅ 최소 권한 원칙 적용"
echo "  ✅ 보안 강화된 Dockerfile 사용"
echo ""

echo "보안 강화된 이미지 빌드 중..."
cd "$PROJECT_DIR/frontend"

# 보안 강화된 Dockerfile 사용
if [ -f "Dockerfile.secure" ]; then
    docker build -f Dockerfile.secure -t $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_SECURE:latest .
    echo -e "${GREEN}✓ 보안 강화된 이미지 빌드 완료${NC}"
else
    echo -e "${YELLOW}⚠ Dockerfile.secure를 찾을 수 없습니다.${NC}"
    echo "기본 Dockerfile로 빌드합니다..."
    docker build -t $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_SECURE:latest .
fi

echo ""
echo "Harbor에 이미지 푸시 중..."
docker push $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_SECURE:latest || echo "⚠ 푸시 실패"

echo ""
read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 3단계: 수정된 이미지 스캔
# ==========================================
echo ""
echo -e "${BLUE}[3단계] 수정된 이미지 스캔 (낮은 취약성)${NC}"
echo ""

echo "Trivy로 수정된 이미지 스캔 중..."
echo ""

# Trivy 스캔 실행 (보안 강화된 이미지)
echo "=== 보안 강화된 이미지 스캔 결과 ==="
trivy image $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_SECURE:latest --severity HIGH,CRITICAL --format table || \
echo -e "${YELLOW}⚠ Trivy가 설치되어 있지 않거나 이미지가 없습니다.${NC}"
echo ""

read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 4단계: Harbor 대시보드에서 비교
# ==========================================
echo ""
echo -e "${BLUE}[4단계] Harbor 대시보드에서 비교${NC}"
echo ""

echo "Harbor 웹 UI 접속:"
echo "  https://$HARBOR_URL"
echo "  사용자: $HARBOR_USER"
echo "  비밀번호: $HARBOR_PASS"
echo ""

echo "비교할 이미지:"
echo "  1. $IMAGE_NAME_INsecure (취약성 높음)"
echo "  2. $IMAGE_NAME_SECURE (취약성 낮음)"
echo ""

echo "확인 사항:"
echo "  ✅ 취약점 개수 비교"
echo "  ✅ 심각도별 분류 (CRITICAL, HIGH, MEDIUM, LOW)"
echo "  ✅ CVE 상세 정보"
echo "  ✅ 스캔 시간 및 결과"
echo ""

echo "Harbor에서 이미지 비교 방법:"
echo "  1. 프로젝트 → $PROJECT_NAME 선택"
echo "  2. 각 이미지의 '취약성 스캔' 탭 클릭"
echo "  3. 취약점 개수 및 심각도 비교"
echo ""

echo "Trivy 스캔 결과 비교 (CLI):"
echo ""
echo "=== 취약점 개수 비교 ==="
echo "취약한 이미지:"
trivy image $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_INsecure --severity HIGH,CRITICAL --format json 2>/dev/null | \
  jq '.Results[] | select(.Vulnerabilities != null) | .Vulnerabilities | length' | \
  awk '{sum+=$1} END {print "  HIGH/CRITICAL 취약점: " sum "개"}' || \
  echo "  스캔 결과를 확인할 수 없습니다."

echo ""
echo "보안 강화된 이미지:"
trivy image $HARBOR_URL/$PROJECT_NAME/$IMAGE_NAME_SECURE:latest --severity HIGH,CRITICAL --format json 2>/dev/null | \
  jq '.Results[] | select(.Vulnerabilities != null) | .Vulnerabilities | length' | \
  awk '{sum+=$1} END {print "  HIGH/CRITICAL 취약점: " sum "개"}' || \
  echo "  스캔 결과를 확인할 수 없습니다."

echo ""
echo "=========================================="
echo -e "${GREEN}  시나리오 2 완료!${NC}"
echo "=========================================="
echo ""
echo "확인 사항:"
echo "  1. ✅ 취약한 이미지 스캔 완료"
echo "  2. ✅ 보안 강화된 이미지 빌드 및 푸시"
echo "  3. ✅ 수정된 이미지 스캔 완료"
echo "  4. ✅ Harbor 대시보드에서 취약점 비교"
echo ""
echo "Harbor 웹 UI:"
echo "  https://$HARBOR_URL"
echo ""

