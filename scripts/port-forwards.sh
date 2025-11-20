#!/bin/bash
# 여러 서비스 Port Forward를 백그라운드로 실행

echo "=== 서비스 Port Forward 시작 ==="

# 기존 Port Forward 프로세스 종료
pkill -f "kubectl port-forward" 2>/dev/null
sleep 2

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /tmp/argocd-pf.log 2>&1 &
ARGO_PID=$!
echo "✓ ArgoCD: https://localhost:8080 (PID: $ARGO_PID)"
echo "  로그: tail -f /tmp/argocd-pf.log"

# Grafana
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 > /tmp/grafana-pf.log 2>&1 &
GRAFANA_PID=$!
echo "✓ Grafana: http://localhost:3000 (PID: $GRAFANA_PID)"
echo "  로그: tail -f /tmp/grafana-pf.log"

# Prometheus
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 > /tmp/prometheus-pf.log 2>&1 &
PROM_PID=$!
echo "✓ Prometheus: http://localhost:9090 (PID: $PROM_PID)"
echo "  로그: tail -f /tmp/prometheus-pf.log"

# Alertmanager
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093 > /tmp/alertmanager-pf.log 2>&1 &
ALERT_PID=$!
echo "✓ Alertmanager: http://localhost:9093 (PID: $ALERT_PID)"
echo "  로그: tail -f /tmp/alertmanager-pf.log"

# Harbor (클러스터 내부에 있는 경우)
if kubectl get svc -n harbor harbor-core 2>/dev/null; then
    kubectl port-forward svc/harbor-core -n harbor 8081:80 > /tmp/harbor-pf.log 2>&1 &
    HARBOR_PID=$!
    echo "✓ Harbor: http://localhost:8081 (PID: $HARBOR_PID)"
    echo "  로그: tail -f /tmp/harbor-pf.log"
else
    echo "⚠ Harbor는 클러스터 외부에 있습니다: http://192.168.0.169:443"
fi

echo ""
echo "=== Port Forward 프로세스 확인 ==="
ps aux | grep "kubectl port-forward" | grep -v grep

echo ""
echo "=== 접근 정보 ==="
echo "ArgoCD:      https://localhost:8080"
echo "Grafana:     http://localhost:3000"
echo "Prometheus:  http://localhost:9090"
echo "Alertmanager: http://localhost:9093"
if [ -n "$HARBOR_PID" ]; then
    echo "Harbor:      http://localhost:8081"
fi

echo ""
echo "종료하려면: ./scripts/stop-port-forwards.sh"
echo "또는: pkill -f 'kubectl port-forward'"

