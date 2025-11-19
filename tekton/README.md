# Tekton CI/CD 파이프라인

이 디렉토리는 Error Archive 프로젝트의 Tekton CI/CD 구성을 포함합니다.

## 구조

```
tekton/
├── manifests/          # Kubernetes 배포 매니페스트
│   ├── backend-deployment.yaml
│   └── frontend-deployment.yaml
├── tasks/              # Tekton Tasks
│   ├── git-clone-task.yaml
│   ├── docker-build-and-push-task.yaml
│   └── kubernetes-deploy-task.yaml
├── pipelines/          # Tekton Pipelines
│   ├── backend-pipeline.yaml
│   └── frontend-pipeline.yaml
└── pipelineruns/       # PipelineRun 예제
    ├── backend-pipelinerun-example.yaml
    └── frontend-pipelinerun-example.yaml
```

## 배포 순서

### 1. Tasks 배포
```bash
kubectl apply -f tekton/tasks/
```

### 2. Pipelines 배포
```bash
kubectl apply -f tekton/pipelines/
```

### 3. PipelineRun 실행

#### Backend 배포
```bash
kubectl create -f tekton/pipelineruns/backend-pipelinerun-example.yaml
```

#### Frontend 배포
```bash
kubectl create -f tekton/pipelineruns/frontend-pipelinerun-example.yaml
```

## 수동 PipelineRun 생성

### Backend
```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: backend-pipelinerun-
  namespace: default
spec:
  pipelineRef:
    name: backend-pipeline
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/dprxrx/error-archive-backend:latest
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

### Frontend
```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-pipelinerun-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/dprxrx/error-archive-frontend:latest
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

## 파이프라인 모니터링

### PipelineRun 상태 확인
```bash
kubectl get pipelineruns
```

### TaskRun 로그 확인
```bash
kubectl get taskruns
kubectl logs <taskrun-name> -c <step-name>
```

### PipelineRun 상세 정보
```bash
kubectl describe pipelinerun <pipelinerun-name>
```

## 주요 설정

- **Git Repository**: https://github.com/dprxrx/error-archive.git
- **Docker Registry**: 192.168.0.169:443
- **Harbor Project**: project
- **Namespace**: error-archive (배포 대상)
- **Backend Image**: 192.168.0.169:443/project/error-archive-backend:latest
- **Frontend Image**: 192.168.0.169:443/project/error-archive-frontend:latest

## Completed Pod 정리

Tekton은 기본적으로 Completed 상태의 Pod를 자동으로 삭제하지 않습니다. 오래된 Pod를 정리하려면:

### 자동 정리 스크립트 사용
```bash
# 24시간 이상 된 Completed Pod 정리
./tekton/cleanup.sh

# 모든 Completed Pod 강제 정리
./tekton/cleanup.sh --all

# 오래된 PipelineRun 삭제 (관련 Pod도 함께 삭제됨)
./tekton/cleanup.sh --pipelineruns
```

### 수동 정리
```bash
# 특정 PipelineRun 삭제 (관련 Pod도 함께 삭제됨)
kubectl delete pipelinerun <pipelinerun-name>

# Completed Pod 직접 삭제
kubectl delete pod -l tekton.dev/pipelineRun --field-selector=status.phase=Succeeded
kubectl delete pod -l tekton.dev/taskRun --field-selector=status.phase=Succeeded
```

## 주의사항

1. 기존 배포된 파드들은 `error-archive` 네임스페이스에 있으며, 이 파이프라인은 해당 네임스페이스의 Deployment를 업데이트합니다.
2. Docker registry 인증 정보는 필요에 따라 Secret으로 관리하는 것을 권장합니다.
3. PipelineRun은 `generateName`을 사용하여 자동으로 고유한 이름을 생성합니다.
4. Completed Pod는 로그 확인을 위해 유지되지만, 정기적으로 정리하는 것을 권장합니다.

