# 수동 테마 전환 가이드 (단계별 명령어)

모든 단계를 수동으로 진행하는 명령어 모음입니다.

---

## 가을 테마 → 겨울 테마 전환

### 1단계: 소스코드 변경
```bash
cd /home/kevin/error-archive

# 겨울 테마 파일로 변경
cp demo/themes/winter/index.html frontend/index.html
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html
```

### 2단계: Git 커밋 및 푸시
```bash
# 변경사항 확인
git status

# Git에 추가
git add frontend/index.html frontend/list.html frontend/roulette.html

# 커밋
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가"

# 푸시 (중요!)
git push origin main
```

### 3단계: Tekton CI 파이프라인 실행
```bash
# 이미지 태그 생성
IMAGE_TAG="winter-$(date +%Y%m%d-%H%M%S)"
echo "이미지 태그: $IMAGE_TAG"

# PipelineRun 생성
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
    value: 192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG
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

### 4단계: 빌드 완료 대기 및 이미지 태그 확인
```bash
# PipelineRun 이름 확인
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
echo "PipelineRun: $PIPELINE_RUN_NAME"

# 빌드 진행 상황 확인
kubectl get pipelineruns -n default | grep frontend-winter-theme

# 빌드 완료 대기 (약 2-3분)
watch -n 5 'kubectl get pipelineruns -n default | grep frontend-winter-theme'

# 빌드 완료 후 이미지 태그 확인
kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}'
echo ""

# 또는 직접 확인
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:winter-20251120-170611"
echo "빌드된 이미지: $BUILT_IMAGE"
```

### 5단계: Kubernetes 매니페스트 이미지 태그 업데이트
```bash
# 빌드된 이미지 태그를 변수에 저장 (위에서 확인한 값 사용)
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:winter-20251120-170611"

# 매니페스트 파일 업데이트
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml

# 변경사항 확인
grep "image:" k8s/error-archive/frontend-deployment.yaml
```

### 6단계: 매니페스트 Git 커밋 및 푸시
```bash
# Git에 추가
git add k8s/error-archive/frontend-deployment.yaml

# 커밋
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - winter"

# 푸시 (중요!)
git push origin main
```

### 7단계: ArgoCD 동기화
```bash
# ArgoCD Application 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 동기화 상태 확인
kubectl get application error-archive-frontend -n argocd
```

### 8단계: 롤링 업데이트 확인
```bash
# Pod 상태 확인
kubectl get pods -n error-archive -l app=frontend -w

# 롤링 업데이트 완료 대기
kubectl rollout status deployment/frontend -n error-archive

# 배포된 이미지 확인
kubectl get deployment frontend -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
```

---

## 겨울 테마 → 가을 테마 전환

### 1단계: 소스코드 변경
```bash
cd /home/kevin/error-archive

# 가을 테마 파일로 변경
cp demo/themes/autumn/index.html frontend/index.html
cp demo/themes/autumn/list.html frontend/list.html
```

### 2단계: Git 커밋 및 푸시
```bash
# 변경사항 확인
git status

# Git에 추가
git add frontend/index.html frontend/list.html

# 커밋
git commit -m "feat: 가을 테마 적용"

# 푸시 (중요!)
git push origin main
```

### 3단계: Tekton CI 파이프라인 실행
```bash
# 이미지 태그 생성
IMAGE_TAG="autumn-$(date +%Y%m%d-%H%M%S)"
echo "이미지 태그: $IMAGE_TAG"

# PipelineRun 생성
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-autumn-theme-
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
    value: 192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG
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

### 4단계: 빌드 완료 대기 및 이미지 태그 확인
```bash
# PipelineRun 이름 확인
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
echo "PipelineRun: $PIPELINE_RUN_NAME"

# 빌드 진행 상황 확인
kubectl get pipelineruns -n default | grep frontend-autumn-theme

# 빌드 완료 대기 (약 2-3분)
watch -n 5 'kubectl get pipelineruns -n default | grep frontend-autumn-theme'

# 빌드 완료 후 이미지 태그 확인
kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}'
echo ""

# 또는 직접 확인
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:autumn-20251120-172919"
echo "빌드된 이미지: $BUILT_IMAGE"
```

### 5단계: Kubernetes 매니페스트 이미지 태그 업데이트
```bash
# 빌드된 이미지 태그를 변수에 저장 (위에서 확인한 값 사용)
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:autumn-20251120-172919"

# 매니페스트 파일 업데이트
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml

# 변경사항 확인
grep "image:" k8s/error-archive/frontend-deployment.yaml
```

### 6단계: 매니페스트 Git 커밋 및 푸시
```bash
# Git에 추가
git add k8s/error-archive/frontend-deployment.yaml

# 커밋
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - autumn"

# 푸시 (중요!)
git push origin main
```

### 7단계: ArgoCD 동기화
```bash
# ArgoCD Application 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 동기화 상태 확인
kubectl get application error-archive-frontend -n argocd
```

### 8단계: 롤링 업데이트 확인
```bash
# Pod 상태 확인
kubectl get pods -n error-archive -l app=frontend -w

# 롤링 업데이트 완료 대기
kubectl rollout status deployment/frontend -n error-archive

# 배포된 이미지 확인
kubectl get deployment frontend -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
```

---

## 빠른 확인 명령어

### 현재 상태 확인
```bash
# 현재 배포된 이미지
kubectl get deployment frontend -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

# Git 매니페스트 이미지
grep "image:" k8s/error-archive/frontend-deployment.yaml

# Pod 상태
kubectl get pods -n error-archive -l app=frontend

# ArgoCD 상태
kubectl get application error-archive-frontend -n argocd
```

### 빌드 상태 확인
```bash
# 최근 PipelineRun 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -5

# PipelineRun 상세 정보
kubectl get pipelinerun <pipelinerun-name> -n default -o yaml | grep -A 5 "docker-image"

# 빌드 로그 확인
kubectl logs -f pipelinerun/<pipelinerun-name> -n default
```

---

## 주의사항

1. **Git 푸시는 반드시 수동으로 진행**
   - 소스코드 변경 후 푸시
   - 매니페스트 변경 후 푸시
   - 각 단계마다 푸시 확인

2. **빌드 완료 후 이미지 태그 확인 필수**
   - PipelineRun에서 정확한 이미지 태그 확인
   - 매니페스트 업데이트 시 정확한 태그 사용

3. **각 단계 완료 후 다음 단계 진행**
   - Git 푸시 완료 확인
   - 빌드 완료 확인
   - 롤링 업데이트 완료 확인

---

## 문제 해결

### Git 푸시가 안 되는 경우
```bash
# 원격 저장소 확인
git remote -v

# 브랜치 확인
git branch

# 강제 푸시 (주의!)
git push origin main --force
```

### 빌드가 실패하는 경우
```bash
# PipelineRun 로그 확인
kubectl logs -f pipelinerun/<pipelinerun-name> -n default

# TaskRun 확인
kubectl get taskruns -n default
kubectl logs -f taskrun/<taskrun-name> -n default
```

### ArgoCD가 동기화되지 않는 경우
```bash
# Application 상태 확인
kubectl describe application error-archive-frontend -n argocd

# 수동 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

