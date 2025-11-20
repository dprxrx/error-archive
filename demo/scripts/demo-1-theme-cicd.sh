#!/bin/bash
# 시나리오 1: 가을테마 → 겨울테마 CICD 시연
# 시연 시간: 약 5-7분

set -e

echo "=========================================="
echo "  시나리오 1: 가을테마 → 겨울테마 CICD 시연"
echo "=========================================="
echo ""
echo "📋 시연 순서:"
echo "  1. 소스코드 변경 (가을 → 겨울 테마)"
echo "  2. Git 커밋 및 푸시"
echo "  3. Tekton CI 파이프라인 실행"
echo "  4. ArgoCD CD 자동 배포 (롤링 업데이트)"
echo "  5. Grafana 대시보드 모니터링"
echo "  6. 과부하 시뮬레이션 및 알림"
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="/home/kevin/error-archive"
DEMO_DIR="$PROJECT_DIR/demo"
AUTUMN_THEME="$DEMO_DIR/themes/autumn"
WINTER_THEME="$DEMO_DIR/themes/winter"

cd "$PROJECT_DIR"

# ==========================================
# 1단계: 소스코드 변경 (가을 → 겨울)
# ==========================================
echo -e "${BLUE}[1단계] 소스코드 변경: 가을 테마 → 겨울 테마${NC}"
echo ""

echo "변경 사항:"
echo "  ✅ list.html: 겨울 이벤트 배너 추가"
echo "  ✅ list.html: 룰렛 링크 활성화"
echo "  ✅ roulette.html: 겨울 이벤트 페이지 추가"
echo ""

# 가을 테마에서 겨울 테마로 변경
echo "소스코드 변경 중..."
cp "$WINTER_THEME/list.html" "$PROJECT_DIR/frontend/list.html"
cp "$WINTER_THEME/roulette.html" "$PROJECT_DIR/frontend/roulette.html"

echo -e "${GREEN}✓ 소스코드 변경 완료${NC}"
echo ""
echo "변경된 파일:"
git diff --name-only frontend/ || echo "  - frontend/list.html"
echo "  - frontend/roulette.html"
echo ""

read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 2단계: Git 커밋 및 푸시
# ==========================================
echo ""
echo -e "${BLUE}[2단계] Git 커밋 및 푸시${NC}"
echo ""

# Git 설정 확인 및 설정
if [ -z "$(git config --global user.email)" ]; then
    echo "Git 사용자 정보 설정 중..."
    git config --global user.email "dprxrx@gmail.com"
    git config --global user.name "dprxrx"
    echo -e "${GREEN}✓ Git 설정 완료${NC}"
fi

VERSION="winter-$(date +%Y%m%d-%H%M%S)"
echo "버전: $VERSION"
echo ""

echo "Git 커밋 중..."
git add frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가 (시연용)

- 겨울 이벤트 배너 추가
- 룰렛 페이지 활성화
- 테마 전환 기능 추가
- 버전: $VERSION" || echo "⚠ 이미 커밋된 변경사항이 있습니다."

echo ""
echo -e "${YELLOW}⚠ Git 푸시는 수동으로 진행하세요:${NC}"
echo "  git push origin main"
echo ""
read -p "Git 푸시를 완료한 후 Enter를 누르세요..."

echo ""
read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 3단계: Tekton CI 파이프라인 실행
# ==========================================
echo ""
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
echo "빌드 진행 상황 확인:"
echo "  kubectl get pipelineruns -n default | grep frontend-winter-theme"
echo "  kubectl logs -f pipelinerun/$PIPELINE_RUN_NAME -n default"
echo ""

echo -e "${YELLOW}⏳ CI 파이프라인 실행 중... (약 2-3분 소요)${NC}"
echo "Tekton 대시보드에서 진행 상황을 확인하세요:"
echo "  kubectl port-forward svc/tekton-dashboard -n tekton-pipelines 9097:9097"
echo "  http://localhost:9097"
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
        kubectl describe pipelinerun $PIPELINE_RUN_NAME -n default | tail -20
        break
    fi
    sleep 5
    echo -n "."
done

echo ""
read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 4단계: ArgoCD CD 자동 배포
# ==========================================
echo ""
echo -e "${BLUE}[4단계] ArgoCD CD 자동 배포 (롤링 업데이트)${NC}"
echo ""

# 빌드된 이미지 태그 추출
BUILT_IMAGE="$IMAGE_NAME"
echo "빌드된 이미지: $BUILT_IMAGE"
echo ""

# Kubernetes 매니페스트 이미지 태그 업데이트
echo "Kubernetes 매니페스트 이미지 태그 업데이트 중..."
DEPLOYMENT_FILE="$PROJECT_DIR/k8s/error-archive/frontend-deployment.yaml"

if [ -f "$DEPLOYMENT_FILE" ]; then
    # 현재 이미지 태그 확인
    CURRENT_IMAGE=$(grep "image:" "$DEPLOYMENT_FILE" | head -1 | awk '{print $2}')
    echo "현재 이미지: $CURRENT_IMAGE"
    echo "새 이미지: $BUILT_IMAGE"
    
    # 이미지 태그 업데이트
    sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" "$DEPLOYMENT_FILE"
    echo -e "${GREEN}✓ 매니페스트 이미지 태그 업데이트 완료${NC}"
    
    # Git에 커밋 (푸시는 수동)
    echo ""
    echo "매니페스트 변경사항을 Git에 커밋합니다 (푸시는 수동으로 진행하세요)..."
    git add "$DEPLOYMENT_FILE"
    git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - $BUILT_IMAGE" || echo "⚠ 이미 커밋된 변경사항이 있습니다."
    echo -e "${GREEN}✓ Git 커밋 완료${NC}"
    echo ""
    echo -e "${YELLOW}⚠ 다음 명령어로 수동으로 Git 푸시를 진행하세요:${NC}"
    echo "  git push origin main"
    echo ""
    read -p "Git 푸시를 완료한 후 Enter를 누르세요..."
else
    echo -e "${YELLOW}⚠ 매니페스트 파일을 찾을 수 없습니다: $DEPLOYMENT_FILE${NC}"
fi

echo ""
echo "ArgoCD Application 확인 중..."
APP_NAME="error-archive-frontend"

# Application 존재 확인
if ! kubectl get application $APP_NAME -n argocd &>/dev/null; then
    echo "ArgoCD Application이 없습니다. 생성 중..."
    kubectl apply -f argocd/frontend-application.yaml || echo "⚠ Application 생성 실패"
    sleep 5
fi

echo "ArgoCD Application 업데이트 중..."
kubectl patch application $APP_NAME -n argocd --type merge -p "{\"spec\":{\"source\":{\"targetRevision\":\"main\"},\"syncPolicy\":{\"syncOptions\":[\"CreateNamespace=true\"]}}}"

echo ""
echo "ArgoCD 동기화 실행..."
kubectl patch application $APP_NAME -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}' || \
argocd app sync $APP_NAME --core || echo "⚠ ArgoCD CLI를 사용하거나 웹 UI에서 동기화하세요"

echo ""
echo -e "${GREEN}✓ ArgoCD 배포 시작${NC}"
echo ""
echo "ArgoCD 대시보드에서 배포 진행 상황 확인:"
echo "  kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "  https://localhost:8080"
echo "  사용자: admin / 비밀번호: 확인 필요"
echo ""

echo "롤링 업데이트 진행 상황 확인:"
echo "  kubectl get pods -n error-archive -l app=frontend -w"
echo "  kubectl rollout status deployment/frontend -n error-archive"
echo ""
echo "ArgoCD Application 상태 확인:"
echo "  kubectl get application $APP_NAME -n argocd"
echo "  kubectl describe application $APP_NAME -n argocd"
echo ""

# 롤링 업데이트 대기
echo "롤링 업데이트 완료를 기다리는 중..."
kubectl rollout status deployment/frontend -n error-archive --timeout=300s || echo "⚠ 타임아웃"

echo ""
read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 5단계: Grafana 대시보드 모니터링
# ==========================================
echo ""
echo -e "${BLUE}[5단계] Grafana 대시보드 모니터링${NC}"
echo ""

echo "Grafana 대시보드 접속:"
echo "  kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80"
echo "  http://localhost:3000"
echo "  기본 사용자: admin / admin"
echo ""

echo "확인할 메트릭:"
echo "  - Pod CPU/메모리 사용량"
echo "  - 요청 수 (Request Rate)"
echo "  - 응답 시간 (Response Time)"
echo "  - 에러율 (Error Rate)"
echo ""

read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 6단계: 과부하 시뮬레이션 및 알림
# ==========================================
echo ""
echo -e "${BLUE}[6단계: 과부하 시뮬레이션 및 알림${NC}"
echo ""

echo "겨울 이벤트로 인한 트래픽 증가 시뮬레이션..."
echo ""

# 부하 생성 스크립트 실행
if [ -f "$PROJECT_DIR/scripts/generate-load.sh" ]; then
    echo "부하 생성 스크립트 실행 중..."
    bash "$PROJECT_DIR/scripts/generate-load.sh" frontend 50 60
    echo -e "${GREEN}✓ 부하 생성 완료${NC}"
else
    echo "부하 생성 스크립트를 찾을 수 없습니다."
    echo "수동으로 부하를 생성하세요:"
    echo "  kubectl run load-generator --image=busybox --rm -it --restart=Never -- /bin/sh -c 'while true; do wget -q -O- http://frontend.error-archive.svc.cluster.local; done'"
fi

echo ""
echo "Grafana에서 다음을 확인하세요:"
echo "  - CPU 사용량 증가"
echo "  - 메모리 사용량 증가"
echo "  - 요청 수 증가"
echo ""

echo "Prometheus Alertmanager에서 알림 확인:"
echo "  kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093"
echo "  http://localhost:9093"
echo ""

echo -e "${YELLOW}⏳ 30초간 부하 유지 중...${NC}"
sleep 30

echo ""
echo "부하 중지 중..."
if [ -f "$PROJECT_DIR/scripts/stop-load.sh" ]; then
    bash "$PROJECT_DIR/scripts/stop-load.sh"
else
    kubectl delete pod load-generator --ignore-not-found=true
fi

echo ""
echo "=========================================="
echo -e "${GREEN}  시나리오 1 완료!${NC}"
echo "=========================================="
echo ""
echo "확인 사항:"
echo "  1. ✅ 소스코드 변경 (가을 → 겨울 테마)"
echo "  2. ✅ CI 파이프라인 실행 (Tekton)"
echo "  3. ✅ CD 자동 배포 (ArgoCD)"
echo "  4. ✅ 롤링 업데이트 완료"
echo "  5. ✅ 모니터링 대시보드 (Grafana)"
echo "  6. ✅ 과부하 시뮬레이션 및 알림"
echo ""
echo "웹 브라우저에서 확인:"
echo "  http://<노드IP>:<NodePort>"
echo "  - 겨울 이벤트 배너 표시 확인"
echo "  - 룰렛 페이지 접근 가능 확인"
echo ""

