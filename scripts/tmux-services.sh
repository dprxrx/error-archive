#!/bin/bash
# tmux를 사용하여 여러 서비스 접근 세션 생성

SESSION_NAME="services"

# tmux 세션이 이미 존재하는지 확인
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "세션 '$SESSION_NAME'이 이미 존재합니다."
    echo "재접속하려면: tmux attach -t $SESSION_NAME"
    exit 1
fi

# 새 tmux 세션 생성
tmux new-session -d -s "$SESSION_NAME"

# 창 0: ArgoCD
tmux rename-window -t "$SESSION_NAME:0" "argocd"
tmux send-keys -t "$SESSION_NAME:0" "echo '=== ArgoCD Port Forward ===' && kubectl port-forward svc/argocd-server -n argocd 8080:443" C-m

# 창 1: Grafana
tmux new-window -t "$SESSION_NAME:1" -n "grafana"
tmux send-keys -t "$SESSION_NAME:1" "echo '=== Grafana Port Forward ===' && kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80" C-m

# 창 2: Prometheus
tmux new-window -t "$SESSION_NAME:2" -n "prometheus"
tmux send-keys -t "$SESSION_NAME:2" "echo '=== Prometheus Port Forward ===' && kubectl port-forward svc/prometheus-monitoring-kube-prometheus-prometheus -n monitoring 9090:9090" C-m

# 창 3: 일반 터미널
tmux new-window -t "$SESSION_NAME:3" -n "terminal"
tmux send-keys -t "$SESSION_NAME:3" "echo '=== 일반 터미널 ===' && echo 'kubectl 명령어를 사용할 수 있습니다.'" C-m

# 창 4: 모니터링
tmux new-window -t "$SESSION_NAME:4" -n "monitor"
tmux send-keys -t "$SESSION_NAME:4" "watch -n 2 'kubectl get pods -A | grep -E \"(argocd|monitoring|error-archive)\"'" C-m

echo "tmux 세션 '$SESSION_NAME'이 생성되었습니다."
echo ""
echo "접속 방법:"
echo "  tmux attach -t $SESSION_NAME"
echo ""
echo "창 전환:"
echo "  Ctrl+b, 0-4 (창 번호)"
echo ""
echo "세션 분리 (백그라운드 유지):"
echo "  Ctrl+b, d"
echo ""
echo "세션 종료:"
echo "  tmux kill-session -t $SESSION_NAME"

