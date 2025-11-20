#!/bin/bash
# Kubernetes Metrics Server 설치 스크립트

echo "=========================================="
echo "  Kubernetes Metrics Server 설치"
echo "=========================================="
echo ""

# 메트릭 서버 설치 확인
if kubectl get deployment metrics-server -n kube-system &>/dev/null; then
    echo "✓ 메트릭 서버가 이미 설치되어 있습니다."
    exit 0
fi

echo "1. Metrics Server 설치 중..."
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

echo ""
echo "2. TLS 인증서 문제 해결 (--kubelet-insecure-tls 옵션 추가)..."
sleep 3
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' 2>/dev/null || echo "이미 설정되어 있거나 설정 중..."

echo ""
echo "3. 설치 확인 중..."
sleep 10

# 메트릭 서버 Pod 상태 확인
kubectl get pods -n kube-system -l k8s-app=metrics-server

echo ""
echo "4. 메트릭 서버 설정 확인..."
kubectl get deployment metrics-server -n kube-system -o jsonpath='{.spec.template.spec.containers[0].args}' | grep -q "kubelet-insecure-tls" && echo "✓ --kubelet-insecure-tls 옵션 적용됨" || echo "설정 확인 필요"

echo ""
echo "=========================================="
echo "  설치 완료!"
echo "=========================================="
echo ""
echo "메트릭 서버 상태 확인:"
echo "  kubectl get pods -n kube-system -l k8s-app=metrics-server"
echo ""
echo "Pod 리소스 사용률 확인:"
echo "  kubectl top pods -n error-archive"
echo ""
echo "Node 리소스 사용률 확인:"
echo "  kubectl top nodes"

