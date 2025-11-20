# Error Archive CI/CD 구축 워크북

## 목차
1. [개요](#개요)
2. [환경 구성](#환경-구성)
3. [Tekton CI 구축](#tekton-ci-구축)
4. [ArgoCD CD 구축](#argocd-cd-구축)
5. [통합 CI/CD 워크플로우](#통합-cicd-워크플로우)
6. [서비스 접근 방법](#서비스-접근-방법)
7. [트러블슈팅](#트러블슈팅)

---

## 개요

이 워크북은 Error Archive 프로젝트의 CI/CD 인프라 구축 과정을 단계별로 설명합니다.

### 아키텍처
```
┌─────────────┐
│  Git Push   │
└──────┬──────┘
       │
       ▼
┌─────────────┐     ┌──────────────┐
│ Tekton (CI) │────▶│ Harbor       │
│ - Build     │     │ Registry     │
│ - Push      │     └──────┬───────┘
└─────────────┘            │
                           ▼
                    ┌─────────────┐
                    │ Git Repo     │
                    │ (Manifests)  │
                    └──────┬───────┘
                           │
                           ▼
                    ┌─────────────┐
                    │ ArgoCD (CD) │
                    │ - Sync      │
                    │ - Deploy    │
                    └─────────────┘
```

### 사용 기술
- **CI**: Tekton Pipelines
- **CD**: ArgoCD (GitOps)
- **Container Registry**: Harbor
- **Kubernetes**: K8s Cluster
- **Monitoring**: Prometheus + Grafana

---

## 환경 구성

### 사전 요구사항
- Kubernetes 클러스터 (v1.24+)
- kubectl 설치 및 클러스터 접근 권한
- Git 저장소 접근 권한
- Harbor Registry 접근 권한

### Git 설정
```bash
git config user.email "dprxrx@gmail.com"
git config user.name "dprxrx"
```

---

## Tekton CI 구축

### 1. Tekton 설치 확인
```bash
kubectl get namespace | grep tekton
kubectl get pods -n tekton-pipelines
```

### 2. Tasks 배포
```bash
kubectl apply -f tekton/tasks/
```

배포되는 Tasks:
- `git-clone`: Git 저장소에서 소스 코드 클론
- `docker-build-and-push`: Docker 이미지 빌드 및 Harbor 푸시
- `kubernetes-deploy`: Kubernetes 배포 (선택사항)

### 3. CI Pipeline 배포
```bash
# CI 전용 Pipeline (배포 제외)
kubectl apply -f tekton/pipelines/backend-pipeline-ci.yaml
kubectl apply -f tekton/pipelines/frontend-pipeline-ci.yaml
```

### 4. Pipeline 확인
```bash
kubectl get pipelines
kubectl get tasks
```

---

## ArgoCD CD 구축

### 1. ArgoCD 설치
```bash
# 설치 스크립트 실행
./argocd/install-argocd.sh

# 또는 수동 설치
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. ArgoCD 접근 설정
```bash
# Port Forward (백그라운드)
kubectl port-forward svc/argocd-server -n argocd 8080:443 &

# 초기 admin 비밀번호 확인
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""

# 비밀번호 변경 (선택사항)
argocd account update-password
```

### 3. Git Repository 등록
```bash
# GitHub Repository Secret 생성
kubectl create secret generic github-repo-secret \
  --from-literal=type=git \
  --from-literal=url=https://github.com/dprxrx/error-archive.git \
  --from-literal=password=YOUR_GITHUB_TOKEN \
  --from-literal=username=dprxrx \
  -n argocd \
  --dry-run=client -o yaml | kubectl label --local -f - -o yaml argocd.argoproj.io/secret-type=repository | kubectl apply -f -
```

### 4. ArgoCD Application 배포
```bash
kubectl apply -f argocd/backend-application.yaml
kubectl apply -f argocd/frontend-application.yaml
```

### 5. Application 상태 확인
```bash
kubectl get applications -n argocd
kubectl describe application error-archive-backend -n argocd
```

---

## 통합 CI/CD 워크플로우

### 전체 워크플로우

#### 1단계: 코드 변경 및 푸시
```bash
# 코드 수정 후
git add .
git commit -m "Update features"
git push origin main
```

#### 2단계: CI Pipeline 실행 (Tekton)
```bash
# Backend 빌드
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: backend-ci-
  namespace: default
spec:
  pipelineRef:
    name: backend-pipeline-ci
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-backend:1.3
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

# Frontend 빌드
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-ci-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:1.3
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

#### 3단계: Pipeline 상태 확인
```bash
# PipelineRun 상태
kubectl get pipelineruns

# TaskRun 로그
kubectl get taskruns
kubectl logs <taskrun-name> -c <step-name>
```

#### 4단계: Kubernetes 매니페스트 업데이트
```bash
# 이미지 버전 업데이트
sed -i 's|192.168.0.169:443/project/error-archive-backend:.*|192.168.0.169:443/project/error-archive-backend:1.3|g' k8s/error-archive/backend-deployment.yaml
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.3|g' k8s/error-archive/frontend-deployment.yaml
```

#### 5단계: Git에 커밋 및 푸시
```bash
git add k8s/error-archive/
git commit -m "Deploy version 1.3"
git push origin main
```

#### 6단계: ArgoCD 자동 배포 확인
```bash
# ArgoCD Application 상태
kubectl get applications -n argocd

# 배포 상태
kubectl get deployments -n error-archive

# 실시간 모니터링
watch -n 2 'kubectl get deployments -n error-archive -o wide'
```

---

## 서비스 접근 방법

### 터미널 멀티플렉서 사용 (tmux/screen)

#### tmux 사용 (권장)
```bash
# tmux 설치
sudo apt-get install tmux  # Ubuntu/Debian
sudo yum install tmux      # CentOS/RHEL

# 새 세션 시작
tmux new -s cicd

# 세션 분리 (백그라운드로 유지)
# Ctrl+b, d

# 세션 재접속
tmux attach -t cicd

# 세션 목록
tmux ls

# 세션 종료
tmux kill-session -t cicd
```

#### tmux로 여러 서비스 접근 유지
```bash
# tmux 세션 시작
tmux new -s services

# 창 분할 (수평)
Ctrl+b, "  # 창을 위아래로 분할

# 창 분할 (수직)
Ctrl+b, %  # 창을 좌우로 분할

# 창 전환
Ctrl+b, 화살표키

# 각 창에서 서비스 실행
# 창 1: ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443

# 창 2: Harbor (Harbor가 클러스터 내부에 있는 경우)
kubectl port-forward svc/harbor-core -n harbor 8081:80

# 창 3: Grafana
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80

# 창 4: 일반 터미널
# kubectl 명령어 등
```

#### screen 사용
```bash
# screen 설치
sudo apt-get install screen

# 새 세션 시작
screen -S services

# 세션 분리
Ctrl+a, d

# 세션 재접속
screen -r services

# 세션 목록
screen -ls
```

### Port Forward 스크립트

`scripts/port-forwards.sh` 생성:
```bash
#!/bin/bash
# 여러 서비스 Port Forward를 백그라운드로 실행

echo "=== 서비스 Port Forward 시작 ==="

# ArgoCD
kubectl port-forward svc/argocd-server -n argocd 8080:443 > /tmp/argocd-pf.log 2>&1 &
echo "ArgoCD: https://localhost:8080 (PID: $!)"

# Harbor (네임스페이스 확인 필요)
# kubectl port-forward svc/harbor-core -n harbor 8081:80 > /tmp/harbor-pf.log 2>&1 &
# echo "Harbor: http://localhost:8081 (PID: $!)"

# Grafana
kubectl port-forward svc/monitoring-grafana -n monitoring 3000:80 > /tmp/grafana-pf.log 2>&1 &
echo "Grafana: http://localhost:3000 (PID: $!)"

# Prometheus
kubectl port-forward svc/prometheus-monitoring-kube-prometheus-prometheus -n monitoring 9090:9090 > /tmp/prometheus-pf.log 2>&1 &
echo "Prometheus: http://localhost:9090 (PID: $!)"

echo ""
echo "=== Port Forward 프로세스 확인 ==="
ps aux | grep "port-forward" | grep -v grep

echo ""
echo "종료하려면: ./scripts/stop-port-forwards.sh"
```

`scripts/stop-port-forwards.sh`:
```bash
#!/bin/bash
echo "=== Port Forward 프로세스 종료 ==="
pkill -f "kubectl port-forward"
echo "모든 Port Forward 프로세스가 종료되었습니다."
```

---

## 모니터링 및 관리

### ArgoCD 접근
- **URL**: https://localhost:8080
- **사용자**: admin
- **비밀번호**: `kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d`

### Harbor 접근
- **URL**: http://192.168.0.169:443 (또는 Port Forward 사용)
- **사용자**: admin
- **비밀번호**: Harbor12345

### Grafana 접근
- **URL**: http://localhost:3000
- **사용자**: admin
- **비밀번호**: `kubectl get secret monitoring-grafana -n monitoring -o jsonpath="{.data.admin-password}" | base64 -d`

### Prometheus 접근
- **URL**: http://localhost:9090

---

## 트러블슈팅

### Tekton Pipeline 실패

#### Docker 빌드 실패
```bash
# TaskRun 로그 확인
kubectl logs <taskrun-name> -c step-build

# Pod 상태 확인
kubectl get pods -l tekton.dev/taskRun=<taskrun-name>
```

#### Harbor 푸시 실패
```bash
# Push 단계 로그 확인
kubectl logs <taskrun-name> -c step-push

# Harbor 인증 확인
docker login 192.168.0.169:443 -u admin -p Harbor12345
```

### ArgoCD 동기화 실패

#### Repository 접근 오류
```bash
# Repository Secret 확인
kubectl get secrets -n argocd | grep repo

# Secret 재생성
kubectl delete secret github-repo-secret -n argocd
# 위의 Repository 등록 명령어 재실행
```

#### 경로 오류
```bash
# Application 상세 정보 확인
kubectl describe application error-archive-backend -n argocd

# Git 저장소 경로 확인
git ls-tree -r --name-only HEAD | grep k8s
```

### Completed Pod 정리
```bash
# 정리 스크립트 실행
./tekton/cleanup.sh

# 또는 수동 정리
kubectl delete pod -l tekton.dev/pipelineRun --field-selector=status.phase=Succeeded
```

---

## 유용한 명령어 모음

### Tekton
```bash
# Pipeline 목록
kubectl get pipelines

# PipelineRun 목록
kubectl get pipelineruns

# TaskRun 로그
kubectl logs <taskrun-name> -c <step-name>

# Pipeline 삭제
kubectl delete pipelinerun <name>
```

### ArgoCD
```bash
# Application 목록
kubectl get applications -n argocd

# Application 상세 정보
kubectl describe application <name> -n argocd

# 수동 동기화
argocd app sync <app-name>

# Application 삭제
kubectl delete application <name> -n argocd
```

### Kubernetes
```bash
# 배포 상태
kubectl get deployments -n error-archive

# Pod 로그
kubectl logs -f <pod-name> -n error-archive

# 리소스 상세 정보
kubectl describe deployment <name> -n error-archive
```

---

## 참고 자료

- [Tekton 공식 문서](https://tekton.dev/docs/)
- [ArgoCD 공식 문서](https://argo-cd.readthedocs.io/)
- [Harbor 공식 문서](https://goharbor.io/docs/)
- [Kubernetes 공식 문서](https://kubernetes.io/docs/)

---

## 변경 이력

- 2025-11-19: 초기 워크북 작성
  - Tekton CI 구축
  - ArgoCD CD 구축
  - 통합 CI/CD 워크플로우 구성

