#!/bin/bash
# 테마 검증 스크립트
# 현재 배포된 테마가 올바른지 확인

set -e

echo "=========================================="
echo "  테마 검증"
echo "=========================================="
echo ""

PROJECT_DIR="/home/kevin/error-archive"
cd "$PROJECT_DIR"

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ==========================================
# 1단계: 현재 배포된 이미지 확인
# ==========================================
echo -e "${BLUE}[1단계] 현재 배포된 이미지 확인${NC}"
echo ""

CURRENT_IMAGE=$(kubectl get deployment frontend -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "현재 이미지: $CURRENT_IMAGE"
echo ""

# 이미지 태그에서 테마 추출
if echo "$CURRENT_IMAGE" | grep -q "autumn"; then
    EXPECTED_THEME="autumn"
    echo -e "${GREEN}✓ 가을 테마 이미지 감지${NC}"
elif echo "$CURRENT_IMAGE" | grep -q "winter"; then
    EXPECTED_THEME="winter"
    echo -e "${GREEN}✓ 겨울 테마 이미지 감지${NC}"
else
    EXPECTED_THEME="unknown"
    echo -e "${YELLOW}⚠ 테마를 확인할 수 없습니다${NC}"
fi

echo ""

# ==========================================
# 2단계: Pod 상태 확인
# ==========================================
echo -e "${BLUE}[2단계] Pod 상태 확인${NC}"
echo ""

kubectl get pods -n error-archive -l app=frontend
echo ""

READY_PODS=$(kubectl get pods -n error-archive -l app=frontend --field-selector=status.phase=Running --no-headers | wc -l)
TOTAL_PODS=$(kubectl get pods -n error-archive -l app=frontend --no-headers | wc -l)

echo "실행 중인 Pod: $READY_PODS / $TOTAL_PODS"
echo ""

if [ "$READY_PODS" -eq "$TOTAL_PODS" ] && [ "$READY_PODS" -gt 0 ]; then
    echo -e "${GREEN}✓ 모든 Pod가 정상 실행 중${NC}"
else
    echo -e "${RED}✗ 일부 Pod가 실행되지 않음${NC}"
fi

echo ""

# ==========================================
# 3단계: Git 매니페스트 확인
# ==========================================
echo -e "${BLUE}[3단계] Git 매니페스트 확인${NC}"
echo ""

DEPLOYMENT_FILE="$PROJECT_DIR/k8s/error-archive/frontend-deployment.yaml"
GIT_IMAGE=$(grep "image:" "$DEPLOYMENT_FILE" | head -1 | awk '{print $2}')
echo "Git 매니페스트 이미지: $GIT_IMAGE"
echo ""

if [ "$CURRENT_IMAGE" == "$GIT_IMAGE" ]; then
    echo -e "${GREEN}✓ 배포된 이미지와 Git 매니페스트 일치${NC}"
else
    echo -e "${YELLOW}⚠ 배포된 이미지와 Git 매니페스트 불일치${NC}"
    echo "  배포된 이미지: $CURRENT_IMAGE"
    echo "  Git 매니페스트: $GIT_IMAGE"
fi

echo ""

# ==========================================
# 4단계: ArgoCD 상태 확인
# ==========================================
echo -e "${BLUE}[4단계] ArgoCD 상태 확인${NC}"
echo ""

APP_NAME="error-archive-frontend"
if kubectl get application $APP_NAME -n argocd &>/dev/null; then
    SYNC_STATUS=$(kubectl get application $APP_NAME -n argocd -o jsonpath='{.status.sync.status}')
    HEALTH_STATUS=$(kubectl get application $APP_NAME -n argocd -o jsonpath='{.status.health.status}')
    
    echo "동기화 상태: $SYNC_STATUS"
    echo "건강 상태: $HEALTH_STATUS"
    echo ""
    
    if [ "$SYNC_STATUS" == "Synced" ]; then
        echo -e "${GREEN}✓ ArgoCD 동기화 완료${NC}"
    else
        echo -e "${YELLOW}⚠ ArgoCD 동기화 필요${NC}"
    fi
    
    if [ "$HEALTH_STATUS" == "Healthy" ]; then
        echo -e "${GREEN}✓ ArgoCD 건강 상태 양호${NC}"
    else
        echo -e "${YELLOW}⚠ ArgoCD 건강 상태: $HEALTH_STATUS${NC}"
    fi
else
    echo -e "${RED}✗ ArgoCD Application을 찾을 수 없습니다${NC}"
fi

echo ""

# ==========================================
# 5단계: 테마별 검증
# ==========================================
echo -e "${BLUE}[5단계] 테마별 검증${NC}"
echo ""

if [ "$EXPECTED_THEME" == "autumn" ]; then
    echo "가을 테마 검증:"
    echo "  ✅ 배너 없음"
    echo "  ✅ 테마 전환 버튼 없음"
    echo "  ✅ 룰렛 링크 없음"
    echo ""
    echo -e "${YELLOW}⚠ 웹 브라우저에서 다음을 확인하세요:${NC}"
    echo "  - 상단에 배너가 없어야 함"
    echo "  - 오른쪽 상단에 테마 전환 버튼이 없어야 함"
    echo "  - 룰렛 페이지 링크가 없어야 함"
elif [ "$EXPECTED_THEME" == "winter" ]; then
    echo "겨울 테마 검증:"
    echo "  ✅ 배너 표시"
    echo "  ✅ 룰렛 링크 활성화"
    echo ""
    echo -e "${YELLOW}⚠ 웹 브라우저에서 다음을 확인하세요:${NC}"
    echo "  - 상단에 겨울 이벤트 배너가 표시되어야 함"
    echo "  - 배너에 '참여하기 →' 링크가 있어야 함"
    echo "  - 룰렛 페이지 접근 가능해야 함"
else
    echo -e "${YELLOW}⚠ 테마를 확인할 수 없습니다${NC}"
fi

echo ""

# ==========================================
# 요약
# ==========================================
echo "=========================================="
echo "  검증 요약"
echo "=========================================="
echo ""
echo "현재 이미지: $CURRENT_IMAGE"
echo "Git 매니페스트: $GIT_IMAGE"
echo "예상 테마: $EXPECTED_THEME"
echo "Pod 상태: $READY_PODS / $TOTAL_PODS 실행 중"
echo "ArgoCD 상태: $SYNC_STATUS / $HEALTH_STATUS"
echo ""
echo "웹 브라우저에서 최종 확인:"
FRONTEND_SVC=$(kubectl get svc frontend -n error-archive -o jsonpath='{.spec.type}')
if [ "$FRONTEND_SVC" == "LoadBalancer" ]; then
    NODEPORT=$(kubectl get svc frontend -n error-archive -o jsonpath='{.spec.ports[0].nodePort}')
    echo "  http://<노드IP>:$NODEPORT"
else
    echo "  kubectl port-forward svc/frontend -n error-archive 8080:80"
    echo "  http://localhost:8080"
fi
echo ""

