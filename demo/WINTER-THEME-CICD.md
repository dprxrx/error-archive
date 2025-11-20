# 겨울 테마 CI/CD 명령어 (복붙용)

## 전체 과정 한 번에 복붙

```bash
# ==========================================
# 1단계: 소스코드 변경 (겨울 테마)
# ==========================================
cd /home/kevin/error-archive
cp demo/themes/winter/index.html frontend/index.html
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html

# ==========================================
# 2단계: Git 커밋 및 푸시
# ==========================================
git add frontend/index.html frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가"
git push origin main

# ==========================================
# 3단계: Tekton CI 파이프라인 실행
# ==========================================
IMAGE_TAG="winter-$(date +%Y%m%d-%H%M%S)"
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

# ==========================================
# 4단계: 빌드 완료 대기 (약 2-3분)
# ==========================================
echo "빌드 진행 중... (약 2-3분 소요)"
sleep 180

# 빌드 상태 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -3

# ==========================================
# 5단계: 빌드된 이미지 태그 확인
# ==========================================
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
BUILT_IMAGE=$(kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}')
echo "빌드된 이미지: $BUILT_IMAGE"

# ==========================================
# 6단계: 매니페스트 이미지 태그 업데이트
# ==========================================
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml
grep "image:" k8s/error-archive/frontend-deployment.yaml

# ==========================================
# 7단계: 매니페스트 Git 커밋 및 푸시
# ==========================================
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - winter"
git push origin main

# ==========================================
# 8단계: ArgoCD 동기화
# ==========================================
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 동기화 상태 확인
kubectl get application error-archive-frontend -n argocd

# ==========================================
# 9단계: 롤링 업데이트 확인
# ==========================================
kubectl rollout status deployment/frontend -n error-archive
kubectl get pods -n error-archive -l app=frontend
```

---

## 단계별 명령어 (수동 진행)

### 1단계: 소스코드 변경 (겨울 테마)
```bash
cd /home/kevin/error-archive
cp demo/themes/winter/index.html frontend/index.html
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html
```

### 2단계: Git 커밋 및 푸시
```bash
git add frontend/index.html frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가"
git push origin main
```

### 3단계: Tekton CI 파이프라인 실행
```bash
IMAGE_TAG="winter-$(date +%Y%m%d-%H%M%S)"
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

### 4단계: 빌드 완료 대기 (약 2-3분)
```bash
# 빌드 진행 상황 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -3

# 빌드 완료 확인 (STATUS가 True가 될 때까지 대기)
watch -n 5 'kubectl get pipelineruns -n default | grep frontend-winter-theme'
```

### 5단계: 빌드된 이미지 태그 확인
```bash
# PipelineRun 이름 확인
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')

# 빌드된 이미지 태그 확인
BUILT_IMAGE=$(kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}')
echo "빌드된 이미지: $BUILT_IMAGE"
```

### 6단계: 매니페스트 이미지 태그 업데이트
```bash
# 위에서 확인한 이미지 태그를 사용
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml

# 확인
grep "image:" k8s/error-archive/frontend-deployment.yaml
```

### 7단계: 매니페스트 Git 커밋 및 푸시
```bash
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - winter"
git push origin main
```

### 8단계: ArgoCD 동기화
```bash
# 방법 1: kubectl patch 사용 (권장)
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 동기화 상태 확인
kubectl get application error-archive-frontend -n argocd

# 상세 상태 확인 (오류 발생 시)
kubectl describe application error-archive-frontend -n argocd | grep -A 10 "Status:"
```

### 9단계: 롤링 업데이트 확인
```bash
# 롤링 업데이트 진행 상황 확인
kubectl rollout status deployment/frontend -n error-archive

# Pod 상태 확인
kubectl get pods -n error-archive -l app=frontend

# 배포된 이미지 확인
kubectl get deployment frontend -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""
```

---

## 상태 확인 명령어

### 현재 배포 상태
```bash
# 배포된 이미지
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
# 최근 PipelineRun
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -5

# 빌드 로그
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
kubectl logs -f pipelinerun/$PIPELINE_RUN_NAME -n default
```

---

## 문제 해결

### Invalid Name 오류 발생 시
```bash
# 매니페스트 파일에서 한글 태그 확인 및 수정
grep "image:" k8s/error-archive/frontend-deployment.yaml

# 한글이 포함된 경우 수정 (예: winter-태그 -> winter-20251120-170611)
sed -i "s|image:.*error-archive-frontend:.*|image: 192.168.0.169:443/project/error-archive-frontend:latest|" k8s/error-archive/frontend-deployment.yaml

# Git에 커밋 및 푸시
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "fix: 이미지 태그 수정 (한글 제거)"
git push origin main

# ArgoCD 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### ArgoCD 동기화 실패 시
```bash
# Application 상태 확인
kubectl get application error-archive-frontend -n argocd
kubectl describe application error-archive-frontend -n argocd

# ArgoCD 서버 로그 확인
kubectl logs -n argocd deployment/argocd-server --tail=50

# 수동 동기화 재시도
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

---

## 체크리스트

각 단계마다 다음을 확인하세요:

- [ ] **1단계**: 소스코드 파일이 올바르게 복사되었는지 확인
- [ ] **2단계**: `git push origin main` 실행 완료 확인
- [ ] **3단계**: PipelineRun이 생성되었는지 확인
- [ ] **4단계**: 빌드가 완료되었는지 확인 (STATUS: True)
- [ ] **5단계**: 빌드된 이미지 태그를 정확히 확인 (한글 없음)
- [ ] **6단계**: 매니페스트 파일이 올바르게 업데이트되었는지 확인 (한글 없음)
- [ ] **7단계**: `git push origin main` 실행 완료 확인
- [ ] **8단계**: ArgoCD 동기화 완료 확인 (SYNC STATUS: Synced)
- [ ] **9단계**: 롤링 업데이트 완료 확인 (Pod가 Running 상태)

