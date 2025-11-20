# 겨울 테마 CI/CD 명령어 (복붙용)

## 전체 과정 (순서대로 복붙)

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
  - name: sonarqube-url
    value: http://sonarqube.sonarqube:9000
  - name: sonarqube-project-key
    value: error-archive-frontend
  - name: sonarqube-project-name
    value: Error Archive Frontend
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
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
BUILT_IMAGE=$(kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.spec.params[?(@.name=="docker-image")].value}')
echo "빌드된 이미지: $BUILT_IMAGE"
```

### 6단계: 매니페스트 이미지 태그 업데이트
```bash
# 위에서 확인한 이미지 태그를 사용 (예: winter-20251120-170611)
sed -i "s|image:.*error-archive-frontend:.*|image: $BUILT_IMAGE|" k8s/error-archive/frontend-deployment.yaml

# 확인 (한글이 없어야 함!)
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

## 빠른 확인 명령어

### 현재 상태 확인
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

---

## ⚠️ 중요 체크리스트

각 단계마다 확인:

- [ ] **2단계**: `git push origin main` 완료 확인
- [ ] **4단계**: 빌드 완료 확인 (STATUS: True)
- [ ] **5단계**: 빌드된 이미지 태그 확인 (한글 없음!)
- [ ] **6단계**: 매니페스트 확인 (한글 없음!)
- [ ] **7단계**: `git push origin main` 완료 확인
- [ ] **8단계**: ArgoCD 동기화 완료 (SYNC STATUS: Synced)
- [ ] **9단계**: 롤링 업데이트 완료 (Pod Running)

---

## 문제 발생 시

### Invalid Name 오류 (한글 태그)
```bash
# 매니페스트 확인
grep "image:" k8s/error-archive/frontend-deployment.yaml

# 한글이 있으면 수정 후 Git 푸시
sed -i "s|image:.*error-archive-frontend:.*|image: 192.168.0.169:443/project/error-archive-frontend:latest|" k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "fix: 이미지 태그 수정"
git push origin main
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### ArgoCD 동기화 실패
```bash
kubectl describe application error-archive-frontend -n argocd | grep -A 10 "Status:"
kubectl logs -n argocd deployment/argocd-server --tail=50
```

