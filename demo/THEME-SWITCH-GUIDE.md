# 테마 전환 가이드

가을 테마와 겨울 테마를 전환하는 방법을 안내합니다.

## 테마별 특징

### 가을 테마 (autumn)
- ❌ 겨울 이벤트 배너 없음
- ❌ 테마 전환 버튼 없음
- ❌ 룰렛 페이지 링크 없음
- ✅ 기본 UI만 표시

### 겨울 테마 (winter)
- ✅ 겨울 이벤트 배너 표시
- ✅ 룰렛 페이지 링크 활성화
- ✅ 이벤트 페이지 접근 가능

## 빠른 전환 명령어

### 가을 테마로 전환
```bash
# 1. 가을 테마로 전환 (소스코드 변경 + CI 빌드)
./demo/scripts/switch-to-autumn.sh

# 2. Git 푸시 (수동)
git push origin main

# 3. 이미지 태그 확인 후 매니페스트 업데이트
# 빌드된 이미지 태그를 확인 (예: autumn-20251120-170611)
./demo/scripts/update-deployment-image.sh autumn-20251120-170611
```

### 겨울 테마로 전환
```bash
# 1. 겨울 테마로 전환 (소스코드 변경 + CI 빌드)
./demo/scripts/switch-to-winter.sh

# 2. Git 푸시 (수동)
git push origin main

# 3. 이미지 태그 확인 후 매니페스트 업데이트
# 빌드된 이미지 태그를 확인 (예: winter-20251120-170611)
./demo/scripts/update-deployment-image.sh winter-20251120-170611
```

### 테마 검증
```bash
# 현재 배포된 테마 확인
./demo/scripts/verify-theme.sh
```

## 상세 단계별 가이드

### 가을 테마로 전환

#### 1단계: 소스코드 변경 및 Git 커밋
```bash
cd /home/kevin/error-archive

# 가을 테마 소스코드로 변경
cp demo/themes/autumn/list.html frontend/list.html

# Git 커밋
git add frontend/list.html
git commit -m "feat: 가을 테마 적용"
git push origin main
```

#### 2단계: Tekton CI 파이프라인 실행
```bash
# 이미지 태그 생성
IMAGE_TAG="autumn-$(date +%Y%m%d-%H%M%S)"
IMAGE_NAME="192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG"

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
    value: $IMAGE_NAME
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

# 빌드 완료 대기
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1
```

#### 3단계: 매니페스트 이미지 태그 업데이트
```bash
# 빌드된 이미지 태그 확인 (예: autumn-20251120-170611)
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:autumn-20251120-170611"

# 매니페스트 업데이트
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml

# Git 커밋 및 푸시
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - autumn"
git push origin main
```

#### 4단계: ArgoCD 동기화
```bash
# ArgoCD 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 롤링 업데이트 확인
kubectl rollout status deployment/frontend -n error-archive
```

### 겨울 테마로 전환

#### 1단계: 소스코드 변경 및 Git 커밋
```bash
cd /home/kevin/error-archive

# 겨울 테마 소스코드로 변경
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html

# Git 커밋
git add frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용 및 이벤트 배너 추가"
git push origin main
```

#### 2단계: Tekton CI 파이프라인 실행
```bash
# 이미지 태그 생성
IMAGE_TAG="winter-$(date +%Y%m%d-%H%M%S)"
IMAGE_NAME="192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG"

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
    value: $IMAGE_NAME
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

# 빌드 완료 대기
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1
```

#### 3단계: 매니페스트 이미지 태그 업데이트
```bash
# 빌드된 이미지 태그 확인 (예: winter-20251120-170611)
BUILT_IMAGE="192.168.0.169:443/project/error-archive-frontend:winter-20251120-170611"

# 매니페스트 업데이트
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml

# Git 커밋 및 푸시
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "chore: 프론트엔드 이미지 태그 업데이트 - winter"
git push origin main
```

#### 4단계: ArgoCD 동기화
```bash
# ArgoCD 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 롤링 업데이트 확인
kubectl rollout status deployment/frontend -n error-archive
```

## 검증 방법

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

### 웹 브라우저에서 확인

#### 가을 테마 확인 사항
- ✅ 상단에 배너가 없어야 함
- ✅ 오른쪽 상단에 테마 전환 버튼이 없어야 함
- ✅ 룰렛 페이지 링크가 없어야 함

#### 겨울 테마 확인 사항
- ✅ 상단에 겨울 이벤트 배너가 표시되어야 함
- ✅ 배너에 '참여하기 →' 링크가 있어야 함
- ✅ 룰렛 페이지 접근 가능해야 함

## 문제 해결

### 이미지 태그가 업데이트되지 않는 경우
```bash
# 매니페스트 파일 직접 확인
cat k8s/error-archive/frontend-deployment.yaml | grep image:

# 수동으로 이미지 태그 업데이트
sed -i "s|image:.*|image: 192.168.0.169:443/project/error-archive-frontend:원하는태그|" k8s/error-archive/frontend-deployment.yaml
```

### ArgoCD가 동기화되지 않는 경우
```bash
# ArgoCD Application 상태 확인
kubectl describe application error-archive-frontend -n argocd

# 수동 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### 롤링 업데이트가 완료되지 않는 경우
```bash
# Deployment 상태 확인
kubectl describe deployment frontend -n error-archive

# Pod 이벤트 확인
kubectl get events -n error-archive --sort-by='.lastTimestamp' | tail -20

# Pod 로그 확인
kubectl logs -n error-archive -l app=frontend --tail=50
```

## 스크립트 목록

| 스크립트 | 설명 |
|---------|------|
| `switch-to-autumn.sh` | 가을 테마로 전환 (소스코드 변경 + CI 빌드) |
| `switch-to-winter.sh` | 겨울 테마로 전환 (소스코드 변경 + CI 빌드) |
| `update-deployment-image.sh` | Deployment 이미지 태그 업데이트 및 ArgoCD 동기화 |
| `verify-theme.sh` | 현재 배포된 테마 검증 |

## 주의사항

1. **Git 푸시는 수동으로 진행**: 모든 스크립트는 Git 커밋만 수행하고, 푸시는 수동으로 진행해야 합니다.
2. **이미지 태그 확인**: CI 빌드 완료 후 생성된 이미지 태그를 정확히 확인해야 합니다.
3. **롤링 업데이트 대기**: ArgoCD 동기화 후 롤링 업데이트가 완료될 때까지 기다려야 합니다.
4. **웹 브라우저 캐시**: 테마 변경 후 브라우저 캐시를 지우거나 강력 새로고침(Ctrl+Shift+R)을 해야 할 수 있습니다.

