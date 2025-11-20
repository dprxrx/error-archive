#!/bin/bash
# 보안 정책 적용 스크립트

echo "=========================================="
echo "  보안 정책 적용"
echo "=========================================="
echo ""

# 1. ServiceAccount 생성
echo "1. ServiceAccount 생성 중..."
kubectl apply -f security/serviceaccounts/
echo "✓ ServiceAccount 생성 완료"
echo ""

# 2. RBAC 설정
echo "2. RBAC (Role/RoleBinding) 설정 중..."
kubectl apply -f security/rbac/
echo "✓ RBAC 설정 완료"
echo ""

# 3. NetworkPolicy 적용
echo "3. NetworkPolicy 적용 중..."
kubectl apply -f security/network-policies/
echo "✓ NetworkPolicy 적용 완료"
echo ""

# 4. 보안 강화된 Deployment 적용
echo "4. 보안 강화된 Deployment 적용 중..."
read -p "기존 Deployment를 보안 강화 버전으로 교체하시겠습니까? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    kubectl apply -f k8s/error-archive/frontend-deployment-secure.yaml
    kubectl apply -f k8s/error-archive/backend-deployment-secure.yaml
    echo "✓ 보안 강화된 Deployment 적용 완료"
else
    echo "⚠ Deployment 적용 건너뜀"
fi
echo ""

echo "=========================================="
echo "  보안 정책 적용 완료!"
echo "=========================================="
echo ""
echo "적용된 보안 정책:"
echo "  ✓ ServiceAccount (루트 사용 금지)"
echo "  ✓ RBAC (최소 권한 원칙)"
echo "  ✓ NetworkPolicy (네트워크 격리)"
echo "  ✓ SecurityContext (non-root, readOnlyRootFilesystem)"
echo ""
echo "확인 명령어:"
echo "  kubectl get serviceaccounts -n error-archive"
echo "  kubectl get roles,rolebindings -n error-archive"
echo "  kubectl get networkpolicies -n error-archive"
echo "  kubectl get pods -n error-archive -o jsonpath='{.items[*].spec.securityContext}'"

