#!/bin/bash
# 시나리오 8: 자동 스케일링 및 부하 분산 (실무 시나리오)

echo "=========================================="
echo "  시나리오 8: 자동 스케일링 및 부하 분산"
echo "=========================================="
echo ""

# HPA (Horizontal Pod Autoscaler) 생성
echo "1단계: HPA 생성..."
kubectl apply -f - <<EOF
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: backend-hpa
  namespace: error-archive
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: backend-deployment
  minReplicas: 2
  maxReplicas: 5
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80
EOF

echo "✓ HPA 생성 완료"
echo ""

# 현재 상태
echo "2단계: 현재 상태 확인..."
kubectl get hpa -n error-archive
kubectl get pods -n error-archive -l app=backend
echo ""

# 부하 생성
echo "3단계: 부하 생성 (자동 스케일링 트리거)..."
BACKEND_PODS=($(kubectl get pods -n error-archive -l app=backend -o jsonpath='{.items[*].metadata.name}'))

for pod in "${BACKEND_PODS[@]}"; do
    echo "Pod $pod에 부하 생성 중..."
    kubectl exec -n error-archive $pod -- sh -c "
        nohup timeout 180s sh -c 'while true; do :; done' >/dev/null 2>&1 &
        echo '부하 생성됨'
    " 2>/dev/null || true
done

echo "✓ 부하 생성 완료"
echo ""

# 모니터링
echo "4단계: 자동 스케일링 모니터링..."
echo ""
echo "HPA 상태 확인 (30초마다):"
for i in {1..6}; do
    echo ""
    echo "--- 확인 $i/6 ---"
    kubectl get hpa backend-hpa -n error-archive
    kubectl get pods -n error-archive -l app=backend
    kubectl top pods -n error-archive -l app=backend 2>/dev/null | head -5 || echo "메트릭 수집 중..."
    sleep 30
done

echo ""
echo "=========================================="
echo "  자동 스케일링 시연 완료!"
echo "=========================================="
echo ""
echo "부하 중지:"
for pod in "${BACKEND_PODS[@]}"; do
    echo "  kubectl exec -n error-archive $pod -- pkill -f 'while true'"
done

