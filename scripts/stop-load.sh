#!/bin/bash
# 리소스 부하 중지 스크립트

NAMESPACE="${1:-error-archive}"
POD_NAME="${2:-}"

echo "=========================================="
echo "  리소스 부하 중지"
echo "=========================================="
echo ""

if [ -z "$POD_NAME" ]; then
    echo "사용 가능한 Pod 목록:"
    kubectl get pods -n $NAMESPACE
    echo ""
    read -p "Pod 이름을 입력하세요: " POD_NAME
fi

if [ -z "$POD_NAME" ]; then
    echo "❌ Pod 이름이 필요합니다."
    exit 1
fi

echo "부하 프로세스 종료 중..."
kubectl exec -n $NAMESPACE $POD_NAME -- sh -c "pkill -f 'stress\|node.*Array\|sh -c.*while\|timeout.*stress' || true" 2>/dev/null

echo "✓ 부하 프로세스 종료 완료"
echo ""
echo "현재 리소스 사용률:"
kubectl top pod $POD_NAME -n $NAMESPACE 2>/dev/null || echo "메트릭 수집 중..."

