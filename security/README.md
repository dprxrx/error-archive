# 보안 강화 가이드

## 개요

이 디렉토리는 Kubernetes 보안 모범 사례를 적용한 설정을 포함합니다.

## 보안 정책

### 1. ServiceAccount (루트 사용 금지)
- 각 서비스별 전용 ServiceAccount 생성
- `default` ServiceAccount 사용 금지

### 2. RBAC (Role-Based Access Control)
- **최소 권한 원칙 (PoLP)** 적용
- 각 서비스에 필요한 최소한의 권한만 부여
- 불필요한 권한 제거

### 3. NetworkPolicy (네트워크 격리)
- Frontend: 외부 접근 허용, Backend로만 통신
- Backend: Frontend에서만 접근 허용
- DNS 쿼리만 허용

### 4. SecurityContext (컨테이너 보안)
- `runAsNonRoot: true` - 루트 사용자 금지
- `readOnlyRootFilesystem: true` - 읽기 전용 파일시스템
- `allowPrivilegeEscalation: false` - 권한 상승 금지
- `capabilities.drop: ALL` - 모든 권한 제거 후 필요한 것만 추가

## 적용 방법

### 전체 보안 정책 적용
```bash
./security/apply-security.sh
```

### 개별 적용
```bash
# ServiceAccount
kubectl apply -f security/serviceaccounts/

# RBAC
kubectl apply -f security/rbac/

# NetworkPolicy
kubectl apply -f security/network-policies/

# 보안 강화된 Deployment
kubectl apply -f k8s/error-archive/frontend-deployment-secure.yaml
kubectl apply -f k8s/error-archive/backend-deployment-secure.yaml
```

## 보안 설정 상세

### Frontend (Nginx)
- **사용자**: 101 (nginx 기본 사용자)
- **그룹**: 101
- **파일시스템**: 읽기 전용 (임시 디렉토리만 쓰기 가능)
- **권한**: NET_BIND_SERVICE만 허용

### Backend (Node.js)
- **사용자**: 1000 (Node.js 권장 사용자)
- **그룹**: 1000
- **파일시스템**: 쓰기 가능 (Node.js 특성상 필요)
- **권한**: 모든 권한 제거

## 확인 방법

### ServiceAccount 확인
```bash
kubectl get serviceaccounts -n error-archive
kubectl describe serviceaccount frontend-sa -n error-archive
```

### RBAC 확인
```bash
kubectl get roles,rolebindings -n error-archive
kubectl describe role frontend-role -n error-archive
```

### NetworkPolicy 확인
```bash
kubectl get networkpolicies -n error-archive
kubectl describe networkpolicy frontend-networkpolicy -n error-archive
```

### SecurityContext 확인
```bash
kubectl get pods -n error-archive -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.securityContext.runAsUser}{"\n"}{end}'
kubectl get pods -n error-archive -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.containers[0].securityContext.readOnlyRootFilesystem}{"\n"}{end}'
```

## 주의사항

### Frontend (Nginx)
- `readOnlyRootFilesystem: true` 사용 시 임시 디렉토리 마운트 필요
- `/tmp`, `/var/cache/nginx`, `/var/run` 디렉토리는 emptyDir로 마운트

### Backend (Node.js)
- Node.js는 파일 쓰기가 필요하므로 `readOnlyRootFilesystem: false`
- 대신 최소 권한 원칙 적용

## 트러블슈팅

### Pod가 시작되지 않는 경우
```bash
# Pod 이벤트 확인
kubectl describe pod <pod-name> -n error-archive

# 로그 확인
kubectl logs <pod-name> -n error-archive
```

### 권한 오류
```bash
# ServiceAccount 확인
kubectl get pods -n error-archive -o jsonpath='{range .items[*]}{.metadata.name}{"\t"}{.spec.serviceAccountName}{"\n"}{end}'
```

### 네트워크 연결 실패
```bash
# NetworkPolicy 확인
kubectl get networkpolicies -n error-archive
kubectl describe networkpolicy -n error-archive
```

## 참고 자료

- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [Pod Security Standards](https://kubernetes.io/docs/concepts/security/pod-security-standards/)
- [Network Policies](https://kubernetes.io/docs/concepts/services-networking/network-policies/)
- [RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)

