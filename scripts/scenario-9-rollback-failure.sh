#!/bin/bash
# 시나리오 9: 배포 실패 및 자동 롤백 (실무 시나리오)

echo "=========================================="
echo "  시나리오 9: 배포 실패 및 자동 롤백"
echo "=========================================="
echo ""
echo "시나리오: 새 버전 배포 후 헬스체크 실패로 자동 롤백"
echo ""

# 1단계: 현재 버전 확인
echo "1단계: 현재 배포 상태 확인..."
CURRENT_IMAGE=$(kubectl get deployment backend-deployment -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}')
echo "현재 이미지: $CURRENT_IMAGE"
echo ""

# 2단계: 잘못된 이미지로 배포 (의도적 실패)
echo "2단계: 잘못된 이미지로 배포 시도..."
NEW_VERSION="1.99"  # 존재하지 않는 버전
echo "새 이미지: 192.168.0.169:443/project/error-archive-backend:$NEW_VERSION"

# Deployment 업데이트
kubectl set image deployment/backend-deployment backend=192.168.0.169:443/project/error-archive-backend:$NEW_VERSION -n error-archive

echo "✓ 배포 시작..."
echo ""

# 3단계: 배포 상태 모니터링
echo "3단계: 배포 상태 모니터링..."
echo ""
for i in {1..10}; do
    echo "--- 확인 $i/10 ---"
    kubectl get deployment backend-deployment -n error-archive
    kubectl get pods -n error-archive -l app=backend
    echo ""
    
    # Pod 이벤트 확인
    kubectl get events -n error-archive --sort-by='.lastTimestamp' | tail -3
    echo ""
    
    sleep 5
done

# 4단계: 롤백
echo "4단계: 수동 롤백 또는 ArgoCD 자동 롤백..."
echo ""
echo "옵션 1: kubectl 롤백"
echo "  kubectl rollout undo deployment/backend-deployment -n error-archive"
echo ""
echo "옵션 2: ArgoCD 롤백 (Git에서 이전 버전으로 복구)"
echo "  sed -i 's|192.168.0.169:443/project/error-archive-backend:.*|$CURRENT_IMAGE|g' k8s/error-archive/backend-deployment.yaml"
echo "  git add k8s/error-archive/backend-deployment.yaml"
echo "  git commit -m 'Rollback to previous version'"
echo "  git push origin main"
echo ""

read -p "롤백을 실행하시겠습니까? (y/n): " ROLLBACK
if [ "$ROLLBACK" = "y" ]; then
    echo "롤백 실행 중..."
    kubectl rollout undo deployment/backend-deployment -n error-archive
    echo "✓ 롤백 완료"
    echo ""
    echo "롤백 상태 확인 중..."
    sleep 10
    kubectl get deployment backend-deployment -n error-archive
    kubectl get pods -n error-archive -l app=backend
fi

echo ""
echo "=========================================="
echo "  배포 실패 및 롤백 시연 완료!"
echo "=========================================="

