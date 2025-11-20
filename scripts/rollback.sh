#!/bin/bash
# 롤백 스크립트

VERSION=${1:-"1.3"}

cd /home/kevin/proj/error-archive-1

echo "=========================================="
echo "  롤백: 버전 $VERSION으로 복구"
echo "=========================================="
echo ""

# 매니페스트 롤백
echo "매니페스트 롤백 중..."
sed -i "s|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:$VERSION|g" k8s/error-archive/frontend-deployment.yaml
echo "✓ 매니페스트 업데이트 완료"
echo ""

# Git 커밋 및 푸시
echo "Git 커밋 및 푸시 중..."
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Rollback frontend to version $VERSION" || echo "변경사항 없음"
git push origin main
echo "✓ Git 푸시 완료"
echo ""

echo "=========================================="
echo "  롤백 완료!"
echo "=========================================="
echo ""
echo "ArgoCD가 자동으로 롤백을 시작합니다."
echo ""
echo "롤백 상태 확인:"
echo "  kubectl get deployments -n error-archive"
echo "  kubectl rollout status deployment/frontend -n error-archive"

