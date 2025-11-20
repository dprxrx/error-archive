#!/bin/bash
# 리소스 과부하 생성 스크립트 (모니터링 알림 시연용)

NAMESPACE="${1:-error-archive}"
POD_NAME="${2:-}"
LOAD_TYPE="${3:-cpu}"  # cpu, memory, both
DURATION="${4:-300}"   # 초 단위 (기본 5분)

echo "=========================================="
echo "  리소스 과부하 생성 (모니터링 시연용)"
echo "=========================================="
echo ""
echo "네임스페이스: $NAMESPACE"
echo "부하 유형: $LOAD_TYPE"
echo "지속 시간: ${DURATION}초"
echo ""

# Pod 선택
if [ -z "$POD_NAME" ]; then
    echo "사용 가능한 Pod 목록:"
    kubectl get pods -n $NAMESPACE -o custom-columns=NAME:.metadata.name,STATUS:.status.phase
    echo ""
    read -p "Pod 이름을 입력하세요 (또는 Enter로 첫 번째 Pod 선택): " POD_NAME
    
    if [ -z "$POD_NAME" ]; then
        POD_NAME=$(kubectl get pods -n $NAMESPACE -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
        if [ -z "$POD_NAME" ]; then
            echo "❌ Pod를 찾을 수 없습니다."
            exit 1
        fi
    fi
fi

echo "선택된 Pod: $POD_NAME"
echo ""

# Pod 존재 확인
if ! kubectl get pod $POD_NAME -n $NAMESPACE &>/dev/null; then
    echo "❌ Pod '$POD_NAME'를 찾을 수 없습니다."
    exit 1
fi

# 컨테이너 이미지 확인 (stress-ng 사용 가능 여부)
CONTAINER_IMAGE=$(kubectl get pod $POD_NAME -n $NAMESPACE -o jsonpath='{.spec.containers[0].image}')

echo "부하 생성 시작..."
echo ""

# CPU 부하 생성
if [ "$LOAD_TYPE" = "cpu" ] || [ "$LOAD_TYPE" = "both" ]; then
    echo "🔥 CPU 부하 생성 중..."
    kubectl exec -n $NAMESPACE $POD_NAME -- sh -c "
        # stress-ng가 있으면 사용, 없으면 무한 루프
        if command -v stress-ng >/dev/null 2>&1; then
            timeout ${DURATION}s stress-ng --cpu 4 --timeout ${DURATION}s &
        elif command -v stress >/dev/null 2>&1; then
            timeout ${DURATION}s stress --cpu 4 --timeout ${DURATION}s &
        else
            # 무한 루프로 CPU 사용
            timeout ${DURATION}s sh -c 'while true; do :; done' &
        fi
        echo 'CPU 부하 프로세스 시작됨 (PID: \$!)'
    " &
    CPU_PID=$!
    echo "✓ CPU 부하 생성됨 (백그라운드 프로세스)"
fi

# 메모리 부하 생성
if [ "$LOAD_TYPE" = "memory" ] || [ "$LOAD_TYPE" = "both" ]; then
    echo "💾 메모리 부하 생성 중..."
    kubectl exec -n $NAMESPACE $POD_NAME -- sh -c "
        # stress-ng가 있으면 사용, 없으면 메모리 할당
        if command -v stress-ng >/dev/null 2>&1; then
            timeout ${DURATION}s stress-ng --vm 2 --vm-bytes 200M --timeout ${DURATION}s &
        elif command -v stress >/dev/null 2>&1; then
            timeout ${DURATION}s stress --vm 2 --vm-bytes 200M --timeout ${DURATION}s &
        else
            # 메모리 할당 (Node.js 환경)
            if command -v node >/dev/null 2>&1; then
                timeout ${DURATION}s node -e 'var arr=[]; setInterval(()=>arr.push(new Array(10*1024*1024).fill(0)), 1000)' &
            else
                # 기본 메모리 할당
                timeout ${DURATION}s sh -c 'arr=(); while true; do arr+=(\$(seq 1 10000)); sleep 0.1; done' &
            fi
        fi
        echo '메모리 부하 프로세스 시작됨'
    " &
    MEM_PID=$!
    echo "✓ 메모리 부하 생성됨 (백그라운드 프로세스)"
fi

echo ""
echo "=========================================="
echo "  부하 생성 완료!"
echo "=========================================="
echo ""
echo "모니터링:"
echo "  kubectl top pod $POD_NAME -n $NAMESPACE"
echo ""
echo "Prometheus 쿼리:"
echo "  rate(container_cpu_usage_seconds_total{pod=\"$POD_NAME\",namespace=\"$NAMESPACE\"}[1m])"
echo "  container_memory_usage_bytes{pod=\"$POD_NAME\",namespace=\"$NAMESPACE\"}"
echo ""
echo "부하 중지:"
echo "  kubectl exec -n $NAMESPACE $POD_NAME -- pkill -f 'stress\|node\|sh -c'"
echo ""
echo "또는 ${DURATION}초 후 자동 종료됩니다."

