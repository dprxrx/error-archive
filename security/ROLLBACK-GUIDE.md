# 보안 정책 롤백 가이드

## 롤백 가능 여부

**네, 보안 정책을 적용한 후에도 이전 상황으로 롤백이 가능합니다.**

## 롤백 방법

### 방법 1: 스크립트 사용 (권장)

```bash
./security/rollback-security.sh
```

### 방법 2: 수동 롤백

#### 1단계: NetworkPolicy 제거
```bash
kubectl delete networkpolicies -n error-archive --all
```

#### 2단계: RBAC 제거
```bash
kubectl delete rolebindings -n error-archive --all
kubectl delete roles -n error-archive --all
```

#### 3단계: ServiceAccount 제거
```bash
kubectl delete serviceaccounts frontend-sa backend-sa -n error-archive
```

#### 4단계: 기존 Deployment로 롤백
```bash
# 기존 매니페스트로 롤백
kubectl apply -f k8s/error-archive/frontend-deployment.yaml
kubectl apply -f k8s/error-archive/backend-deployment.yaml
```

### 방법 3: 부분 롤백 (선택적)

#### NetworkPolicy만 제거
```bash
kubectl delete networkpolicies -n error-archive --all
```

#### RBAC만 제거
```bash
kubectl delete rolebindings -n error-archive --all
kubectl delete roles -n error-archive --all
```

#### Deployment만 롤백
```bash
kubectl apply -f k8s/error-archive/frontend-deployment.yaml
kubectl apply -f k8s/error-archive/backend-deployment.yaml
```

## 롤백 확인

### 현재 상태 확인
```bash
# NetworkPolicy 확인
kubectl get networkpolicies -n error-archive

# RBAC 확인
kubectl get roles,rolebindings -n error-archive

# ServiceAccount 확인
kubectl get serviceaccounts -n error-archive

# Deployment 확인
kubectl get deployments -n error-archive -o wide
```

### Pod 상태 확인
```bash
kubectl get pods -n error-archive
kubectl describe pod <pod-name> -n error-archive
```

## 주의사항

1. **NetworkPolicy 제거**: 네트워크 격리 정책이 제거되면 모든 트래픽이 허용됩니다.
2. **RBAC 제거**: 최소 권한 정책이 제거되면 Pod가 더 많은 권한을 가질 수 있습니다.
3. **ServiceAccount 제거**: Pod는 `default` ServiceAccount를 사용하게 됩니다.
4. **Deployment 롤백**: 보안 설정이 없는 기존 Deployment로 복구됩니다.

## 롤백 후 복구

롤백 후 다시 보안 정책을 적용하려면:

```bash
./security/apply-security.sh
```

## Git을 통한 롤백 (ArgoCD 사용 시)

ArgoCD를 사용하는 경우, Git에서 매니페스트를 롤백하면 자동으로 적용됩니다:

```bash
# Git에서 이전 버전으로 롤백
git checkout HEAD~1 -- k8s/error-archive/frontend-deployment.yaml
git checkout HEAD~1 -- k8s/error-archive/backend-deployment.yaml

# 커밋 및 푸시
git add k8s/error-archive/
git commit -m "Rollback to previous deployment"
git push origin main
```

ArgoCD가 자동으로 변경사항을 감지하여 롤백합니다.

