# ArgoCD + Tekton CI/CD 구조

이 디렉토리는 Tekton(CI)과 ArgoCD(CD)를 연동한 GitOps CI/CD 구성을 포함합니다.

## 아키텍처

```
┌─────────────────┐
│   Git Push      │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Tekton (CI)   │  ← 이미지 빌드 및 Harbor 푸시
│  - git-clone    │
│  - build        │
│  - push         │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Harbor Registry│  ← 이미지 저장
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Git Repository │  ← 매니페스트 업데이트 (수동 또는 자동)
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  ArgoCD (CD)    │  ← GitOps로 자동 배포
│  - 감시          │
│  - 동기화        │
│  - 배포          │
└─────────────────┘
```

## 구조

```
.
├── argocd/
│   ├── backend-application.yaml    # Backend ArgoCD Application
│   ├── frontend-application.yaml   # Frontend ArgoCD Application
│   ├── install-argocd.sh           # ArgoCD 설치 스크립트
│   └── README.md                    # 이 파일
├── k8s/
│   └── error-archive/
│       ├── namespace.yaml           # Namespace 정의
│       ├── backend-deployment.yaml  # Backend Deployment/Service
│       └── frontend-deployment.yaml # Frontend Deployment/Service
└── tekton/
    └── pipelines/
        ├── backend-pipeline-ci.yaml  # Backend CI Pipeline (배포 제외)
        └── frontend-pipeline-ci.yaml # Frontend CI Pipeline (배포 제외)
```

## 설치 및 설정

### 1. ArgoCD 설치

```bash
./argocd/install-argocd.sh
```

또는 수동 설치:
```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. ArgoCD 접근

#### Port Forward 사용
```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```
브라우저에서 `https://localhost:8080` 접속

#### 초기 admin 비밀번호 확인
```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
echo ""
```

### 3. Git 저장소에 Kubernetes 매니페스트 추가

```bash
# k8s/ 디렉토리를 Git에 추가
git add k8s/
git commit -m "Add Kubernetes manifests for ArgoCD"
git push origin main
```

### 4. ArgoCD Application 배포

```bash
# Backend Application
kubectl apply -f argocd/backend-application.yaml

# Frontend Application
kubectl apply -f argocd/frontend-application.yaml
```

### 5. Tekton CI Pipeline 배포

```bash
# CI 전용 Pipeline 배포
kubectl apply -f tekton/pipelines/backend-pipeline-ci.yaml
kubectl apply -f tekton/pipelines/frontend-pipeline-ci.yaml
```

## 사용 방법

### CI 파이프라인 실행 (Tekton)

#### Backend 빌드 및 푸시
```bash
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
    value: 192.168.0.169:443/project/error-archive-backend:1.2
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

#### Frontend 빌드 및 푸시
```bash
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
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:1.2
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

### CD 배포 (ArgoCD)

#### 방법 1: Git 매니페스트 업데이트 (권장)

1. `k8s/error-archive/backend-deployment.yaml`에서 이미지 태그 수정
2. Git에 커밋 및 푸시
3. ArgoCD가 자동으로 감지하여 배포

```bash
# 예시: 이미지 버전 업데이트
sed -i 's|:1.1|:1.2|g' k8s/error-archive/backend-deployment.yaml
git add k8s/error-archive/backend-deployment.yaml
git commit -m "Update backend image to 1.2"
git push origin main
```

#### 방법 2: ArgoCD CLI 사용

```bash
# ArgoCD CLI 설치
curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
chmod +x /usr/local/bin/argocd

# 로그인
argocd login localhost:8080

# 수동 동기화
argocd app sync error-archive-backend
argocd app sync error-archive-frontend
```

## 모니터링

### ArgoCD Application 상태 확인

```bash
# Application 목록
kubectl get applications -n argocd

# 상세 정보
kubectl describe application error-archive-backend -n argocd
kubectl describe application error-archive-frontend -n argocd

# ArgoCD CLI 사용
argocd app list
argocd app get error-archive-backend
```

### Tekton Pipeline 상태 확인

```bash
kubectl get pipelineruns
kubectl get taskruns
```

## 주요 설정

- **Git Repository**: https://github.com/dprxrx/error-archive.git
- **Docker Registry**: 192.168.0.169:443
- **Harbor Project**: project
- **Namespace**: error-archive
- **ArgoCD Namespace**: argocd

## 워크플로우

1. **개발자가 코드 변경 및 푸시**
   ```bash
   git add .
   git commit -m "Update backend code"
   git push origin main
   ```

2. **Tekton CI Pipeline 실행** (수동 또는 Trigger)
   - Git에서 소스 코드 클론
   - Docker 이미지 빌드
   - Harbor에 이미지 푸시

3. **Kubernetes 매니페스트 업데이트**
   ```bash
   # k8s/error-archive/backend-deployment.yaml에서 이미지 태그 변경
   sed -i 's|:1.1|:1.2|g' k8s/error-archive/backend-deployment.yaml
   git add k8s/error-archive/backend-deployment.yaml
   git commit -m "Deploy backend:1.2"
   git push origin main
   ```

4. **ArgoCD 자동 배포**
   - Git 저장소 감시
   - 변경사항 감지
   - 자동으로 Kubernetes에 배포

## 장점

1. **관심사 분리**: CI(Tekton)와 CD(ArgoCD) 분리
2. **GitOps**: 모든 배포 상태가 Git에 저장되어 추적 가능
3. **자동화**: Git 푸시만으로 자동 배포
4. **롤백 용이**: Git 히스토리를 통한 간단한 롤백
5. **멀티 환경 지원**: 동일한 구조로 여러 환경 관리 가능

## 트러블슈팅

### ArgoCD가 변경사항을 감지하지 않는 경우

```bash
# 수동 동기화
argocd app sync error-archive-backend --force

# 또는 kubectl 사용
kubectl patch application error-archive-backend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### 이미지 Pull 실패

Harbor 인증이 필요한 경우 ImagePullSecret 생성:
```bash
kubectl create secret docker-registry harbor-secret \
  --docker-server=192.168.0.169:443 \
  --docker-username=admin \
  --docker-password=Harbor12345 \
  -n error-archive
```

Deployment에 추가:
```yaml
spec:
  template:
    spec:
      imagePullSecrets:
      - name: harbor-secret
```

