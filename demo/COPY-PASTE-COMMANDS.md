# 복붙용 명령어 모음 (수동 진행)

각 단계를 복사해서 실행하세요.

---

## 🍂 가을 테마 → ❄️ 겨울 테마 전환

### 1단계: 소스코드 변경
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
kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}'
echo ""
```

### 6단계: 매니페스트 이미지 태그 업데이트
```bash
# 위에서 확인한 이미지 태그를 사용 (예: winter-20251120-170611)
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:winter-20251120-170611"

# 매니페스트 업데이트
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

# 방법 2: ArgoCD CLI 사용 (CLI가 설치되어 있는 경우)
# argocd app sync error-archive-frontend --core

# 동기화 상태 확인
kubectl get application error-archive-frontend -n argocd

# 상세 상태 확인 (오류 발생 시)
kubectl describe application error-archive-frontend -n argocd | grep -A 10 "Status:"

# 자동 동기화 대기 (약 3분, syncPolicy.automated가 활성화되어 있으면 자동으로 동기화됨)
# watch -n 5 'kubectl get application error-archive-frontend -n argocd'
```

### 9단계: 롤링 업데이트 확인
```bash
kubectl rollout status deployment/frontend -n error-archive
kubectl get pods -n error-archive -l app=frontend
```

---

## ❄️ 겨울 테마 → 🍂 가을 테마 전환

### 1단계: 소스코드 변경
```bash
cd /home/kevin/error-archive
cp demo/themes/autumn/index.html frontend/index.html
cp demo/themes/autumn/list.html frontend/list.html
```

### 2단계: Git 커밋 및 푸시
```bash
git add frontend/index.html frontend/list.html
git commit -m "feat: 가을 테마 적용"
git push origin main
```

### 3단계: Tekton CI 파이프라인 실행
```bash
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
```

### 4단계: 빌드 완료 대기 (약 2-3분)
```bash
# 빌드 진행 상황 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -3

# 빌드 완료 확인 (STATUS가 True가 될 때까지 대기)
watch -n 5 'kubectl get pipelineruns -n default | grep frontend-autumn-theme'
```

### 5단계: 빌드된 이미지 태그 확인
```bash
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
BUILT_IMAGE=$(kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}')
echo "빌드된 이미지: $BUILT_IMAGE"
```

### 6단계: 매니페스트 이미지 태그 업데이트
```bash
# 위에서 확인한 이미지 태그를 사용 (예: autumn-20251120-172919)
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml

# 확인 (한글이 없어야 함!)
grep "image:" k8s/error-archive/frontend-deployment.yaml
```

### 7단계: 매니페스트 Git 커밋 및 푸시
```bash
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - autumn"
git push origin main
```

### 8단계: ArgoCD 동기화
```bash
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 동기화 상태 확인
kubectl get application error-archive-frontend -n argocd
```

### 9단계: 롤링 업데이트 확인
```bash
kubectl rollout status deployment/frontend -n error-archive
kubectl get pods -n error-archive -l app=frontend
```

---

## 🔍 상태 확인 명령어

### 현재 배포 상태 확인
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

## ⚠️ 중요 체크리스트

각 단계마다 다음을 확인하세요:

- [ ] **1단계**: 소스코드 파일이 올바르게 복사되었는지 확인
- [ ] **2단계**: `git push origin main` 실행 완료 확인
- [ ] **3단계**: PipelineRun이 생성되었는지 확인
- [ ] **4단계**: 빌드가 완료되었는지 확인 (STATUS: True)
- [ ] **5단계**: 빌드된 이미지 태그를 정확히 확인
- [ ] **6단계**: 매니페스트 파일이 올바르게 업데이트되었는지 확인
- [ ] **7단계**: `git push origin main` 실행 완료 확인
- [ ] **8단계**: ArgoCD 동기화 완료 확인
- [ ] **9단계**: 롤링 업데이트 완료 확인

---

## 🚨 문제 발생 시

### Git 푸시 실패
```bash
# 원격 저장소 확인
git remote -v

# 강제 푸시 (주의!)
git push origin main --force
```

### 빌드 실패
```bash
# PipelineRun 로그 확인
kubectl logs -f pipelinerun/<pipelinerun-name> -n default

# 실패한 TaskRun 확인
kubectl get taskruns -n default
kubectl describe taskrun <taskrun-name> -n default
```

### ArgoCD 동기화 실패
```bash
# Application 상태 확인
kubectl get application error-archive-frontend -n argocd
kubectl describe application error-archive-frontend -n argocd

# ArgoCD 서버 로그 확인
kubectl logs -n argocd deployment/argocd-server --tail=50

# 수동 동기화 재시도 (방법 1)
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 수동 동기화 재시도 (방법 2 - ArgoCD CLI)
# argocd app sync error-archive-frontend --core --force

# Git 저장소 연결 확인
kubectl get application error-archive-frontend -n argocd -o jsonpath='{.spec.source}' | jq .

# ArgoCD 서버 재시작 (최후의 수단)
# kubectl rollout restart deployment/argocd-server -n argocd
```

