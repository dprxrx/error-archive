# SonarQube 빠른 시작 (토큰 포함)

## SonarQube 접속 정보

```
URL: http://localhost:9000
사용자: admin
비밀번호: Passpass123123#
```

## 토큰 정보

```bash
# 백엔드 스캔용 토큰
export SONAR_TOKEN_BACKEND="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 프론트엔드 스캔용 토큰
export SONAR_TOKEN_FRONTEND="sqp_e0229117ea554f28429d3cd9b92d27b530097798"

# 기본 토큰 (일반용)
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"
```

## 빠른 스캔 명령어

### 1단계: SonarQube 포트 포워딩
```bash
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
```

### 2단계: 백엔드 스캔 (취약한 코드)
```bash
cd /home/kevin/error-archive

docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  --network host \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.projectName="Error Archive (Vulnerable)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b
```

### 3단계: 취약점 확인
```bash
# 웹 UI에서 확인
# http://localhost:9000
# Projects → error-archive-vulnerable → Issues 탭

# 또는 API로 확인
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 취약점 목록
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&types=VULNERABILITY" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line}'
```

### 4단계: 수정된 코드 스캔
```bash
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  --network host \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-secure \
  -Dsonar.projectName="Error Archive (Secure)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b
```

### 5단계: 프론트엔드 스캔 (선택사항)
```bash
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  --network host \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-frontend \
  -Dsonar.projectName="Error Archive Frontend" \
  -Dsonar.sources=frontend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=sqp_e0229117ea554f28429d3cd9b92d27b530097798
```

## 취약점 확인 명령어

### 전체 이슈 개수
```bash
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable" | \
  jq '.total'
```

### 취약점만 확인
```bash
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&types=VULNERABILITY" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line}'
```

### 심각도별 확인
```bash
# CRITICAL, BLOCKER만
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&severities=CRITICAL,BLOCKER" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line}'
```

### 프로젝트 메트릭
```bash
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/measures/component?component=error-archive-vulnerable&metricKeys=bugs,vulnerabilities,code_smells,security_hotspots" | \
  jq '.component.measures[] | {metric: .metric, value: .value}'
```

