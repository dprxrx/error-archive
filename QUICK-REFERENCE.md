# CI/CD 빠른 참조 가이드

## 배포 확인 명령어

```bash
# 배포 상태 확인
kubectl get deployments -n error-archive -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,READY:.status.readyReplicas/..spec.replicas

# Pod 이미지 확인
kubectl get pods -n error-archive -l app=frontend -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].image}{"\n"}{end}'

# ArgoCD Application 상태
kubectl get applications -n argocd

# 실시간 모니터링
watch -n 2 'kubectl get deployments -n error-archive'
```

---

## 롤백 명령어 (복붙용)

### 방법 1: Git 매니페스트 롤백 (권장 - ArgoCD 자동 배포)

```bash
cd /home/kevin/proj/error-archive-1

# 매니페스트 롤백 (1.4 → 1.3)
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.3|g' k8s/error-archive/frontend-deployment.yaml

# Git 커밋 및 푸시
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Rollback frontend to version 1.3"
git push origin main
```

### 방법 2: 스크립트 사용

```bash
./scripts/rollback.sh 1.3
```

### 방법 3: kubectl 직접 롤백 (긴급)

```bash
# 이미지 직접 변경
kubectl set image deployment/frontend nginx=192.168.0.169:443/project/error-archive-frontend:1.3 -n error-archive

# 롤아웃 상태 확인
kubectl rollout status deployment/frontend -n error-archive

# 롤아웃 히스토리 확인
kubectl rollout history deployment/frontend -n error-archive

# 특정 리비전으로 롤백
kubectl rollout undo deployment/frontend -n error-archive
```

---

## 전체 CI/CD 시연 (한 번에)

### 배포
```bash
./scripts/cicd-demo.sh
```

### 롤백
```bash
./scripts/rollback.sh 1.3
```

---

## 웹사이트 접속 정보

```bash
# Frontend Service 확인
kubectl get svc -n error-archive frontend

# NodePort로 접속
# http://<노드IP>:32361
```

---

## 문제 해결

### 배포가 진행되지 않는 경우
```bash
# ArgoCD Application 상세 정보
kubectl describe application error-archive-frontend -n argocd

# Pod 이벤트 확인
kubectl describe pod -n error-archive -l app=frontend | grep Events -A 10

# Pod 로그 확인
kubectl logs -f -n error-archive -l app=frontend
```

### 이미지 Pull 실패
```bash
# ImagePullSecret 확인
kubectl get deployment frontend -n error-archive -o yaml | grep imagePullSecrets

# Harbor 인증 확인
docker login 192.168.0.169:443 -u admin -p Harbor12345
```

