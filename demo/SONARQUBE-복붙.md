# SonarQube 취약 코드 검출 및 수정 시나리오 (복붙용)

## 전체 과정 (순서대로 복붙)

### 1단계: SonarQube 포트 포워딩
```bash
# SonarQube 포트 포워딩 (백그라운드)
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &

# 포트 포워딩 확인
sleep 3
curl -s http://localhost:9000/api/system/status | jq . || echo "SonarQube 접속 확인 중..."
```

### 2단계: 취약한 코드 스캔 (보안 취약점 발견)
```bash
cd /home/kevin/error-archive

# SonarQube 스캔 (취약한 코드)
# 방법 1: sonar-scanner 사용 (설치되어 있는 경우)
sonar-scanner \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.projectName="Error Archive (Vulnerable)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin

# 방법 2: Docker로 실행 (sonar-scanner가 없는 경우)
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.projectName="Error Archive (Vulnerable)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://host.docker.internal:9000 \
  -Dsonar.login=admin
```

### 4단계: SonarQube 대시보드에서 취약점 확인
```bash
# SonarQube 웹 UI 접속 정보
cat <<EOF
==========================================
SonarQube 웹 UI 접속 정보
==========================================
URL: http://localhost:9000
사용자: admin
비밀번호: Passpass123123#

프로젝트: error-archive-vulnerable
확인 사항:
- Issues 탭: 취약점 목록
- Security Hotspots: 보안 이슈
- Code Smells: 코드 스멜
- Bugs: 버그 개수
EOF

# API로 취약점 확인
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 취약점 목록 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&types=VULNERABILITY" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line}'
```

### 4단계: 취약 코드 수정
```bash
cd /home/kevin/error-archive/backend

# 취약한 코드 예시 확인 (예시 파일이 있다면)
# 실제 프로젝트의 취약한 코드를 수정

# 예시: SQL Injection 취약점 수정
# 기존: const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
# 수정: const query = 'SELECT * FROM posts WHERE title LIKE ?';
#       const result = await db.query(query, [`%${keyword}%`]);

# 예시: 하드코딩된 비밀번호 제거
# 기존: const ADMIN_PASSWORD = "admin123";
# 수정: const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;

# Git 커밋
git add backend/
git commit -m "fix: 보안 취약점 수정 (SQL Injection, 하드코딩 비밀번호 제거)"
git push origin main
```

### 6단계: 수정된 코드 스캔 (정상 코드)
```bash
cd /home/kevin/error-archive

# SonarQube 스캔 (수정된 코드)
# 방법 1: sonar-scanner 사용
sonar-scanner \
  -Dsonar.projectKey=error-archive-secure \
  -Dsonar.projectName="Error Archive (Secure)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin

# 방법 2: Docker로 실행
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-secure \
  -Dsonar.projectName="Error Archive (Secure)" \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://host.docker.internal:9000 \
  -Dsonar.login=admin
```

### 7단계: SonarQube 대시보드에서 비교 및 취약점 확인
```bash
# SonarQube 웹 UI 접속 정보
cat <<EOF
==========================================
SonarQube 프로젝트 비교
==========================================
URL: http://localhost:9000
사용자: admin
비밀번호: admin

비교할 프로젝트:
1. error-archive-vulnerable (취약한 코드)
2. error-archive-secure (정상 코드)

비교 방법:
1. Projects → 프로젝트 선택
2. Overview 탭에서 전체 메트릭 확인
3. Issues 탭에서 취약점 상세 확인
4. Security Hotspots 탭에서 보안 이슈 확인

비교 지표:
- 보안 취약점 개수
- 코드 스멜 (Code Smell) 개수
- 버그 개수
- 기술 부채 (Technical Debt)
- 코드 커버리지
EOF
```

---

## 단계별 상세 명령어

### 1단계: SonarQube 준비 및 접속
```bash
# SonarQube Pod 상태 확인
kubectl get pods -n sonarqube

# SonarQube 서비스 확인
kubectl get svc -n sonarqube

# 포트 포워딩 (백그라운드)
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 > /tmp/sonarqube-pf.log 2>&1 &

# 포트 포워딩 PID 확인
echo "포트 포워딩 PID: $!"

# SonarQube 접속 확인 (약 30초 대기 후)
sleep 30
curl -s http://localhost:9000/api/system/status | jq . || echo "SonarQube 시작 중..."

# 토큰 설정
export SONAR_TOKEN_BACKEND="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"
export SONAR_TOKEN_FRONTEND="sqp_e0229117ea554f28429d3cd9b92d27b530097798"
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"
```

### 2단계: 취약한 코드 스캔
```bash
cd /home/kevin/error-archive

# sonar-project.properties 파일 생성 (선택사항)
cat > sonar-project.properties <<EOF
sonar.projectKey=error-archive-vulnerable
sonar.projectName=Error Archive (Vulnerable)
sonar.sources=backend
sonar.sourceEncoding=UTF-8
sonar.host.url=http://localhost:9000
sonar.login=admin
sonar.exclusions=**/node_modules/**,**/dist/**,**/build/**
EOF

# SonarQube 스캔 실행
# 방법 1: 로컬 sonar-scanner 사용
if command -v sonar-scanner &> /dev/null; then
    sonar-scanner
else
    # 방법 2: Docker로 실행
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
fi
```

### 3단계: 취약점 확인
```bash
# SonarQube API로 취약점 개수 확인
curl -s -u admin:admin \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable&severities=CRITICAL,BLOCKER" | \
  jq '.issues | length'

# 전체 이슈 개수 확인
curl -s -u admin:admin \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-vulnerable" | \
  jq '.total'

# 보안 핫스팟 확인
curl -s -u admin:admin \
  "http://localhost:9000/api/hotspots/search?projectKey=error-archive-vulnerable" | \
  jq '.hotspots | length'
```

### 4단계: 취약 코드 수정 예시
```bash
cd /home/kevin/error-archive/backend

# 예시 1: SQL Injection 취약점 수정
# server.js 파일에서 수정
# 기존 코드:
#   const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
#   const result = await db.query(query);
# 
# 수정된 코드:
#   const query = 'SELECT * FROM posts WHERE title LIKE ?';
#   const result = await db.query(query, [`%${keyword}%`]);

# 예시 2: 하드코딩된 비밀번호 제거
# 기존 코드:
#   const ADMIN_PASSWORD = "admin123";
# 
# 수정된 코드:
#   const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';

# 예시 3: 민감 정보 로깅 제거
# 기존 코드:
#   console.log("User login:", username, password);
# 
# 수정된 코드:
#   console.log("User login:", username); // 비밀번호 제외

# 수정 후 Git 커밋
git add backend/
git commit -m "fix: 보안 취약점 수정"
git push origin main
```

### 5단계: 수정된 코드 스캔
```bash
cd /home/kevin/error-archive

# sonar-project.properties 파일 생성 (새 프로젝트)
cat > sonar-project.properties <<EOF
sonar.projectKey=error-archive-secure
sonar.projectName=Error Archive (Secure)
sonar.sources=backend
sonar.sourceEncoding=UTF-8
sonar.host.url=http://localhost:9000
sonar.login=admin
sonar.exclusions=**/node_modules/**,**/dist/**,**/build/**
EOF

# SonarQube 스캔 실행
if command -v sonar-scanner &> /dev/null; then
    sonar-scanner
else
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
fi
```

### 6단계: 프로젝트 비교
```bash
# 취약한 프로젝트 메트릭
echo "=== 취약한 프로젝트 (error-archive-vulnerable) ==="
curl -s -u admin:admin \
  "http://localhost:9000/api/measures/component?component=error-archive-vulnerable&metricKeys=bugs,vulnerabilities,code_smells,security_hotspots" | \
  jq '.component.measures'

# 수정된 프로젝트 메트릭
echo ""
echo "=== 수정된 프로젝트 (error-archive-secure) ==="
curl -s -u admin:admin \
  "http://localhost:9000/api/measures/component?component=error-archive-secure&metricKeys=bugs,vulnerabilities,code_smells,security_hotspots" | \
  jq '.component.measures'
```

---

## 빠른 확인 명령어

### SonarQube 상태 확인
```bash
# SonarQube Pod 상태
kubectl get pods -n sonarqube

# SonarQube 로그 확인
kubectl logs -f deployment/sonarqube -n sonarqube

# SonarQube 서비스 확인
kubectl get svc -n sonarqube

# SonarQube API 상태 확인
curl -s http://localhost:9000/api/system/status | jq .
```

### sonar-scanner 설치 확인
```bash
# sonar-scanner 설치 확인
sonar-scanner --version

# 설치되어 있지 않으면 Docker 사용
docker run --rm sonarsource/sonar-scanner-cli:latest --version
```

### 프로젝트 목록 확인
```bash
# SonarQube 프로젝트 목록
curl -s -u admin:admin \
  "http://localhost:9000/api/projects/search" | \
  jq '.components[] | {key: .key, name: .name}'
```

---

## ⚠️ 중요 체크리스트

각 단계마다 확인:

- [ ] **1단계**: SonarQube 포트 포워딩 성공 확인
- [ ] **2단계**: 취약한 코드 스캔 완료 (이슈 개수 기록)
- [ ] **3단계**: SonarQube 대시보드에서 취약점 확인
- [ ] **4단계**: 취약 코드 수정 및 Git 커밋 완료
- [ ] **5단계**: 수정된 코드 스캔 완료 (이슈 개수 기록)
- [ ] **6단계**: SonarQube 대시보드에서 비교 (이슈 개수 감소 확인)

---

## 문제 발생 시

### SonarQube 접속 실패
```bash
# Pod 상태 확인
kubectl get pods -n sonarqube

# Pod 로그 확인
kubectl logs -f deployment/sonarqube -n sonarqube

# 포트 포워딩 재시작
pkill -f "port-forward.*sonarqube"
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &
```

### sonar-scanner 실행 실패
```bash
# Docker로 실행 (권장)
docker run --rm \
  -v $(pwd):/usr/src \
  -w /usr/src \
  --network host \
  sonarsource/sonar-scanner-cli:latest \
  -Dsonar.projectKey=error-archive-vulnerable \
  -Dsonar.sources=backend \
  -Dsonar.host.url=http://localhost:9000 \
  -Dsonar.login=admin
```

### 인증 실패
```bash
# SonarQube 기본 비밀번호 확인
# 초기 비밀번호: admin / admin
# 첫 로그인 시 비밀번호 변경 요구

# 토큰 사용 (권장)
# SonarQube UI → My Account → Security → Generate Token
# 스캔 시 -Dsonar.login=YOUR_TOKEN 사용
```

### 스캔 결과가 나타나지 않는 경우
```bash
# 프로젝트 목록 확인
curl -s -u admin:admin \
  "http://localhost:9000/api/projects/search" | jq .

# 스캔 작업 상태 확인
curl -s -u admin:admin \
  "http://localhost:9000/api/ce/activity?component=error-archive-vulnerable" | jq .
```

---

## 취약 코드 예시

### SQL Injection 취약점
```javascript
// ❌ 취약한 코드
app.post('/api/posts/search', async (req, res) => {
  const { keyword } = req.body;
  const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
  const result = await db.query(query);
  res.json(result);
});

// ✅ 수정된 코드
app.post('/api/posts/search', async (req, res) => {
  const { keyword } = req.body;
  const query = 'SELECT * FROM posts WHERE title LIKE ?';
  const result = await db.query(query, [`%${keyword}%`]);
  res.json(result);
});
```

### 하드코딩된 비밀번호
```javascript
// ❌ 취약한 코드
const ADMIN_PASSWORD = "admin123";
if (password === ADMIN_PASSWORD) {
  // 관리자 권한 부여
}

// ✅ 수정된 코드
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';
if (password === ADMIN_PASSWORD) {
  // 관리자 권한 부여
}
```

### 민감 정보 로깅
```javascript
// ❌ 취약한 코드
console.log("User login:", username, password);

// ✅ 수정된 코드
console.log("User login:", username); // 비밀번호 제외
```

---

## 시연 시 강조 포인트

1. **취약점 개수 감소**: vulnerable vs secure 프로젝트 비교
2. **보안 이슈 해결**: SQL Injection, 하드코딩 비밀번호 등
3. **코드 품질 개선**: 코드 스멜, 버그 개수 감소
4. **기술 부채 감소**: Technical Debt 감소
5. **SonarQube 통합**: CI/CD 파이프라인 통합 가능

---

## SonarQube 대시보드 확인 항목

### Overview 탭
- 버그 (Bugs)
- 취약점 (Vulnerabilities)
- 코드 스멜 (Code Smells)
- 보안 핫스팟 (Security Hotspots)
- 커버리지 (Coverage)
- 기술 부채 (Technical Debt)

### Issues 탭
- 심각도별 이슈 (CRITICAL, MAJOR, MINOR, INFO)
- 이슈 유형 (Bug, Vulnerability, Code Smell)
- 이슈 상세 정보

### Security Hotspots 탭
- 보안 관련 코드 위치
- 보안 권장사항
- 보안 점수

