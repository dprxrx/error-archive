# 시연용 빠른 명령어 모음 (복붙용)

## 시나리오 1: 가을테마 → 겨울테마 CICD 시연

### 1단계: 소스코드 변경
```bash
cd /home/kevin/error-archive

# Git 설정 (처음 한 번만)
git config --global user.email "dprxrx@gmail.com"
git config --global user.name "dprxrx"

# 테마 변경
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html
git add frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가"

# Git 푸시 (수동)
git push origin main
```

### 2단계: Tekton CI 파이프라인 실행
```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-winter-theme-
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
    value: 192.168.0.169:443/project/error-archive-frontend:winter-$(date +%Y%m%d-%H%M%S)
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

### 3단계: 빌드 진행 상황 확인
```bash
kubectl get pipelineruns -n default | grep frontend-winter-theme
kubectl logs -f pipelinerun/$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}') -n default
```

### 4단계: ArgoCD 동기화 및 배포
```bash
# ArgoCD Application 이름 확인
kubectl get applications -n argocd

# 동기화 (Application 이름: error-archive-frontend)
argocd app sync error-archive-frontend --core

# 또는 kubectl 사용
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 롤링 업데이트 진행 상황 확인
kubectl get pods -n error-archive -l app=frontend -w
kubectl rollout status deployment/frontend -n error-archive
```

### 5단계: Grafana 대시보드 확인
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
# 브라우저: http://localhost:3000 (admin/admin)
```

### 6단계: 과부하 시뮬레이션
```bash
./scripts/generate-load.sh frontend 50 60
sleep 30
./scripts/stop-load.sh
```

### 7단계: Alertmanager 알림 확인
```bash
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093
# 브라우저: http://localhost:9093
```

---

## 시나리오 2: Harbor Trivy 취약성 스캔

### 1단계: Harbor 로그인
```bash
docker login 192.168.0.169:443 -u admin -p Harbor12345
```

### 2단계: 취약한 이미지 스캔
```bash
trivy image 192.168.0.169:443/project/error-archive-frontend:insecure --severity HIGH,CRITICAL --format table
```

### 3단계: 보안 강화된 이미지 빌드
```bash
cd /home/kevin/error-archive/frontend
docker build -f Dockerfile.secure -t 192.168.0.169:443/project/error-archive-frontend:secure .
docker push 192.168.0.169:443/project/error-archive-frontend:secure
```

### 4단계: 수정된 이미지 스캔
```bash
trivy image 192.168.0.169:443/project/error-archive-frontend:secure --severity HIGH,CRITICAL --format table
```

### 5단계: Harbor 대시보드 확인
```bash
# 브라우저: https://192.168.0.169:443
# 프로젝트 → project → 각 이미지의 취약성 스캔 탭
```

---

## 시나리오 3: SonarQube 취약 코드 검사

### 1단계: SonarQube 포트 포워딩
```bash
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
# 브라우저: http://localhost:9000 (admin/admin)
```

### 2단계: 취약한 코드 스캔
```bash
cd /home/kevin/error-archive
sonar-scanner \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin
```

### 3단계: 수정된 코드 스캔
```bash
sonar-scanner \
  -Dsonar.projectKey=error-archive-secure \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin
```

### 4단계: SonarQube 대시보드 확인
```bash
# 브라우저: http://localhost:9000
# Projects → 프로젝트 선택 → Issues 탭
```

---

## 테마 전환

### 가을 테마로 전환 (전체 프로세스)
```bash
# 1. 가을 테마로 전환 (소스코드 변경 + CI 빌드)
./demo/scripts/switch-to-autumn.sh

# 2. Git 푸시 (수동)
git push origin main

# 3. 빌드된 이미지 태그 확인 후 매니페스트 업데이트
# 예: autumn-20251120-170611
./demo/scripts/update-deployment-image.sh autumn-20251120-170611
```

### 겨울 테마로 전환 (전체 프로세스)
```bash
# 1. 겨울 테마로 전환 (소스코드 변경 + CI 빌드)
./demo/scripts/switch-to-winter.sh

# 2. Git 푸시 (수동)
git push origin main

# 3. 빌드된 이미지 태그 확인 후 매니페스트 업데이트
# 예: winter-20251120-170611
./demo/scripts/update-deployment-image.sh winter-20251120-170611
```

### 테마 검증
```bash
# 현재 배포된 테마 확인
./demo/scripts/verify-theme.sh
```

### 수동 테마 전환 (빠른 전환)

#### 가을 테마로 전환
```bash
cd /home/kevin/error-archive
cp demo/themes/autumn/list.html frontend/list.html
git add frontend/list.html
git commit -m "feat: 가을 테마 적용"
git push origin main
```

#### 겨울 테마로 전환
```bash
cd /home/kevin/error-archive
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html
git add frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용"
git push origin main
```

---

## 대시보드 포트 포워딩 (한 번에 실행)

```bash
# Tekton Dashboard
kubectl port-forward svc/tekton-dashboard -n tekton-pipelines 9097:9097 &

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# Grafana
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 &

# Prometheus
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 &

# Alertmanager
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093 &

# SonarQube
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
```

### 접속 정보
- Tekton: http://localhost:9097
- ArgoCD: https://localhost:8080
- Grafana: http://localhost:3000 (admin/admin)
- Prometheus: http://localhost:9090
- Alertmanager: http://localhost:9093
- SonarQube: http://localhost:9000 (admin/admin)
- Harbor: https://192.168.0.169:443 (admin/Harbor12345)

---

## 빠른 확인 명령어

### Pod 상태 확인
```bash
kubectl get pods -n error-archive
kubectl get pods -n error-archive -l app=frontend
kubectl get pods -n error-archive -l app=backend
```

### 서비스 상태 확인
```bash
kubectl get svc -n error-archive
kubectl get endpoints -n error-archive
```

### 배포 상태 확인
```bash
kubectl get deployments -n error-archive
kubectl rollout status deployment/frontend -n error-archive
kubectl rollout status deployment/backend-deployment -n error-archive
```

### 로그 확인
```bash
kubectl logs -n error-archive deployment/frontend --tail=50
kubectl logs -n error-archive deployment/backend-deployment --tail=50
```

### Tekton 파이프라인 상태
```bash
kubectl get pipelineruns -n default
kubectl get taskruns -n default
```

### ArgoCD 애플리케이션 상태
```bash
kubectl get application -n argocd
argocd app list
argocd app get frontend
```

---

## 문제 해결

### Tekton 파이프라인 실패 시
```bash
kubectl get pipelineruns -n default
kubectl describe pipelinerun <pipelinerun-name> -n default
kubectl logs -f pipelinerun/<pipelinerun-name> -n default
```

### ArgoCD 동기화 실패 시
```bash
kubectl get application frontend -n argocd
kubectl describe application frontend -n argocd
argocd app sync frontend --core
```

### 이미지 빌드 실패 시
```bash
docker build --progress=plain -f Dockerfile .
docker login 192.168.0.169:443 -u admin -p Harbor12345
```

### Pod 재시작
```bash
kubectl rollout restart deployment/frontend -n error-archive
kubectl rollout restart deployment/backend-deployment -n error-archive
```

