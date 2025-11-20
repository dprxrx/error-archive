#!/bin/bash
# Port Forward 프로세스 종료

echo "=== Port Forward 프로세스 종료 ==="

# kubectl port-forward 프로세스 찾기 및 종료
PIDS=$(pgrep -f "kubectl port-forward")
if [ -z "$PIDS" ]; then
    echo "실행 중인 Port Forward 프로세스가 없습니다."
else
    echo "종료할 프로세스:"
    ps aux | grep "kubectl port-forward" | grep -v grep
    echo ""
    pkill -f "kubectl port-forward"
    sleep 1
    echo "모든 Port Forward 프로세스가 종료되었습니다."
fi

