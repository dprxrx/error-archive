# 시연용 시나리오 가이드

이 디렉토리는 프로젝트 발표 시연을 위한 파일과 스크립트를 포함합니다.

## 디렉토리 구조

```
demo/
├── themes/              # 테마별 소스코드
│   ├── autumn/         # 가을 테마 (배너 없음, 룰렛 없음)
│   └── winter/         # 겨울 테마 (배너 있음, 룰렛 있음)
├── scripts/            # 시연용 스크립트
│   ├── demo-1-theme-cicd.sh      # 시나리오 1: 테마 CICD 시연
│   ├── demo-2-harbor-trivy.sh    # 시나리오 2: Harbor Trivy 취약성 스캔
│   └── demo-3-sonarqube.sh       # 시나리오 3: SonarQube 취약 코드 검사
└── README.md           # 이 파일
```

## 시나리오 1: 가을테마 → 겨울테마 CICD 시연

### 목표
- 소스코드 변경 (가을 → 겨울 테마)
- Tekton CI 파이프라인 실행
- ArgoCD CD 자동 배포 (롤링 업데이트)
- Grafana 대시보드 모니터링
- 과부하 시뮬레이션 및 알림

### 실행 방법

```bash
# 전체 시연 자동 실행
./demo/scripts/demo-1-theme-cicd.sh

# 또는 단계별 수동 실행 (복붙용 명령어)
```

### 단계별 명령어 (복붙용)

#### 1단계: 소스코드 변경
```bash
cd /home/kevin/error-archive
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html
git add frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가"
git push origin main
```

#### 2단계: Tekton CI 파이프라인 실행
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

# 빌드 진행 상황 확인
kubectl get pipelineruns -n default | grep frontend-winter-theme
```

#### 3단계: ArgoCD CD 자동 배포
```bash
# ArgoCD 동기화
argocd app sync frontend --core

# 또는 웹 UI에서 동기화
# https://localhost:8080 (port-forward 필요)

# 롤링 업데이트 진행 상황 확인
kubectl get pods -n error-archive -l app=frontend -w
kubectl rollout status deployment/frontend -n error-archive
```

#### 4단계: Grafana 대시보드 확인
```bash
# Grafana 포트 포워딩
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# 브라우저에서 접속
# http://localhost:3000
# 사용자: admin / admin
```

#### 5단계: 과부하 시뮬레이션
```bash
# 부하 생성
./scripts/generate-load.sh frontend 50 60

# 30초 후 부하 중지
sleep 30
./scripts/stop-load.sh
```

### 변경 사항 비교

#### 가을 테마 (autumn)
- ❌ 겨울 이벤트 배너 없음
- ❌ 룰렛 페이지 링크 없음
- ❌ 테마 토글 버튼 없음

#### 겨울 테마 (winter)
- ✅ 겨울 이벤트 배너 표시
- ✅ 룰렛 페이지 링크 활성화
- ✅ 테마 토글 버튼 표시

## 시나리오 2: Harbor Trivy 취약성 스캔

### 목표
- 취약한 이미지 스캔 (높은 취약성)
- 보안 강화된 이미지 빌드
- 수정된 이미지 스캔 (낮은 취약성)
- Harbor 대시보드에서 비교

### 실행 방법

```bash
./demo/scripts/demo-2-harbor-trivy.sh
```

### 단계별 명령어 (복붙용)

#### 1단계: 취약한 이미지 스캔
```bash
# Harbor 로그인
docker login 192.168.0.169:443 -u admin -p Harbor12345

# Trivy 스캔
trivy image 192.168.0.169:443/project/error-archive-frontend:insecure \
  --severity HIGH,CRITICAL --format table
```

#### 2단계: 보안 강화된 이미지 빌드
```bash
cd /home/kevin/error-archive/frontend
docker build -f Dockerfile.secure \
  -t 192.168.0.169:443/project/error-archive-frontend:secure .
docker push 192.168.0.169:443/project/error-archive-frontend:secure
```

#### 3단계: 수정된 이미지 스캔
```bash
trivy image 192.168.0.169:443/project/error-archive-frontend:secure \
  --severity HIGH,CRITICAL --format table
```

#### 4단계: Harbor 대시보드 확인
```bash
# Harbor 웹 UI 접속
# https://192.168.0.169:443
# 프로젝트 → project → 각 이미지의 취약성 스캔 탭
```

## 시나리오 3: SonarQube 취약 코드 검사

### 목표
- 취약한 코드 스캔 (보안 취약점 발견)
- 취약 코드 수정
- 수정된 코드 스캔 (정상 코드)
- SonarQube 대시보드에서 비교

### 실행 방법

```bash
./demo/scripts/demo-3-sonarqube.sh
```

### 단계별 명령어 (복붙용)

#### 1단계: 취약한 코드 스캔
```bash
cd /home/kevin/error-archive

# SonarQube 스캔
sonar-scanner \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin
```

#### 2단계: 취약 코드 수정
```bash
# 코드 수정 후 커밋
git add backend/
git commit -m "fix: 보안 취약점 수정"
git push origin main
```

#### 3단계: 수정된 코드 스캔
```bash
sonar-scanner \
  -Dsonar.projectKey=error-archive-secure \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin
```

#### 4단계: SonarQube 대시보드 확인
```bash
# SonarQube 웹 UI 접속
# http://localhost:9000
# 사용자: admin / admin
# Projects → 프로젝트 선택 → Issues 탭
```

## 테마 전환 (롤백 포함)

### 가을 테마로 롤백
```bash
cd /home/kevin/error-archive
cp demo/themes/autumn/list.html frontend/list.html
# roulette.html은 제거하거나 숨김 처리
git add frontend/list.html
git commit -m "revert: 가을 테마로 롤백"
git push origin main
```

### 겨울 테마로 전환
```bash
cd /home/kevin/error-archive
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html
git add frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용"
git push origin main
```

## 대시보드 접속 정보

### Tekton Dashboard
```bash
kubectl port-forward svc/tekton-dashboard -n tekton-pipelines 9097:9097
# http://localhost:9097
```

### ArgoCD
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
# https://localhost:8080
# 사용자: admin / 비밀번호: 확인 필요
```

### Grafana
```bash
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80
# http://localhost:3000
# 사용자: admin / admin
```

### Prometheus
```bash
kubectl port-forward svc/monitoring-kube-prometheus-prometheus -n monitoring 9090:9090
# http://localhost:9090
```

### Alertmanager
```bash
kubectl port-forward svc/monitoring-kube-prometheus-alertmanager -n monitoring 9093:9093
# http://localhost:9093
```

### Harbor
```bash
# https://192.168.0.169:443
# 사용자: admin / Harbor12345
```

### SonarQube
```bash
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000
# http://localhost:9000
# 사용자: admin / admin
```

## 주의사항

1. **시연 전 준비사항**
   - 모든 서비스가 정상 실행 중인지 확인
   - 필요한 포트 포워딩 설정
   - Git 저장소 접근 권한 확인

2. **시연 중 주의사항**
   - 각 단계마다 대기 시간 필요
   - 대시보드에서 결과 확인 후 다음 단계 진행
   - 네트워크 지연 고려

3. **롤백 방법**
   - 각 시나리오는 독립적으로 실행 가능
   - 문제 발생 시 이전 단계로 롤백 가능
   - 테마는 언제든지 전환 가능

## 문제 해결

### Tekton 파이프라인 실패
```bash
# 파이프라인 로그 확인
kubectl logs -f pipelinerun/<pipelinerun-name> -n default

# TaskRun 로그 확인
kubectl get taskruns -n default
kubectl logs -f taskrun/<taskrun-name> -n default
```

### ArgoCD 동기화 실패
```bash
# Application 상태 확인
kubectl get application frontend -n argocd
kubectl describe application frontend -n argocd

# 수동 동기화
argocd app sync frontend --core
```

### 이미지 빌드 실패
```bash
# Docker 빌드 로그 확인
docker build --progress=plain -f Dockerfile .

# Harbor 로그인 확인
docker login 192.168.0.169:443 -u admin -p Harbor12345
```

