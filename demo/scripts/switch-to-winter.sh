#!/bin/bash
# 겨울 테마로 전환 스크립트
# 시연용: 겨울 테마 배포

set -e

echo "=========================================="
echo "  겨울 테마로 전환"
echo "=========================================="
echo ""

PROJECT_DIR="/home/kevin/error-archive"
cd "$PROJECT_DIR"

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ==========================================
# 1단계: 소스코드 변경 (겨울 테마)
# ==========================================
echo -e "${BLUE}[1단계] 소스코드 변경: 겨울 테마${NC}"
echo ""

echo "변경 사항:"
echo "  ✅ list.html: 겨울 이벤트 배너 추가"
echo "  ✅ list.html: 룰렛 링크 활성화"
echo "  ✅ roulette.html: 겨울 이벤트 페이지 추가"
echo ""

# 겨울 테마로 변경
cp "$PROJECT_DIR/demo/themes/winter/list.html" "$PROJECT_DIR/frontend/list.html"
cp "$PROJECT_DIR/demo/themes/winter/index.html" "$PROJECT_DIR/frontend/index.html"
cp "$PROJECT_DIR/demo/themes/winter/roulette.html" "$PROJECT_DIR/frontend/roulette.html"
echo -e "${GREEN}✓ 소스코드 변경 완료${NC}"
echo ""

# ==========================================
# 2단계: Git 커밋
# ==========================================
echo -e "${BLUE}[2단계] Git 커밋${NC}"
echo ""

# Git 설정 확인
if [ -z "$(git config --global user.email)" ]; then
    git config --global user.email "dprxrx@gmail.com"
    git config --global user.name "dprxrx"
fi

VERSION="winter-$(date +%Y%m%d-%H%M%S)"
echo "버전: $VERSION"
echo ""

echo "Git 커밋 중..."
git add frontend/list.html frontend/index.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가 (시연용)

- 겨울 이벤트 배너 추가
- 룰렛 페이지 활성화
- 버전: $VERSION" || echo "⚠ 이미 커밋된 변경사항이 있습니다."

echo -e "${GREEN}✓ Git 커밋 완료${NC}"
echo ""
echo -e "${YELLOW}⚠ Git 푸시는 수동으로 진행하세요:${NC}"
echo "  git push origin main"
echo ""

# ==========================================
# 3단계: Tekton CI 파이프라인 실행
# ==========================================
echo -e "${BLUE}[3단계] Tekton CI 파이프라인 실행${NC}"
echo ""

IMAGE_TAG="winter-$(date +%Y%m%d-%H%M%S)"
IMAGE_NAME="192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG"

echo "이미지 태그: $IMAGE_NAME"
echo ""

echo "Tekton PipelineRun 생성 중..."
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-winter-theme-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: $IMAGE_NAME
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF

PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')

echo -e "${GREEN}✓ PipelineRun 생성 완료: $PIPELINE_RUN_NAME${NC}"
echo ""

echo -e "${YELLOW}⏳ CI 파이프라인 실행 중... (약 2-3분 소요)${NC}"
echo "빌드 진행 상황 확인:"
echo "  kubectl get pipelineruns -n default | grep frontend-winter-theme"
echo ""

# 빌드 완료 대기
echo "빌드 완료를 기다리는 중..."
while true; do
    STATUS=$(kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.status.conditions[0].status}' 2>/dev/null || echo "Unknown")
    if [ "$STATUS" == "True" ]; then
        echo -e "${GREEN}✓ CI 파이프라인 완료${NC}"
        break
    elif [ "$STATUS" == "False" ]; then
        echo -e "${YELLOW}⚠ CI 파이프라인 실패${NC}"
        break
    fi
    sleep 5
    echo -n "."
done

echo ""
echo "=========================================="
echo -e "${GREEN}  겨울 테마 전환 준비 완료!${NC}"
echo "=========================================="
echo ""
echo "다음 단계:"
echo "  1. Git 푸시: git push origin main"
echo "  2. 매니페스트 이미지 태그 업데이트: $IMAGE_NAME"
echo "  3. ArgoCD 동기화"
echo ""

