# SonarQube 인증 문제 해결 및 취약점 확인 방법

## 인증 오류 해결

### 문제: HTTP 401 오류
```
ERROR Failed to query server version: GET http://localhost:9000/api/v2/analysis/version failed with HTTP 401
```

### 해결 방법 1: SonarQube 토큰 생성 및 사용 (권장)

#### 1단계: SonarQube 웹 UI에서 토큰 생성
```bash
# SonarQube 접속
# http://localhost:9000
# 사용자: admin / 비밀번호: admin

# 토큰 생성 절차:
# 1. 우측 상단 프로필 아이콘 클릭
# 2. My Account 선택
# 3. Security 탭 클릭
# 4. Generate Token 버튼 클릭
# 5. 토큰 이름 입력 (예: scanner-token)
# 6. Expires in: No expiration 선택 (또는 원하는 기간)
# 7. Generate 버튼 클릭
# 8. 토큰 복사 (한 번만 표시됨! 반드시 저장)
```

#### 2단계: 토큰으로 스캔 실행
```bash
cd /home/kevin/error-archive

# 토큰을 환경 변수로 설정
export SONAR_TOKEN="your-generated-token-here"

# 스캔 실행
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  --network host \
  -e SONAR_TOKEN="$SONAR_TOKEN" \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.projectName="Error Archive (Vulnerable)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=$SONAR_TOKEN
```

### 해결 방법 2: 기본 비밀번호 사용 (토큰 생성 전)

```bash
cd /home/kevin/error-archive

# 기본 비밀번호 형식: admin:admin
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  --network host \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.projectName="Error Archive (Vulnerable)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin:admin
```

---

## 취약점 확인 방법

### 방법 1: SonarQube 웹 UI에서 확인

```bash
# SonarQube 접속
# http://localhost:9000
# 사용자: admin / 비밀번호: admin

# 확인 절차:
# 1. Projects 메뉴 클릭
# 2. error-archive-vulnerable 프로젝트 선택
# 3. Overview 탭: 전체 메트릭 확인
# 4. Issues 탭: 취약점 목록 확인
# 5. Security Hotspots 탭: 보안 이슈 확인
```

### 방법 2: SonarQube API로 취약점 확인

```bash
# 토큰 설정 (위에서 생성한 토큰 사용)
export SONAR_TOKEN="your-token-here"

# 전체 이슈 개수 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable" | \
  jq '.total'

# 취약점만 확인 (Vulnerability 타입)
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&types=VULNERABILITY" | \
  jq '.issues[] | {key: .key, severity: .severity, message: .message, file: .component}'

# 심각도별 취약점 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&severities=CRITICAL,BLOCKER" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line}'

# 보안 핫스팟 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/hotspots/search?projectKey=error-archive-vulnerable" | \
  jq '.hotspots[] | {key: .key, vulnerabilityProbability: .vulnerabilityProbability, message: .message, file: .component}'
```

### 방법 3: 상세 취약점 정보 확인

```bash
# 특정 파일의 취약점 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&componentQualifiers=FIL" | \
  jq '.components[] | {key: .key, name: .name}'

# 특정 취약점의 상세 정보
ISSUE_KEY="your-issue-key-here"
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?issues=$ISSUE_KEY" | \
  jq '.issues[0] | {key: .key, severity: .severity, message: .message, rule: .rule, component: .component, line: .line}'
```

### 방법 4: 프로젝트 메트릭 확인

```bash
# 프로젝트 전체 메트릭
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/measures/component?component=error-archive-vulnerable&metricKeys=bugs,vulnerabilities,code_smells,security_hotspots,coverage,duplicated_lines_density" | \
  jq '.component.measures[] | {metric: .metric, value: .value}'
```

---

## 취약점 종류별 확인

### SQL Injection 취약점 확인
```bash
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&rules=javascript:S5144" | \
  jq '.issues[] | {message: .message, file: .component, line: .line}'
```

### 하드코딩된 비밀번호 확인
```bash
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&rules=javascript:S2068" | \
  jq '.issues[] | {message: .message, file: .component, line: .line}'
```

### 민감 정보 로깅 확인
```bash
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&rules=javascript:S4792" | \
  jq '.issues[] | {message: .message, file: .component, line: .line}'
```

---

## 빠른 확인 스크립트

```bash
#!/bin/bash
# SonarQube 취약점 빠른 확인 스크립트

PROJECT_KEY="error-archive-vulnerable"
SONAR_TOKEN="${SONAR_TOKEN:-admin:admin}"
SONAR_URL="http://localhost:9000"

echo "=== SonarQube 취약점 확인 ==="
echo "프로젝트: $PROJECT_KEY"
echo ""

# 전체 이슈 개수
TOTAL=$(curl -s -u $SONAR_TOKEN: \
  "$SONAR_URL/api/issues/search?componentKeys=$PROJECT_KEY" | \
  jq -r '.total')
echo "전체 이슈: $TOTAL 개"

# 취약점 개수
VULN=$(curl -s -u $SONAR_TOKEN: \
  "$SONAR_URL/api/issues/search?componentKeys=$PROJECT_KEY&types=VULNERABILITY" | \
  jq -r '.total')
echo "취약점: $VULN 개"

# 버그 개수
BUGS=$(curl -s -u $SONAR_TOKEN: \
  "$SONAR_URL/api/issues/search?componentKeys=$PROJECT_KEY&types=BUG" | \
  jq -r '.total')
echo "버그: $BUGS 개"

# 코드 스멜 개수
SMELLS=$(curl -s -u $SONAR_TOKEN: \
  "$SONAR_URL/api/issues/search?componentKeys=$PROJECT_KEY&types=CODE_SMELL" | \
  jq -r '.total')
echo "코드 스멜: $SMELLS 개"

# 보안 핫스팟 개수
HOTSPOTS=$(curl -s -u $SONAR_TOKEN: \
  "$SONAR_URL/api/hotspots/search?projectKey=$PROJECT_KEY" | \
  jq -r '.hotspots | length')
echo "보안 핫스팟: $HOTSPOTS 개"

echo ""
echo "=== 상위 5개 취약점 ==="
curl -s -u $SONAR_TOKEN: \
  "$SONAR_URL/api/issues/search?componentKeys=$PROJECT_KEY&types=VULNERABILITY&ps=5" | \
  jq -r '.issues[] | "\(.severity) - \(.message) [\(.component):\(.line)]"'
```

---

## 문제 해결

### 토큰이 작동하지 않는 경우
```bash
# 토큰 형식 확인
# 올바른 형식: -Dsonar.login=your-token-here
# 잘못된 형식: -Dsonar.login=admin (비밀번호 없음)

# 환경 변수 확인
echo $SONAR_TOKEN

# 직접 토큰 사용
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  --network host \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=your-actual-token-here
```

### SonarQube가 시작되지 않은 경우
```bash
# Pod 상태 확인
kubectl get pods -n sonarqube

# Pod 로그 확인
kubectl logs -f deployment/sonarqube -n sonarqube

# 포트 포워딩 확인
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
```

### 스캔은 성공했지만 프로젝트가 보이지 않는 경우
```bash
# 프로젝트 목록 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/projects/search" | \
  jq '.components[] | {key: .key, name: .name}'

# 스캔 작업 상태 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/ce/activity?component=error-archive-vulnerable" | \
  jq '.tasks[] | {status: .status, submittedAt: .submittedAt}'
```

