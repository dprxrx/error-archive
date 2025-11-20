#!/bin/bash
# 시나리오 10: 모니터링 알림 시연 (부하 생성 포함)

echo "=========================================="
echo "  시나리오 10: 모니터링 알림 시연"
echo "=========================================="
echo ""

# 1단계: 알림 규칙 확인/생성
echo "1단계: 알림 규칙 설정..."
kubectl apply -f - <<EOF
apiVersion: monitoring.coreos.com/v1
kind: PrometheusRule
metadata:
  name: error-archive-alerts-demo
  namespace: error-archive
spec:
  groups:
  - name: error-archive-demo
    interval: 30s
    rules:
    - alert: HighCPUUsage
      expr: rate(container_cpu_usage_seconds_total{namespace="error-archive",container!="POD",container!=""}[1m]) > 0.05
      for: 30s
      labels:
        severity: warning
      annotations:
        summary: "High CPU usage detected"
        description: "Pod {{ \$labels.pod }} has CPU usage above 5% ({{ \$value | humanize }} cores)"
    - alert: HighMemoryUsage
      expr: |
        (
          container_memory_usage_bytes{namespace="error-archive",container!="POD",container!=""} 
          / 
          (container_spec_memory_limit_bytes{namespace="error-archive",container!="POD",container!=""} > bool 0) 
          * container_spec_memory_limit_bytes{namespace="error-archive",container!="POD",container!=""}
          + (container_spec_memory_limit_bytes{namespace="error-archive",container!="POD",container!=""} == bool 0) 
          * 1073741824
        ) > 0.5
        or
        container_memory_usage_bytes{namespace="error-archive",container!="POD",container!=""} > 100000000
      for: 30s
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
        description: "Pod {{ \$labels.pod }} has memory usage above 50% or 100MB"
    - alert: PodCrashLooping
      expr: rate(kube_pod_container_status_restarts_total{namespace="error-archive"}[5m]) > 0
      for: 2m
      labels:
        severity: critical
      annotations:
        summary: "Pod is crash looping"
        description: "Pod {{ \$labels.pod }} is restarting frequently"
EOF

echo "✓ 알림 규칙 생성 완료"
echo ""

# 2단계: Prometheus/Alertmanager 연결
echo "2단계: 모니터링 도구 연결..."
pkill -f "port-forward.*prometheus" 2>/dev/null
pkill -f "port-forward.*alertmanager" 2>/dev/null
pkill -f "port-forward.*grafana" 2>/dev/null

kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 > /tmp/prometheus-pf.log 2>&1 &
sleep 1
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093 > /tmp/alertmanager-pf.log 2>&1 &
sleep 1
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 > /tmp/grafana-pf.log 2>&1 &
sleep 2

echo "✓ Prometheus: http://localhost:9090"
echo "✓ Alertmanager: http://localhost:9093"
echo "✓ Grafana: http://localhost:3000"
echo ""

# 3단계: 현재 상태 확인
echo "3단계: 현재 상태 확인..."
# 정상 작동하는 Pod 선택 (Ready 1/1)
BACKEND_POD=$(kubectl get pods -n error-archive -l app=backend -o jsonpath='{.items[?(@.status.containerStatuses[0].ready==true)].metadata.name}' | awk '{print $1}')
if [ -z "$BACKEND_POD" ]; then
    # Ready Pod가 없으면 첫 번째 Pod 선택
    BACKEND_POD=$(kubectl get pods -n error-archive -l app=backend -o jsonpath='{.items[0].metadata.name}')
fi
echo "대상 Pod: $BACKEND_POD"
echo ""
echo "Pod 상태:"
kubectl get pod $BACKEND_POD -n error-archive
echo ""
echo "리소스 사용률:"
kubectl top pod $BACKEND_POD -n error-archive 2>/dev/null || echo "메트릭 수집 중... (Prometheus에서 확인 가능)"
echo ""

# 4단계: 부하 생성
echo "4단계: 리소스 부하 생성 (알림 트리거)..."
echo ""
echo "CPU 및 메모리 부하 생성 중..."
LOAD_RESULT=$(kubectl exec -n error-archive $BACKEND_POD -- sh -c "
    # CPU 부하 (여러 프로세스로 강화)
    for i in \$(seq 1 4); do
        nohup timeout 300s sh -c 'while true; do :; done' >/dev/null 2>&1 &
    done
    # 메모리 부하 (Node.js 환경)
    if command -v node >/dev/null 2>&1; then
        nohup timeout 300s node -e 'var arr=[]; setInterval(()=>arr.push(new Array(100*1024*1024).fill(0)), 500)' >/dev/null 2>&1 &
    else
        # 기본 메모리 부하
        nohup timeout 300s sh -c 'arr=(); while true; do arr+=(\$(seq 1 50000)); sleep 0.1; done' >/dev/null 2>&1 &
    fi
    # 프로세스 확인
    sleep 2
    ps aux | grep -E 'while true|node.*Array|timeout.*sh' | grep -v grep | wc -l
" 2>&1)

if echo "$LOAD_RESULT" | grep -qE '[1-9]'; then
    echo "✓ 부하 생성 완료 (프로세스 확인됨)"
else
    echo "⚠ 부하 생성 확인 중... 재시도..."
    # 재시도
    kubectl exec -n error-archive $BACKEND_POD -- sh -c "
        for i in \$(seq 1 6); do
            nohup sh -c 'while true; do :; done' >/dev/null 2>&1 &
        done
        sleep 1
    " 2>/dev/null
    echo "✓ 부하 재생성 완료"
fi

echo "부하 적용 대기 중 (10초)..."
sleep 10
echo ""

# 5단계: 모니터링 및 알림 확인
echo "5단계: 리소스 사용률 모니터링 (60초)..."
echo ""
echo "Prometheus 쿼리로 확인:"
echo "  CPU: rate(container_cpu_usage_seconds_total{pod=\"$BACKEND_POD\",namespace=\"error-archive\"}[1m])"
echo "  Memory: container_memory_usage_bytes{pod=\"$BACKEND_POD\",namespace=\"error-archive\"}"
echo ""
for i in {1..12}; do
    echo "--- 확인 $i/12 (5초 간격) ---"
    # kubectl top 시도
    if kubectl top pod $BACKEND_POD -n error-archive 2>/dev/null; then
        echo ""
    else
        # Prometheus API로 확인 (간단한 방법)
        echo "메트릭 서버 수집 중... Prometheus에서 확인: http://localhost:9090"
    fi
    sleep 5
done

echo ""
echo "6단계: 알림 확인..."
echo ""
echo "⚠ 참고: Alertmanager 클러스터 상태가 'disabled'인 것은 단일 인스턴스이기 때문입니다 (정상)"
echo ""
echo "Prometheus 알림 확인:"
echo "  http://localhost:9090/alerts"
echo ""
echo "Alertmanager 알림 확인:"
echo "  http://localhost:9093/#/alerts"
echo ""
echo "Prometheus에서 직접 쿼리로 확인:"
echo "  CPU: rate(container_cpu_usage_seconds_total{pod=\"$BACKEND_POD\",namespace=\"error-archive\",container!=\"POD\"}[1m])"
echo "  Memory: container_memory_usage_bytes{pod=\"$BACKEND_POD\",namespace=\"error-archive\",container!=\"POD\"}"
echo ""

# 알림 규칙 상태 확인
kubectl get prometheusrules -n error-archive error-archive-alerts-demo -o yaml | grep -A 5 "rules:" | head -10

echo ""
echo "=========================================="
echo "  모니터링 알림 시연 완료!"
echo "=========================================="
echo ""
echo "부하 중지:"
echo "  ./scripts/stop-load.sh error-archive $BACKEND_POD"
echo ""
echo "또는:"
echo "  kubectl exec -n error-archive $BACKEND_POD -- pkill -f 'while true\|node.*Array'"

