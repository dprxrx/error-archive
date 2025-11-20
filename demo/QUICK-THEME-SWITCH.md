# 테마 전환 빠른 명령어 (복붙용)

## 가을 테마 → 겨울 테마 전환

### 방법 1: 스크립트 사용 (권장)
```bash
# 1. 겨울 테마로 전환
./demo/scripts/switch-to-winter.sh

# 2. Git 푸시 (수동)
git push origin main

# 3. 빌드 완료 후 이미지 태그 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1
# PipelineRun의 params에서 docker-image 값 확인

# 4. 매니페스트 업데이트 및 배포
./demo/scripts/update-deployment-image.sh winter-20251120-170611
```

### 방법 2: 수동 전환
```bash
# 1. 소스코드 변경
cd /home/kevin/error-archive
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/index.html frontend/index.html
cp demo/themes/winter/roulette.html frontend/roulette.html

# 2. Git 커밋
git add frontend/list.html frontend/index.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용"
git push origin main

# 3. Tekton CI 실행
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

# 4. 빌드 완료 대기 (약 2-3분)
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1

# 5. 매니페스트 이미지 태그 업데이트
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG"
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - $IMAGE_TAG"
git push origin main

# 6. ArgoCD 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
kubectl rollout status deployment/frontend -n error-archive
```

---

## 겨울 테마 → 가을 테마 전환

### 방법 1: 스크립트 사용 (권장)
```bash
# 1. 가을 테마로 전환
./demo/scripts/switch-to-autumn.sh

# 2. Git 푸시 (수동)
git push origin main

# 3. 빌드 완료 후 이미지 태그 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1

# 4. 매니페스트 업데이트 및 배포
./demo/scripts/update-deployment-image.sh autumn-20251120-170611
```

### 방법 2: 수동 전환
```bash
# 1. 소스코드 변경
cd /home/kevin/error-archive
cp demo/themes/autumn/list.html frontend/list.html
cp demo/themes/autumn/index.html frontend/index.html

# 2. Git 커밋
git add frontend/list.html frontend/index.html
git commit -m "feat: 가을 테마 적용"
git push origin main

# 3. Tekton CI 실행
IMAGE_TAG="autumn-$(date +%Y%m%d-%H%M%S)"
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

# 4. 빌드 완료 대기 (약 2-3분)
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1

# 5. 매니페스트 이미지 태그 업데이트
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG"
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - $IMAGE_TAG"
git push origin main

# 6. ArgoCD 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
kubectl rollout status deployment/frontend -n error-archive
```

---

## 테마 검증

### 스크립트로 검증
```bash
./demo/scripts/verify-theme.sh
```

### 수동 검증
```bash
# 현재 배포된 이미지 확인
kubectl get deployment frontend -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}'

# Pod 상태 확인
kubectl get pods -n error-archive -l app=frontend

# ArgoCD 상태 확인
kubectl get application error-archive-frontend -n argocd
```

---

## 테마별 특징 확인

### 가을 테마 (autumn)
- ❌ 배너 없음
- ❌ 테마 전환 버튼 없음
- ❌ 룰렛 링크 없음

### 겨울 테마 (winter)
- ✅ 배너 표시
- ✅ 룰렛 링크 활성화
- ✅ 이벤트 페이지 접근 가능

---

## 문제 해결

### 이미지 태그 확인
```bash
# 빌드된 이미지 태그 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1
kubectl get pipelinerun <pipelinerun-name> -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}'
```

### 매니페스트 수동 업데이트
```bash
# 현재 이미지 확인
grep "image:" k8s/error-archive/frontend-deployment.yaml

# 이미지 태그 수동 변경
sed -i "s|image:.*|image: 192.168.0.169:443/project/error-archive-frontend:원하는태그|" k8s/error-archive/frontend-deployment.yaml
```

### ArgoCD 수동 동기화
```bash
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

