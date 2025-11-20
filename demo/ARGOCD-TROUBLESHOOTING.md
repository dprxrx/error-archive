# ArgoCD 동기화 문제 해결 가이드

## 일반적인 오류 및 해결 방법

### 1. 동기화 명령어 실행

#### 기본 동기화 명령어
```bash
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

#### 대안 방법들
```bash
# 방법 1: ArgoCD CLI 사용 (설치되어 있는 경우)
argocd app sync error-archive-frontend --core

# 방법 2: 자동 동기화 대기 (syncPolicy.automated가 활성화되어 있으면 자동으로 동기화됨)
# Git 푸시 후 약 3분 대기
watch -n 5 'kubectl get application error-archive-frontend -n argocd'
```

### 2. 상태 확인

#### Application 상태 확인
```bash
# 간단한 상태 확인
kubectl get application error-archive-frontend -n argocd

# 상세 상태 확인
kubectl describe application error-archive-frontend -n argocd

# JSON 형식으로 확인
kubectl get application error-archive-frontend -n argocd -o json | jq '.status'
```

#### 동기화 상태 확인
```bash
# SYNC STATUS 확인
kubectl get application error-archive-frontend -n argocd -o jsonpath='{.status.sync.status}'
echo ""

# HEALTH STATUS 확인
kubectl get application error-archive-frontend -n argocd -o jsonpath='{.status.health.status}'
echo ""

# 최근 동기화 시간 확인
kubectl get application error-archive-frontend -n argocd -o jsonpath='{.status.sync.finishedAt}'
echo ""
```

### 3. 오류 진단

#### ArgoCD 서버 로그 확인
```bash
# 최근 로그 확인
kubectl logs -n argocd deployment/argocd-server --tail=100

# 실시간 로그 확인
kubectl logs -f -n argocd deployment/argocd-server
```

#### Application 이벤트 확인
```bash
kubectl get events -n argocd --field-selector involvedObject.name=error-archive-frontend --sort-by='.lastTimestamp'
```

#### Git 저장소 연결 확인
```bash
# Application의 Git 설정 확인
kubectl get application error-archive-frontend -n argocd -o jsonpath='{.spec.source}' | jq .

# Git 저장소 접근 테스트
kubectl exec -n argocd deployment/argocd-repo-server -- sh -c "git ls-remote https://github.com/dprxrx/error-archive.git"
```

### 4. 일반적인 오류 해결

#### 오류: "application is out of sync"
```bash
# 수동 동기화 실행
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'

# 또는 강제 동기화
argocd app sync error-archive-frontend --core --force
```

#### 오류: "failed to get git repo"
```bash
# Git 저장소 URL 확인
kubectl get application error-archive-frontend -n argocd -o jsonpath='{.spec.source.repoURL}'
echo ""

# ArgoCD Repository 설정 확인
kubectl get secrets -n argocd | grep repo

# Git 저장소 접근 권한 확인
kubectl exec -n argocd deployment/argocd-repo-server -- sh -c "git ls-remote https://github.com/dprxrx/error-archive.git"
```

#### 오류: "image pull error"
```bash
# 배포된 이미지 확인
kubectl get deployment frontend -n error-archive -o jsonpath='{.spec.template.spec.containers[0].image}'
echo ""

# Pod 상태 확인
kubectl get pods -n error-archive -l app=frontend

# Pod 로그 확인
kubectl logs -n error-archive -l app=frontend --tail=50

# ImagePullSecret 확인
kubectl get secrets -n error-archive | grep pull
```

#### 오류: "application is progressing"
```bash
# 롤링 업데이트 상태 확인
kubectl rollout status deployment/frontend -n error-archive

# Pod 상태 확인
kubectl get pods -n error-archive -l app=frontend -o wide

# Deployment 이벤트 확인
kubectl describe deployment frontend -n error-archive | tail -20
```

### 5. ArgoCD 재시작

#### ArgoCD 서버 재시작
```bash
kubectl rollout restart deployment/argocd-server -n argocd
kubectl rollout status deployment/argocd-server -n argocd
```

#### ArgoCD Application Controller 재시작
```bash
kubectl rollout restart deployment/argocd-application-controller -n argocd
kubectl rollout status deployment/argocd-application-controller -n argocd
```

#### ArgoCD Repo Server 재시작
```bash
kubectl rollout restart deployment/argocd-repo-server -n argocd
kubectl rollout status deployment/argocd-repo-server -n argocd
```

### 6. 빠른 체크리스트

동기화가 안 될 때 다음을 순서대로 확인하세요:

- [ ] Git 푸시가 완료되었는지 확인
  ```bash
  git log --oneline -5
  ```

- [ ] Application이 존재하는지 확인
  ```bash
  kubectl get application error-archive-frontend -n argocd
  ```

- [ ] Git 저장소 URL이 올바른지 확인
  ```bash
  kubectl get application error-archive-frontend -n argocd -o jsonpath='{.spec.source.repoURL}'
  ```

- [ ] 매니페스트 파일 경로가 올바른지 확인
  ```bash
  kubectl get application error-archive-frontend -n argocd -o jsonpath='{.spec.source.path}'
  ```

- [ ] 동기화 정책이 활성화되어 있는지 확인
  ```bash
  kubectl get application error-archive-frontend -n argocd -o jsonpath='{.spec.syncPolicy.automated}'
  ```

- [ ] ArgoCD 서버가 정상 작동하는지 확인
  ```bash
  kubectl get pods -n argocd | grep argocd-server
  ```

### 7. 수동 동기화 강제 실행

모든 방법이 실패할 경우:

```bash
# 1. Application 삭제 후 재생성 (주의: 기존 리소스는 유지됨)
kubectl delete application error-archive-frontend -n argocd
kubectl apply -f argocd/frontend-application.yaml

# 2. 즉시 동기화
kubectl patch application error-archive-frontend -n argocd --type merge -p '{"operation":{"initiatedBy":{"username":"admin"},"sync":{"revision":"main"}}}'
```

### 8. 유용한 명령어 모음

```bash
# 모든 ArgoCD Application 상태 확인
kubectl get applications -n argocd

# ArgoCD Pod 상태 확인
kubectl get pods -n argocd

# ArgoCD 서비스 상태 확인
kubectl get svc -n argocd

# ArgoCD 웹 UI 접근
kubectl port-forward svc/argocd-server -n argocd 8080:443
# 브라우저에서 https://localhost:8080 접속
```
