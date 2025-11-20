# SonarQube 토큰 정리

## 토큰 정보

### 백엔드 토큰
```
sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b
```

### 프론트엔드 토큰
```
sqp_e0229117ea554f28429d3cd9b92d27b530097798
```

### 일반 토큰
```
sqa_b521b117e99b8c38e1b08d69d6ff2396e6f9cc99
```

## Kubernetes Secret

### 백엔드용 Secret
```bash
kubectl create secret generic sonarqube-token \
  --from-literal=token=sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b \
  -n default
```

### 프론트엔드용 Secret
```bash
kubectl create secret generic sonarqube-token-frontend \
  --from-literal=token=sqp_e0229117ea554f28429d3cd9b92d27b530097798 \
  -n default
```

## 사용 가이드

### 백엔드 스캔 시
```bash
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 또는 직접 사용
-Dsonar.login=sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b
```

### 프론트엔드 스캔 시
```bash
export SONAR_TOKEN="sqp_e0229117ea554f28429d3cd9b92d27b530097798"

# 또는 직접 사용
-Dsonar.login=sqp_e0229117ea554f28429d3cd9b92d27b530097798
```

### 일반 스캔 시
```bash
export SONAR_TOKEN="sqa_b521b117e99b8c38e1b08d69d6ff2396e6f9cc99"

# 또는 직접 사용
-Dsonar.login=sqa_b521b117e99b8c38e1b08d69d6ff2396e6f9cc99
```

## 파이프라인별 토큰 사용

### Backend 파이프라인
- Secret: `sonarqube-token`
- 토큰: `sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b`

### Frontend 파이프라인
- Secret: `sonarqube-token-frontend`
- 토큰: `sqp_e0229117ea554f28429d3cd9b92d27b530097798`

## 확인 명령어

```bash
# Secret 확인
kubectl get secret sonarqube-token sonarqube-token-frontend -n default

# Secret 값 확인 (base64 디코딩)
kubectl get secret sonarqube-token -n default -o jsonpath='{.data.token}' | base64 -d
echo ""

kubectl get secret sonarqube-token-frontend -n default -o jsonpath='{.data.token}' | base64 -d
echo ""
```

