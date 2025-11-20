# SonarQube 및 Trivy 설정 정리

## 1. SonarQube 코드 검사 기준

### 현재 설정 (`sonarqube-scan-task-simple.yaml`)

#### 검사 대상
- **언어**: JavaScript (JS)
- **소스 경로**: `frontend` 또는 `backend` 디렉토리
- **제외 경로**:
  - `**/node_modules/**`
  - `**/dist/**`
  - `**/build/**`

#### 검사 항목
SonarQube는 다음 항목들을 검사합니다:

1. **취약점 (Vulnerabilities)**
   - SQL Injection
   - 하드코딩된 비밀번호
   - XSS (Cross-Site Scripting)
   - 민감 정보 로깅
   - 보안 헤더 누락
   - 암호화 관련 문제

2. **버그 (Bugs)**
   - Null 포인터 역참조
   - 무한 루프
   - 타입 오류
   - 예외 처리 누락

3. **코드 스멜 (Code Smells)**
   - 중복 코드
   - 복잡한 함수
   - 긴 함수
   - 매직 넘버
   - 사용하지 않는 변수

4. **보안 핫스팟 (Security Hotspots)**
   - 잠재적 보안 문제
   - 권한 검사 누락
   - 암호화 강도

#### 검사 규칙 예시
- `javascript:S5144`: SQL Injection 취약점
- `javascript:S2068`: 하드코딩된 비밀번호
- `javascript:S4792`: 민감 정보 로깅
- `javascript:S1481`: 사용하지 않는 변수

#### 현재 설정 파일
```yaml
# sonar-project.properties (자동 생성)
sonar.projectKey=error-archive-frontend
sonar.projectName=Error Archive Frontend
sonar.sources=frontend
sonar.sourceEncoding=UTF-8
sonar.host.url=http://sonarqube.sonarqube:9000
sonar.token=<토큰>
sonar.exclusions=**/node_modules/**,**/dist/**,**/build/**
```

---

## 2. Trivy 취약점 스캔 - 프론트엔드 이미지 변경사항

### 이전 상태 (취약점 있음)

#### 이전 Dockerfile (추정)
```dockerfile
FROM nginx:latest
# 보안 업데이트 없음
# 비root 사용자 설정 없음
```

**문제점**:
- `nginx:latest` 사용 → 최신 버전이지만 취약점이 포함될 수 있음
- 보안 업데이트 미적용
- 비root 사용자로 실행하지 않음
- 불필요한 패키지 포함

### 현재 상태 (클린)

#### 현재 Dockerfile (`frontend/Dockerfile`)
```dockerfile
FROM nginx:1.25-alpine

# 보안 업데이트
RUN apk update && \
    apk upgrade && \
    apk add --no-cache dumb-init && \
    rm -rf /var/cache/apk/*

# nginx 설정 보안 강화
RUN sed -i 's/#user  nobody;/user nginx;/' /etc/nginx/nginx.conf && \
    chown -R nginx:nginx /var/www/html /var/cache/nginx /var/log/nginx /etc/nginx/conf.d && \
    chmod -R 755 /var/www/html

# dumb-init을 사용하여 시그널 처리 개선
ENTRYPOINT ["dumb-init", "--"]
CMD ["nginx", "-g", "daemon off;"]
```

### 주요 변경사항

#### 1. 베이스 이미지 변경
- **이전**: `nginx:latest` (Debian 기반, 큰 이미지 크기)
- **현재**: `nginx:1.25-alpine` (Alpine Linux 기반, 작은 이미지 크기)

**Alpine Linux 장점**:
- 최소 패키지 세트로 취약점이 적음
- 이미지 크기가 작음 (약 5MB vs 50MB)
- 빠른 빌드 및 배포

#### 2. 보안 업데이트 적용
```dockerfile
RUN apk update && apk upgrade
```
- 모든 패키지를 최신 보안 패치 버전으로 업데이트
- 알려진 CVE 취약점 해결

#### 3. 비root 사용자 실행
```dockerfile
RUN sed -i 's/#user  nobody;/user nginx;/' /etc/nginx/nginx.conf
```
- root 권한으로 실행하지 않음
- 공격 표면 감소

#### 4. 불필요한 패키지 제거
```dockerfile
rm -rf /var/cache/apk/*
```
- 빌드 캐시 제거
- 이미지 크기 감소

#### 5. dumb-init 추가
```dockerfile
apk add --no-cache dumb-init
ENTRYPOINT ["dumb-init", "--"]
```
- 시그널 처리 개선
- 좀비 프로세스 방지

### Trivy 스캔 결과 비교

#### 이전 이미지 (nginx:latest)
```
취약점 개수: 높음
- CRITICAL: 여러 개
- HIGH: 여러 개
- MEDIUM: 여러 개
```

#### 현재 이미지 (nginx:1.25-alpine + 보안 업데이트)
```
취약점 개수: 낮음 또는 없음
- CRITICAL: 0개
- HIGH: 0개 또는 매우 적음
- MEDIUM: 매우 적음
```

### 취약점 감소 이유

1. **Alpine Linux 사용**
   - 최소 패키지 세트
   - 취약점이 적은 베이스 이미지

2. **특정 버전 사용**
   - `nginx:1.25-alpine` (특정 버전)
   - `nginx:latest` 대신 안정적인 버전 사용

3. **보안 업데이트 적용**
   - `apk update && apk upgrade`
   - 알려진 취약점 패치 적용

4. **비root 사용자**
   - 권한 최소화
   - 공격 표면 감소

---

## 3. SonarQube vs Trivy 비교

| 항목 | SonarQube | Trivy |
|------|-----------|-------|
| **검사 대상** | 소스 코드 | 컨테이너 이미지 |
| **검사 내용** | 코드 품질, 버그, 취약점 | 이미지 내 패키지 취약점 (CVE) |
| **검사 시점** | CI 단계 (코드 스캔) | CI/CD 단계 (이미지 스캔) |
| **주요 검사** | SQL Injection, 하드코딩 비밀번호 등 | CVE 데이터베이스 기반 취약점 |
| **결과** | 코드 이슈 목록 | CVE 목록 및 심각도 |

### SonarQube가 검출하는 것
- 코드 레벨 취약점 (SQL Injection, XSS 등)
- 보안 코딩 규칙 위반
- 코드 품질 문제

### Trivy가 검출하는 것
- 이미지 내 설치된 패키지의 알려진 CVE
- 베이스 이미지 취약점
- 의존성 라이브러리 취약점

---

## 4. 현재 CI/CD 파이프라인에서의 역할

### Frontend 파이프라인 (`frontend-pipeline-ci`)

1. **Git Clone** → 소스 코드 가져오기
2. **SonarQube Scan** → 코드 품질 및 취약점 검사
3. **Docker Build** → 이미지 빌드 (`nginx:1.25-alpine` 사용)
4. **Docker Push** → Harbor에 푸시
5. **Harbor Trivy Scan** (자동) → 이미지 취약점 스캔

### 검사 흐름
```
소스 코드
  ↓
SonarQube (코드 검사)
  ↓
Docker Build (nginx:1.25-alpine)
  ↓
Harbor Push
  ↓
Trivy Scan (이미지 검사)
  ↓
배포
```

---

## 5. 확인 명령어

### SonarQube 이슈 확인
```bash
# 취약점 확인
curl -u <토큰>: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-frontend&types=VULNERABILITY" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line}'
```

### Trivy 스캔 확인
```bash
# 현재 이미지 스캔
trivy image 192.168.0.169:443/project/error-archive-frontend:latest \
  --severity HIGH,CRITICAL --format table

# 취약점 개수 확인
trivy image 192.168.0.169:443/project/error-archive-frontend:latest \
  --severity HIGH,CRITICAL --format json | \
  jq '[.Results[]?.Vulnerabilities[]?] | length'
```

---

## 요약

### SonarQube 검사 기준
- **언어**: JavaScript
- **검사 항목**: 취약점, 버그, 코드 스멜, 보안 핫스팟
- **제외**: node_modules, dist, build
- **주요 규칙**: SQL Injection, 하드코딩 비밀번호, XSS 등

### Trivy 취약점 감소 이유
1. **베이스 이미지**: `nginx:latest` → `nginx:1.25-alpine`
2. **보안 업데이트**: `apk update && apk upgrade` 추가
3. **비root 사용자**: nginx 사용자로 실행
4. **불필요한 패키지 제거**: 캐시 정리
5. **dumb-init 추가**: 시그널 처리 개선

이러한 변경으로 프론트엔드 이미지의 취약점이 크게 감소했습니다.

