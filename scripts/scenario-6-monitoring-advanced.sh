#!/bin/bash
# 시나리오 6: 모니터링 심화 - 메트릭 수집 및 분석

echo "=========================================="
echo "  시나리오 6: 모니터링 심화"
echo "=========================================="
echo ""

# 1단계: ServiceMonitor 생성
echo "1단계: ServiceMonitor 생성 (Prometheus 메트릭 수집)..."
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: ServiceMonitor
metadata:
  name: error-archive-backend
  namespace: error-archive
  labels:
    app: backend
spec:
  selector:
    matchLabels:
      app: backend
  endpoints:
  - port: http
    path: /metrics
    interval: 30s
EOF
echo "✓ ServiceMonitor 생성 완료"
echo ""

# 2단계: PrometheusRule 생성
echo "2단계: 알림 규칙 생성..."
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: error-archive-alerts
  namespace: error-archive
spec:
  groups:
  - name: error-archive
    rules:
    - alert: HighCPUUsage
      expr: rate(container_cpu_usage_seconds_total{namespace="error-archive"}[5m]) > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected in error-archive namespace"
        description: "Pod {{ \$labels.pod }} has high CPU usage"
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes{namespace="error-archive"} / container_spec_memory_limit_bytes > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected in error-archive namespace"
        description: "Pod {{ \$labels.pod }} has high memory usage"
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total{namespace="error-archive"}[15m]) > 0
      for: 5m
      labels:
        severity: critical
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ \$labels.pod }} is restarting frequently"
EOF
echo "✓ 알림 규칙 생성 완료"
echo ""

# 3단계: Alertmanager 연결
echo "3단계: Alertmanager 연결..."
pkill -f "port-forward.*alertmanager" 2>/dev/null
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093 > /tmp/alertmanager-pf.log 2>&1 &
echo "✓ Alertmanager Port Forward 시작 (PID: $!)"
echo "  접속: http://localhost:9093"
echo ""

# 4단계: 메트릭 확인
echo "4단계: 메트릭 확인..."
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

echo "=== 현재 Pod 메트릭 ==="
kubectl top pods -n error-archive 2>/dev/null || echo "메트릭 수집 중... 잠시 후 다시 시도하세요"
echo ""

# 5단계: 알림 확인
echo "5단계: 알림 확인..."
echo ""
echo "알림 규칙 확인:"
kubectl get prometheusrules -n error-archive
echo ""
echo "Alertmanager 알림 확인:"
echo "  http://localhost:9093/#/alerts"
echo ""

echo "=========================================="
echo "  모니터링 심화 설정 완료!"
echo "=========================================="
echo ""
echo "접속 정보:"
echo "  Prometheus: http://localhost:9090"
echo "  Grafana: http://localhost:3000"
echo "  Alertmanager: http://localhost:9093"

