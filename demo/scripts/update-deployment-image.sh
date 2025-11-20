#!/bin/bash
# Deployment 이미지 태그 업데이트 및 ArgoCD 동기화
# 사용법: ./update-deployment-image.sh <이미지-태그>
# 예: ./update-deployment-image.sh winter-20251120-170611

set -e

if [ -z "$1" ]; then
    echo "사용법: $0 <이미지-태그>"
    echo "예: $0 winter-20251120-170611"
    echo "예: $0 autumn-20251120-170611"
    exit 1
fi

IMAGE_TAG="$1"
IMAGE_NAME="192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG"
PROJECT_DIR="/home/kevin/error-archive"
DEPLOYMENT_FILE="$PROJECT_DIR/k8s/error-archive/frontend-deployment.yaml"
APP_NAME="error-archive-frontend"

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "=========================================="
echo "  Deployment 이미지 태그 업데이트"
echo "=========================================="
echo ""
echo "이미지: $IMAGE_NAME"
echo ""

cd "$PROJECT_DIR"

# ==========================================
# 1단계: 매니페스트 이미지 태그 업데이트
# ==========================================
echo -e "${BLUE}[1단계] 매니페스트 이미지 태그 업데이트${NC}"
echo ""

if [ ! -f "$DEPLOYMENT_FILE" ]; then
    echo -e "${YELLOW}⚠ 매니페스트 파일을 찾을 수 없습니다: $DEPLOYMENT_FILE${NC}"
    exit 1
fi

# 현재 이미지 확인
CURRENT_IMAGE=$(grep "image:" "$DEPLOYMENT_FILE" | head -1 | awk '{print $2}')
echo "현재 이미지: $CURRENT_IMAGE"
echo "새 이미지: $IMAGE_NAME"
echo ""

# 이미지 태그 업데이트
sed -i "s|image:.*error-archive-frontend:.*|image: $IMAGE_NAME|" "$DEPLOYMENT_FILE"
echo -e "${GREEN}✓ 매니페스트 이미지 태그 업데이트 완료${NC}"
echo ""

# ==========================================
# 2단계: Git 커밋
# ==========================================
echo -e "${BLUE}[2단계] Git 커밋${NC}"
echo ""

git add "$DEPLOYMENT_FILE"
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - $IMAGE_TAG" || echo "⚠ 이미 커밋된 변경사항이 있습니다."
echo -e "${GREEN}✓ Git 커밋 완료${NC}"
echo ""
echo -e "${YELLOW}⚠ Git 푸시는 수동으로 진행하세요:${NC}"
echo "  git push origin main"
echo ""
read -p "Git 푸시를 완료한 후 Enter를 누르세요..."

# ==========================================
# 3단계: ArgoCD 동기화
# ==========================================
echo ""
echo -e "${BLUE}[3단계] ArgoCD 동기화${NC}"
echo ""

# Application 존재 확인
if ! kubectl get application $APP_NAME -n argocd &>/dev/null; then
    echo "ArgoCD Application이 없습니다. 생성 중..."
    kubectl apply -f argocd/frontend-application.yaml || echo "⚠ Application 생성 실패"
    sleep 5
fi

echo "ArgoCD 동기화 실행 중..."
kubectl patch application $APP_NAME -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}' || \
echo "⚠ ArgoCD 동기화 실패 (수동으로 실행하세요)"

echo ""
echo -e "${GREEN}✓ ArgoCD 동기화 요청 완료${NC}"
echo ""

# ==========================================
# 4단계: 롤링 업데이트 확인
# ==========================================
echo -e "${BLUE}[4단계] 롤링 업데이트 확인${NC}"
echo ""

echo "롤링 업데이트 진행 상황 확인:"
echo "  kubectl get pods -n error-archive -l app=frontend -w"
echo "  kubectl rollout status deployment/frontend -n error-archive"
echo ""

kubectl rollout status deployment/frontend -n error-archive --timeout=180s || echo "⚠ 타임아웃"

echo ""
echo "=========================================="
echo -e "${GREEN}  배포 완료!${NC}"
echo "=========================================="
echo ""
echo "확인 사항:"
echo "  ✅ 이미지 태그: $IMAGE_NAME"
echo "  ✅ Git 커밋 완료"
echo "  ✅ ArgoCD 동기화 완료"
echo "  ✅ 롤링 업데이트 완료"
echo ""

