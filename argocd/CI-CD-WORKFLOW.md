# Tekton + ArgoCD CI/CD 워크플로우 가이드

## 전체 워크플로우

### 1단계: 코드 변경 및 푸시

```bash
# 코드 수정 후
git add .
git commit -m "Update backend features"
git push origin main
```

### 2단계: CI 파이프라인 실행 (Tekton)

#### Backend 빌드
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

#### Frontend 빌드
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

### 3단계: Kubernetes 매니페스트 업데이트

```bash
# Backend 이미지 버전 업데이트
sed -i 's|192.168.0.169:443/project/error-archive-backend:.*|192.168.0.169:443/project/error-archive-backend:1.2|g' k8s/error-archive/backend-deployment.yaml

# Frontend 이미지 버전 업데이트
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.2|g' k8s/error-archive/frontend-deployment.yaml

# Git에 커밋 및 푸시
git add k8s/error-archive/
git commit -m "Deploy version 1.2"
git push origin main
```

### 4단계: ArgoCD 자동 배포

ArgoCD가 Git 저장소를 감시하고 있으며, 변경사항을 감지하면 자동으로 배포합니다.

수동 동기화가 필요한 경우:
```bash
argocd app sync error-archive-backend
argocd app sync error-archive-frontend
```

## 자동화 스크립트

### 전체 CI/CD 실행 스크립트

`deploy.sh` 예제:
```bash
#!/bin/bash
VERSION=${1:-latest}

echo "=== CI/CD 파이프라인 실행: $VERSION ==="

# 1. Backend CI
echo "1. Backend 빌드 중..."
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
    value: 192.168.0.169:443/project/error-archive-backend:$VERSION
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

# 2. Frontend CI
echo "2. Frontend 빌드 중..."
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
    value: 192.168.0.169:443/project/error-archive-frontend:$VERSION
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

# 3. 매니페스트 업데이트
echo "3. 매니페스트 업데이트 중..."
sed -i "s|192.168.0.169:443/project/error-archive-backend:.*|192.168.0.169:443/project/error-archive-backend:$VERSION|g" k8s/error-archive/backend-deployment.yaml
sed -i "s|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:$VERSION|g" k8s/error-archive/frontend-deployment.yaml

# 4. Git 푸시
echo "4. Git에 푸시 중..."
git add k8s/error-archive/
git commit -m "Deploy version $VERSION" || echo "변경사항 없음"
git push origin main

echo ""
echo "=== 완료 ==="
echo "ArgoCD가 자동으로 배포를 시작합니다."
echo "상태 확인: kubectl get applications -n argocd"
```

사용법:
```bash
chmod +x deploy.sh
./deploy.sh 1.2
```

