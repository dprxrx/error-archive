#!/bin/bash
# 시나리오 5: 모니터링 및 알림

echo "=========================================="
echo "  시나리오 5: 모니터링 및 알림"
echo "=========================================="
echo ""

# 1단계: Prometheus 연결
echo "1단계: Prometheus 연결..."
pkill -f "port-forward.*prometheus" 2>/dev/null
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 > /tmp/prometheus-pf.log 2>&1 &
echo "✓ Prometheus Port Forward 시작 (PID: $!)"
echo "  접속: http://localhost:9090"
echo ""

# 2단계: Grafana 연결
echo "2단계: Grafana 연결..."
pkill -f "port-forward.*grafana" 2>/dev/null
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 > /tmp/grafana-pf.log 2>&1 &
echo "✓ Grafana Port Forward 시작 (PID: $!)"
echo "  접속: http://localhost:3000"
echo "  사용자: admin"
echo "  비밀번호:"
kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d
echo ""
echo ""

# 3단계: 메트릭 쿼리 예시
echo "3단계: Prometheus 쿼리 예시..."
echo ""
echo "=== Prometheus에서 실행할 쿼리 ==="
echo ""
echo "1. Pod CPU 사용률:"
echo "   rate(container_cpu_usage_seconds_total{namespace=\"error-archive\"}[5m])"
echo ""
echo "2. Pod 메모리 사용률:"
echo "   container_memory_usage_bytes{namespace=\"error-archive\"}"
echo ""
echo "3. Pod 재시작 횟수:"
echo "   kube_pod_container_status_restarts_total{namespace=\"error-archive\"}"
echo ""
echo "4. HTTP 요청 수 (있는 경우):"
echo "   sum(rate(http_requests_total{namespace=\"error-archive\"}[5m]))"
echo ""

# 4단계: 실시간 모니터링
echo "4단계: 실시간 모니터링..."
echo ""

# 메트릭 서버 확인 및 설치
if ! kubectl get deployment metrics-server -n kube-system &>/dev/null; then
    echo "메트릭 서버가 없습니다. 설치 중..."
    kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
    sleep 5
    # TLS 인증서 문제 해결
    kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]' 2>/dev/null
    echo "메트릭 서버 설치 완료. 잠시 대기 중..."
    sleep 15
fi

echo "Pod 리소스 사용률:"
kubectl top pods -n error-archive 2>/dev/null || echo "메트릭 수집 중... 잠시 후 다시 시도하세요"
echo ""
echo "Deployment 상태:"
kubectl get deployments -n error-archive -o wide
echo ""

# 5단계: 알림 규칙 확인
echo "5단계: 알림 규칙 확인..."
kubectl get prometheusrules -n monitoring 2>/dev/null | head -5 || echo "알림 규칙이 없습니다"
echo ""

echo "=========================================="
echo "  모니터링 설정 완료!"
echo "=========================================="
echo ""
echo "접속 정보:"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana: http://localhost:3000"
echo ""
echo "종료하려면: pkill -f 'port-forward'"

