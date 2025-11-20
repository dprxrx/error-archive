# Harbor Trivy 취약점 해결 가이드

## 개요

Harbor의 Trivy 스캔에서 발견된 취약점을 해결하는 방법을 설명합니다.

## 취약점 해결 방법

### 1. 베이스 이미지 업데이트

#### 현재 이미지
- Backend: `node:18` → `node:18-alpine` (더 가볍고 취약점이 적음)
- Frontend: `nginx:latest` → `nginx:1.25-alpine` (특정 버전 + alpine)

#### Alpine 이미지 사용 이유
- 더 작은 이미지 크기
- 취약점이 적은 최소 패키지 세트
- 빠른 빌드 및 배포

### 2. 보안 강화 Dockerfile 적용

#### Backend 보안 강화
```dockerfile
FROM node:18-alpine
RUN apk update && apk upgrade
RUN adduser -S nodejs -u 1001
USER nodejs
```

#### Frontend 보안 강화
```dockerfile
FROM nginx:1.25-alpine
RUN apk update && apk upgrade
```

### 3. 패키지 업데이트

#### Backend (Node.js)
```dockerfile
# package.json 의존성 업데이트
RUN npm audit fix
RUN npm ci --only=production
```

#### Frontend (Nginx)
```dockerfile
# Alpine 패키지 업데이트
RUN apk update && apk upgrade
```

### 4. 비root 사용자 실행

```dockerfile
# 비root 사용자 생성 및 전환
RUN adduser -S nodejs -u 1001
USER nodejs
```

### 5. 불필요한 패키지 제거

```dockerfile
# 빌드 후 캐시 정리
RUN npm cache clean --force
RUN rm -rf /var/cache/apk/*
```

## 적용 방법

### 방법 1: 보안 강화 Dockerfile 사용

```bash
# Backend
cp backend/Dockerfile.secure backend/Dockerfile

# Frontend
cp frontend/Dockerfile.secure frontend/Dockerfile
```

### 방법 2: 기존 Dockerfile 수정

#### Backend Dockerfile 수정
```dockerfile
# 기존: FROM node:18
# 변경: FROM node:18-alpine

FROM node:18-alpine

# 보안 업데이트 추가
RUN apk update && apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# 비root 사용자 추가
RUN addgroup -g 1001 -S nodejs && \
    adduser -S nodejs -u 1001

USER nodejs

# npm ci 사용 (더 안전한 설치)
RUN npm ci --only=production && \
    npm cache clean --force
```

#### Frontend Dockerfile 수정
```dockerfile
# 기존: FROM nginx:latest
# 변경: FROM nginx:1.25-alpine

FROM nginx:1.25-alpine

# 보안 업데이트 추가
RUN apk update && apk upgrade && \
    rm -rf /var/cache/apk/*
```

## Harbor에서 취약점 관리

### 1. 취약점 무시 설정 (권장하지 않음)

Harbor UI에서:
1. 프로젝트 → 설정 → 스캐너
2. 취약점 정책 설정
3. 특정 취약점 무시 설정

### 2. 취약점 정책 설정

```yaml
# Harbor 프로젝트 정책
vulnerability_policy:
  severity: high  # high 이상만 차단
  ignore_cves:
    - CVE-2023-XXXXX  # 특정 CVE 무시
```

### 3. 스캔 결과 확인

```bash
# Harbor API를 통한 스캔 결과 확인
curl -u admin:Harbor12345 \
  "https://192.168.0.169:443/api/v2.0/projects/project/repositories/error-archive-backend/artifacts/latest/vulnerabilities"
```

## CI/CD 파이프라인에 보안 스캔 추가

### Tekton Task에 보안 스캔 추가

`tekton/tasks/security-scan-task.yaml`:
```yaml
apiVersion: tekton.dev/v1
kind: Task
metadata:
  name: trivy-scan
spec:
  params:
  - name: image
    type: string
  steps:
  - name: scan
    image: aquasec/trivy:latest
    script: |
      trivy image --exit-code 1 --severity HIGH,CRITICAL $(params.image)
```

### Pipeline에 보안 스캔 단계 추가

```yaml
- name: security-scan
  runAfter:
  - docker-build-and-push
  taskRef:
    name: trivy-scan
  params:
  - name: image
    value: $(params.docker-image)
```

## 취약점 해결 체크리스트

- [ ] 베이스 이미지를 Alpine 버전으로 변경
- [ ] 베이스 이미지를 최신 버전으로 업데이트
- [ ] 패키지 업데이트 (`apk update && apk upgrade`)
- [ ] npm 의존성 업데이트 (`npm audit fix`)
- [ ] 비root 사용자로 실행
- [ ] 불필요한 패키지 제거
- [ ] 빌드 캐시 정리
- [ ] Harbor 스캔 정책 설정

## 일반적인 취약점 해결

### Node.js 취약점
```bash
# npm audit 실행
npm audit

# 자동 수정
npm audit fix

# 강제 수정
npm audit fix --force

# 특정 패키지 업데이트
npm update <package-name>
```

### 시스템 패키지 취약점
```dockerfile
# Alpine
RUN apk update && apk upgrade

# Debian/Ubuntu
RUN apt-get update && apt-get upgrade -y
```

## 모니터링

### 정기적인 스캔
```bash
# 로컬에서 Trivy 실행
trivy image 192.168.0.169:443/project/error-archive-backend:latest

# 특정 심각도만 확인
trivy image --severity HIGH,CRITICAL <image>
```

### 자동화된 스캔
- Harbor에서 자동 스캔 활성화
- CI/CD 파이프라인에 스캔 단계 추가
- 취약점 발견 시 빌드 실패 설정

## 참고 자료

- [Trivy 공식 문서](https://aquasecurity.github.io/trivy/)
- [Harbor 보안 스캔 가이드](https://goharbor.io/docs/latest/administration/vulnerability-scanning/)
- [Docker 보안 모범 사례](https://docs.docker.com/develop/security-best-practices/)

