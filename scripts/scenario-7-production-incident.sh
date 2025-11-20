#!/bin/bash
# 시나리오 7: 프로덕션 장애 대응 (실무 시나리오)

echo "=========================================="
echo "  시나리오 7: 프로덕션 장애 대응"
echo "=========================================="
echo ""
echo "시나리오: 백엔드 Pod의 CPU 사용률이 급증하여 서비스 응답 지연 발생"
echo ""

# 1단계: 현재 상태 확인
echo "1단계: 현재 상태 확인..."
echo ""
kubectl get pods -n error-archive -l app=backend
echo ""
kubectl top pods -n error-archive -l app=backend 2>/dev/null || echo "메트릭 수집 중..."
echo ""

# 2단계: 부하 생성 (장애 시뮬레이션)
echo "2단계: 장애 시뮬레이션 - CPU 부하 생성..."
BACKEND_POD=$(kubectl get pods -n error-archive -l app=backend -o jsonpath='{.items[0].metadata.name}')
echo "대상 Pod: $BACKEND_POD"
echo ""

# CPU 부하 생성
kubectl exec -n error-archive $BACKEND_POD -- sh -c "
    if command -v stress-ng >/dev/null 2>&1; then
        nohup timeout 300s stress-ng --cpu 4 --timeout 300s >/dev/null 2>&1 &
    else
        nohup timeout 300s sh -c 'while true; do :; done' >/dev/null 2>&1 &
    fi
    echo 'CPU 부하 생성됨'
" 2>/dev/null || echo "부하 생성 중..."

echo "✓ CPU 부하 생성 완료"
echo ""
echo "3단계: 모니터링 대시보드 확인..."
echo "  Prometheus: http://localhost:9090"
echo "  Grafana: http://localhost:3000"
echo ""

# Prometheus/Grafana Port Forward
pkill -f "port-forward.*prometheus" 2>/dev/null
pkill -f "port-forward.*grafana" 2>/dev/null
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 > /tmp/prometheus-pf.log 2>&1 &
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 > /tmp/grafana-pf.log 2>&1 &

echo "4단계: 알림 확인 (30초 대기)..."
sleep 30

echo ""
echo "현재 리소스 사용률:"
kubectl top pod $BACKEND_POD -n error-archive 2>/dev/null || echo "메트릭 수집 중..."
echo ""

# 5단계: 대응 조치
echo "5단계: 대응 조치..."
echo ""
echo "옵션 1: Pod 재시작"
echo "  kubectl delete pod $BACKEND_POD -n error-archive"
echo ""
echo "옵션 2: 스케일 아웃 (부하 분산)"
echo "  kubectl scale deployment backend-deployment --replicas=4 -n error-archive"
echo ""
echo "옵션 3: 리소스 제한 조정"
echo "  kubectl set resources deployment backend-deployment --limits=cpu=500m,memory=512Mi -n error-archive"
echo ""

read -p "Pod를 재시작하시겠습니까? (y/n): " RESTART
if [ "$RESTART" = "y" ]; then
    echo "Pod 재시작 중..."
    kubectl delete pod $BACKEND_POD -n error-archive
    echo "✓ Pod 재시작 완료"
    echo ""
    echo "새 Pod 상태 확인 중..."
    sleep 10
    NEW_POD=$(kubectl get pods -n error-archive -l app=backend -o jsonpath='{.items[0].metadata.name}')
    kubectl top pod $NEW_POD -n error-archive 2>/dev/null || echo "메트릭 수집 중..."
fi

echo ""
echo "=========================================="
echo "  장애 대응 완료!"
echo "=========================================="
echo ""
echo "부하 중지:"
echo "  ./scripts/stop-load.sh error-archive $BACKEND_POD"

