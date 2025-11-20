#!/bin/bash
# 보안 정책 롤백 스크립트

echo "=========================================="
echo "  보안 정책 롤백"
echo "=========================================="
echo ""

read -p "보안 정책을 제거하고 이전 상태로 롤백하시겠습니까? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "롤백 취소됨"
    exit 0
fi

echo ""
echo "1. NetworkPolicy 제거 중..."
kubectl delete networkpolicies -n error-archive --all
echo "✓ NetworkPolicy 제거 완료"
echo ""

echo "2. RBAC 제거 중..."
kubectl delete rolebindings -n error-archive --all
kubectl delete roles -n error-archive --all
echo "✓ RBAC 제거 완료"
echo ""

echo "3. ServiceAccount 제거 중..."
kubectl delete serviceaccounts frontend-sa backend-sa -n error-archive
echo "✓ ServiceAccount 제거 완료"
echo ""

echo "4. 기존 Deployment로 롤백 중..."
read -p "기존 Deployment 매니페스트로 롤백하시겠습니까? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl apply -f k8s/error-archive/frontend-deployment.yaml
    kubectl apply -f k8s/error-archive/backend-deployment.yaml
    echo "✓ Deployment 롤백 완료"
else
    echo "⚠ Deployment 롤백 건너뜀"
fi
echo ""

echo "=========================================="
echo "  롤백 완료!"
echo "=========================================="
echo ""
echo "이전 상태로 복구되었습니다."

