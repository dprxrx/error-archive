# 프로젝트 발표용 CI/CD 시연 시나리오

## 시나리오 개요

### 기본 시나리오

| 시나리오 | 설명 | 소요 시간 | 스크립트 |
|---------|------|----------|---------|
| 1. 기본 CI/CD 파이프라인 | 코드 변경부터 배포까지 전체 흐름 | 3-4분 | `scenario-1-basic-cicd.sh` |
| 2. 버전 관리 및 롤백 | 버전 업그레이드와 안전한 롤백 | 2-3분 | `scenario-2-rollback.sh` |
| 3. 보안 스캔 통합 | 취약점 스캔 및 보안 강화 | 2-3분 | `scenario-3-security-scan.sh` |
| 4. 다중 환경 배포 | 개발/스테이징/프로덕션 환경 분리 | 2-3분 | `scenario-4-multi-env.sh` |
| 5. 모니터링 및 알림 | 실시간 모니터링과 알림 설정 | 2-3분 | `scenario-5-monitoring.sh` |
| 6. 모니터링 심화 | 메트릭 수집 및 분석 | 3-4분 | `scenario-6-monitoring-advanced.sh` |

### 실무 시나리오 (프로덕션 환경 대응)

| 시나리오 | 설명 | 소요 시간 | 스크립트 |
|---------|------|----------|---------|
| 7. 프로덕션 장애 대응 | CPU 급증으로 인한 서비스 지연 대응 | 4-5분 | `scenario-7-production-incident.sh` |
| 8. 자동 스케일링 | HPA를 통한 부하 분산 및 자동 확장 | 5-6분 | `scenario-8-auto-scaling.sh` |
| 9. 배포 실패 및 롤백 | 잘못된 배포 후 자동/수동 롤백 | 3-4분 | `scenario-9-rollback-failure.sh` |
| 10. 모니터링 알림 시연 | 리소스 과부하로 알림 트리거 | 4-5분 | `scenario-10-monitoring-alert.sh` |

### 유틸리티 스크립트

| 스크립트 | 설명 |
|---------|------|
| `generate-load.sh` | 리소스 과부하 생성 (CPU/메모리) |
| `stop-load.sh` | 생성된 부하 중지 |

---

## 시나리오 1: 기본 CI/CD 파이프라인 시연

### 목표
코드 변경부터 자동 빌드, Harbor 푸시, ArgoCD 자동 배포까지 전체 CI/CD 워크플로우 시연

### 시연 순서

#### 1단계: 코드 변경 (배너 추가)
```bash
cd /home/kevin/proj/error-archive-1

# Frontend에 배너 추가
cat >> frontend/index.html << 'EOF'

<!-- 배너 추가 (버전 1.6) -->
<div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); color: white; padding: 8px; text-align: center; font-size: 14px; font-weight: bold; position: fixed; top: 0; left: 0; right: 0; z-index: 9999;">
  🚀 CI/CD 파이프라인 시연 - 버전 1.6
</div>
<style>
  body { padding-top: 40px; }
</style>
EOF

# Git 커밋 및 푸시
git add frontend/index.html
git commit -m "Add banner for version 1.6 - CI/CD demo"
git push origin main
```

#### 2단계: CI Pipeline 실행 (Tekton)
```bash
# Frontend 이미지 빌드 및 Harbor 푸시
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-demo-1.6-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:1.6
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF

# 빌드 진행 상황 확인
watch -n 3 'kubectl get pipelineruns | grep frontend-demo-1.6'
```

#### 3단계: Kubernetes 매니페스트 업데이트
```bash
# 매니페스트 업데이트
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.6|g' k8s/error-archive/frontend-deployment.yaml

# Git 푸시 (ArgoCD 자동 배포)
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy frontend version 1.6"
git push origin main
```

#### 4단계: 배포 확인
```bash
# ArgoCD Application 상태
kubectl get applications -n argocd

# 배포 상태 실시간 모니터링
watch -n 2 'kubectl get deployments -n error-archive -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,READY:.status.readyReplicas/..spec.replicas'

# Pod 이미지 확인
kubectl get pods -n error-archive -l app=frontend -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}'
```

---

## 시나리오 2: 버전 관리 및 롤백

### 목표
버전 업그레이드 후 문제 발생 시 안전한 롤백 프로세스 시연

### 시연 순서

#### 1단계: 문제가 있는 버전 배포
```bash
cd /home/kevin/proj/error-archive-1

# 문제가 있는 코드 추가 (예: 에러 발생 코드)
cat >> frontend/index.html << 'EOF'

<!-- 문제가 있는 코드 -->
<script>
  console.error("Intentional error for demo");
  throw new Error("Demo error");
</script>
EOF

git add frontend/index.html
git commit -m "Add problematic code - version 1.7"
git push origin main

# 이미지 빌드
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-problem-1.7-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:1.7
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF
```

#### 2단계: 문제 버전 배포
```bash
# 매니페스트 업데이트
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.7|g' k8s/error-archive/frontend-deployment.yaml

git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy problematic version 1.7"
git push origin main
```

#### 3단계: 문제 발견 및 롤백
```bash
# 문제 확인
kubectl logs -f deployment/frontend -n error-archive

# 롤백 실행
./scripts/rollback.sh 1.6

# 또는 수동 롤백
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.6|g' k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Rollback to stable version 1.6"
git push origin main
```

#### 4단계: 롤백 확인
```bash
# 롤백 상태 확인
kubectl rollout status deployment/frontend -n error-archive

# 이전 버전으로 복구 확인
kubectl get pods -n error-archive -l app=frontend -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}'
```

---

## 시나리오 3: 보안 스캔 통합

### 목표
Harbor Trivy 스캔을 통한 취약점 검출 및 보안 강화 이미지 배포

### 시연 순서

#### 1단계: 현재 이미지 취약점 확인
```bash
# Harbor에서 1.6 버전 이미지 스캔 결과 확인
# Harbor UI: http://192.168.0.169:443
# 프로젝트 → error-archive-frontend → 1.6 → 취약점 탭

# 또는 로컬에서 스캔
./scripts/scan-harbor-image.sh 192.168.0.169:443/project/error-archive-frontend:1.6
```

#### 2단계: 보안 강화 Dockerfile 적용
```bash
cd /home/kevin/proj/error-archive-1

# 보안 강화 Dockerfile 적용
./scripts/apply-secure-dockerfiles.sh
```

#### 3단계: 보안 강화 이미지 빌드
```bash
# 보안 강화 버전 빌드
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-secure-1.8-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:1.8
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF
```

#### 4단계: 취약점 비교
```bash
# 보안 강화 버전 스캔
./scripts/scan-harbor-image.sh 192.168.0.169:443/project/error-archive-frontend:1.8

# Harbor UI에서 취약점 개수 비교
# 1.6 버전 vs 1.8 버전 취약점 개수 확인
```

---

## 시나리오 4: 다중 환경 배포

### 목표
개발/스테이징/프로덕션 환경으로 분리하여 단계적 배포 시연

### 시연 순서

#### 1단계: 개발 환경 배포
```bash
cd /home/kevin/proj/error-archive-1

# 개발 환경 매니페스트 생성
kubectl create namespace error-archive-dev 2>/dev/null || true

# 개발 환경에 배포
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-dev
  namespace: error-archive-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
      env: dev
  template:
    metadata:
      labels:
        app: frontend
        env: dev
    spec:
      containers:
      - name: nginx
        image: 192.168.0.169:443/project/error-archive-frontend:1.6
        ports:
        - containerPort: 80
EOF

# 개발 환경 확인
kubectl get pods -n error-archive-dev
```

#### 2단계: 스테이징 환경 배포
```bash
# 스테이징 환경 생성
kubectl create namespace error-archive-staging 2>/dev/null || true

# 스테이징 환경에 배포
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-staging
  namespace: error-archive-staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
      env: staging
  template:
    metadata:
      labels:
        app: frontend
        env: staging
    spec:
      containers:
      - name: nginx
        image: 192.168.0.169:443/project/error-archive-frontend:1.6
        ports:
        - containerPort: 80
EOF
```

#### 3단계: 프로덕션 환경 배포
```bash
# 프로덕션 환경 (기존 error-archive 네임스페이스)
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.6|g' k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy to production - version 1.6"
git push origin main
```

#### 4단계: 환경별 상태 확인
```bash
# 모든 환경 확인
kubectl get deployments -A | grep frontend

# 환경별 Pod 확인
kubectl get pods -n error-archive-dev
kubectl get pods -n error-archive-staging
kubectl get pods -n error-archive
```

---

## 시나리오 5: 모니터링 및 알림

### 목표
Prometheus 메트릭 수집, Grafana 대시보드, 알림 설정 시연

### 시연 순서

#### 1단계: Prometheus 연결 및 확인
```bash
# Prometheus Port Forward
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 > /tmp/prometheus-pf.log 2>&1 &

# 접속: http://localhost:9090
echo "Prometheus 접속: http://localhost:9090"
```

#### 2단계: 메트릭 쿼리 확인
```bash
# Prometheus에서 실행할 쿼리 예시
echo "=== Prometheus 쿼리 예시 ==="
echo ""
echo "1. Pod CPU 사용률:"
echo "   rate(container_cpu_usage_seconds_total{namespace=\"error-archive\"}[5m])"
echo ""
echo "2. Pod 메모리 사용률:"
echo "   container_memory_usage_bytes{namespace=\"error-archive\"}"
echo ""
echo "3. HTTP 요청 수:"
echo "   sum(rate(http_requests_total{namespace=\"error-archive\"}[5m]))"
echo ""
echo "4. Pod 재시작 횟수:"
echo "   kube_pod_container_status_restarts_total{namespace=\"error-archive\"}"
```

#### 3단계: Grafana 대시보드 확인
```bash
# Grafana Port Forward
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 > /tmp/grafana-pf.log 2>&1 &

# Grafana 비밀번호 확인
echo "Grafana 접속: http://localhost:3000"
echo "사용자: admin"
echo "비밀번호:"
kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d
echo ""
```

#### 4단계: 실시간 메트릭 모니터링
```bash
# Pod 리소스 사용률 실시간 확인
watch -n 2 'kubectl top pods -n error-archive'

# Deployment 상태 모니터링
watch -n 2 'kubectl get deployments -n error-archive -o wide'

# Pod 이벤트 모니터링
kubectl get events -n error-archive --sort-by='.lastTimestamp' | tail -10
```

#### 5단계: 알림 규칙 확인
```bash
# Alertmanager 규칙 확인
kubectl get prometheusrules -n monitoring

# 알림 규칙 상세 확인
kubectl get prometheusrules -n monitoring -o yaml | grep -A 10 "rules:"
```

---

## 시나리오 6: 모니터링 심화 - 메트릭 수집 및 분석

### 목표
애플리케이션 메트릭 수집, 대시보드 생성, 알림 설정

### 시연 순서

#### 1단계: 애플리케이션 메트릭 확인
```bash
# Backend Pod 메트릭 엔드포인트 확인
kubectl get pods -n error-archive -l app=backend
BACKEND_POD=$(kubectl get pods -n error-archive -l app=backend -o jsonpath='{.items[0].metadata.name}')

# Pod 내부에서 메트릭 확인
kubectl exec -n error-archive $BACKEND_POD -- curl -s http://localhost:3000/metrics | head -20
```

#### 2단계: ServiceMonitor 생성 (Prometheus가 메트릭 수집)
```bash
# ServiceMonitor 생성
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

# ServiceMonitor 확인
kubectl get servicemonitor -n error-archive
```

#### 3단계: Grafana 대시보드 생성
```bash
# Grafana 대시보드 ConfigMap 생성
kubectl apply -f - <<EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: error-archive-dashboard
  namespace: monitoring
  labels:
    grafana_dashboard: "1"
data:
  error-archive.json: |
    {
      "dashboard": {
        "title": "Error Archive Monitoring",
        "panels": [
          {
            "title": "Pod CPU Usage",
            "targets": [
              {
                "expr": "rate(container_cpu_usage_seconds_total{namespace=\"error-archive\"}[5m])"
              }
            ]
          },
          {
            "title": "Pod Memory Usage",
            "targets": [
              {
                "expr": "container_memory_usage_bytes{namespace=\"error-archive\"}"
              }
            ]
          }
        ]
      }
    }
EOF
```

#### 4단계: 알림 규칙 생성
```bash
# PrometheusRule 생성
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
        summary: "High CPU usage detected"
    - alert: HighMemoryUsage
      expr: container_memory_usage_bytes{namespace="error-archive"} / container_spec_memory_limit_bytes > 0.8
      for: 5m
      labels:
        severity: warning
      annotations:
        summary: "High memory usage detected"
EOF
```

#### 5단계: 알림 확인
```bash
# Alertmanager 접속
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093 > /tmp/alertmanager-pf.log 2>&1 &

echo "Alertmanager 접속: http://localhost:9093"
echo "알림 확인: http://localhost:9093/#/alerts"
```

---

## 빠른 참조: 모든 시나리오 실행 명령어

### 시나리오 1: 기본 CI/CD
```bash
./scripts/cicd-demo.sh
```

### 시나리오 2: 롤백
```bash
./scripts/rollback.sh 1.6
```

### 시나리오 3: 보안 스캔
```bash
./scripts/scan-harbor-image.sh 192.168.0.169:443/project/error-archive-frontend:1.8
```

### 시나리오 4: 다중 환경
```bash
# 위의 시나리오 4 명령어 실행
```

### 시나리오 5-6: 모니터링
```bash
./scripts/port-forwards.sh
# 또는
./scripts/tmux-services.sh
```

---

## 시나리오 7: 프로덕션 장애 대응 (실무 시나리오)

### 목표
실제 프로덕션 환경에서 발생할 수 있는 CPU 급증 상황을 시뮬레이션하고, 모니터링을 통해 문제를 감지하고 대응하는 과정을 시연

### 시나리오 설명
- **상황**: 백엔드 Pod의 CPU 사용률이 급증하여 서비스 응답 지연 발생
- **대응**: 모니터링을 통한 문제 감지 → 대응 조치 (Pod 재시작, 스케일 아웃, 리소스 조정)

### 실행 방법
```bash
./scripts/scenario-7-production-incident.sh
```

### 주요 단계
1. 현재 상태 확인
2. CPU 부하 생성 (장애 시뮬레이션)
3. 모니터링 대시보드 확인
4. 알림 확인
5. 대응 조치 (Pod 재시작, 스케일 아웃 등)

---

## 시나리오 8: 자동 스케일링 및 부하 분산 (실무 시나리오)

### 목표
HPA(Horizontal Pod Autoscaler)를 통한 자동 스케일링 기능 시연

### 시나리오 설명
- **상황**: 트래픽 증가로 인한 리소스 부족
- **대응**: HPA가 CPU/메모리 사용률을 모니터링하여 자동으로 Pod 수 증가

### 실행 방법
```bash
./scripts/scenario-8-auto-scaling.sh
```

### 주요 단계
1. HPA 생성 (min: 2, max: 5, CPU: 70%, Memory: 80%)
2. 현재 상태 확인
3. 부하 생성 (자동 스케일링 트리거)
4. 자동 스케일링 모니터링 (Pod 수 증가 확인)

---

## 시나리오 9: 배포 실패 및 자동 롤백 (실무 시나리오)

### 목표
잘못된 배포 후 자동/수동 롤백 프로세스 시연

### 시나리오 설명
- **상황**: 존재하지 않는 이미지 버전으로 배포 시도
- **대응**: 배포 실패 감지 → 자동/수동 롤백

### 실행 방법
```bash
./scripts/scenario-9-rollback-failure.sh
```

### 주요 단계
1. 현재 버전 확인
2. 잘못된 이미지로 배포 시도
3. 배포 상태 모니터링 (실패 확인)
4. 롤백 실행 (kubectl 또는 ArgoCD)

---

## 시나리오 10: 모니터링 알림 시연 (부하 생성 포함)

### 목표
리소스 과부하를 통한 Prometheus 알림 트리거 및 Alertmanager 알림 확인

### 시나리오 설명
- **상황**: CPU/메모리 사용률 급증
- **대응**: Prometheus 알림 규칙 트리거 → Alertmanager 알림 확인

### 실행 방법
```bash
./scripts/scenario-10-monitoring-alert.sh
```

### 주요 단계
1. 알림 규칙 생성 (CPU > 50%, Memory > 70%)
2. Prometheus/Alertmanager 연결
3. 현재 상태 확인
4. 리소스 부하 생성 (알림 트리거)
5. 모니터링 및 알림 확인

---

## 유틸리티: 리소스 부하 생성

### 부하 생성 스크립트
```bash
# 기본 사용법 (CPU 부하)
./scripts/generate-load.sh error-archive <POD_NAME> cpu 300

# 메모리 부하
./scripts/generate-load.sh error-archive <POD_NAME> memory 300

# CPU + 메모리 부하
./scripts/generate-load.sh error-archive <POD_NAME> both 300

# Pod 이름 자동 선택
./scripts/generate-load.sh error-archive "" cpu 300
```

### 부하 중지
```bash
./scripts/stop-load.sh error-archive <POD_NAME>
```

### 예시: 백엔드 Pod에 CPU 부하 생성
```bash
BACKEND_POD=$(kubectl get pods -n error-archive -l app=backend -o jsonpath='{.items[0].metadata.name}')
./scripts/generate-load.sh error-archive $BACKEND_POD cpu 300
```

---

## 발표 팁

### 기본 시나리오
1. **시나리오 1**: 전체 흐름을 보여주며 각 단계 설명
2. **시나리오 2**: 문제 발생 시 빠른 대응 능력 강조
3. **시나리오 3**: 보안 강화 프로세스 시연
4. **시나리오 4**: 엔터프라이즈급 배포 전략
5. **시나리오 5-6**: 운영 모니터링 및 관찰성 강조

### 실무 시나리오 (추천)
1. **시나리오 7**: 프로덕션 장애 대응 능력 강조
2. **시나리오 8**: 자동화된 인프라 운영 시연
3. **시나리오 9**: 안전한 배포 프로세스 및 롤백 능력
4. **시나리오 10**: 실시간 모니터링 및 알림 시스템 시연

### 발표 시나리오 조합 추천
- **기본 발표**: 시나리오 1 → 시나리오 2 → 시나리오 10
- **실무 중심**: 시나리오 7 → 시나리오 8 → 시나리오 9
- **전체 시연**: 시나리오 1 → 시나리오 7 → 시나리오 10

각 시나리오는 2-6분 내에 완료되도록 설계되었습니다.

