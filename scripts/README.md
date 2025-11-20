# 서비스 접근 스크립트

## Port Forward 스크립트 (백그라운드 실행)

### 모든 서비스 Port Forward 시작
```bash
./scripts/port-forwards.sh
```

이 스크립트는 다음 서비스들을 백그라운드로 Port Forward합니다:
- ArgoCD: https://localhost:8080
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Harbor: http://localhost:8081 (클러스터 내부에 있는 경우)

### Port Forward 종료
```bash
./scripts/stop-port-forwards.sh
```

## tmux를 사용한 멀티 터미널 세션

### tmux 세션 생성
```bash
./scripts/tmux-services.sh
```

이 스크립트는 tmux 세션을 생성하고 각 창에서 서비스를 실행합니다:
- 창 0: ArgoCD Port Forward
- 창 1: Grafana Port Forward
- 창 2: Prometheus Port Forward
- 창 3: 일반 터미널
- 창 4: 리소스 모니터링

### tmux 세션 접속
```bash
tmux attach -t services
```

### tmux 기본 명령어
- 창 전환: `Ctrl+b, 0-4` (창 번호)
- 세션 분리 (백그라운드 유지): `Ctrl+b, d`
- 세션 종료: `tmux kill-session -t services`

## 수동 Port Forward

### 개별 서비스 접근
```bash
# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# Grafana
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# Prometheus
kubectl port-forward svc/prometheus-monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
```

## 접근 정보

### ArgoCD
- URL: https://localhost:8080
- 사용자: admin
- 비밀번호: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### Grafana
- URL: http://localhost:3000
- 사용자: admin
- 비밀번호: `kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d`

### Prometheus
- URL: http://localhost:9090

### Harbor
- URL: http://192.168.0.169:443 (또는 Port Forward 사용)
- 사용자: admin
- 비밀번호: Harbor12345
