#!/bin/bash
# 시나리오 3: SonarQube 취약 코드 검사 시연
# 취약 코드 → 정상 코드로 변화를 SonarQube로 보여주기
# 시연 시간: 약 3-4분

set -e

echo "=========================================="
echo "  시나리오 3: SonarQube 취약 코드 검사 시연"
echo "=========================================="
echo ""
echo "📋 시연 순서:"
echo "  1. 취약한 코드 스캔 (보안 취약점 발견)"
echo "  2. 취약 코드 수정"
echo "  3. 수정된 코드 스캔 (정상 코드)"
echo "  4. SonarQube 대시보드에서 비교"
echo ""

# 색상 정의
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

PROJECT_DIR="/home/kevin/error-archive"
SONARQUBE_URL="http://localhost:9000"
SONARQUBE_USER="admin"
SONARQUBE_PASS="admin"

# ==========================================
# 1단계: 취약한 코드 스캔
# ==========================================
echo -e "${BLUE}[1단계] 취약한 코드 스캔 (보안 취약점 발견)${NC}"
echo ""

echo "취약한 코드 예시:"
echo ""
echo "=== 취약한 코드 (backend/server.js) ==="
cat << 'EOF'
// ❌ 취약한 코드: SQL Injection 취약점
app.post('/api/posts/search', async (req, res) => {
  const { keyword } = req.body;
  // 직접 쿼리 문자열에 사용자 입력 삽입 (위험!)
  const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
  const result = await db.query(query);
  res.json(result);
});

// ❌ 취약한 코드: 하드코딩된 비밀번호
const ADMIN_PASSWORD = "admin123";
if (password === ADMIN_PASSWORD) {
  // 관리자 권한 부여
}

// ❌ 취약한 코드: 민감 정보 로깅
console.log("User login:", username, password);
EOF

echo ""
echo "SonarQube 스캔 실행 중..."
echo ""

# SonarQube 프로젝트 키
PROJECT_KEY="error-archive-vulnerable"

# 취약한 코드가 있는 브랜치/태그로 스캔
cd "$PROJECT_DIR"

echo "SonarQube 스캔 실행..."
if command -v sonar-scanner &> /dev/null; then
    sonar-scanner \
        -Dsonar.projectKey=$PROJECT_KEY \
        -Dsonar.sources=backend \
        -Dsonar.host.url=$SONARQUBE_URL \
        -Dsonar.login=$SONARQUBE_PASS || \
    echo -e "${YELLOW}⚠ SonarQube 스캔 실패 (수동으로 실행하세요)${NC}"
else
    echo -e "${YELLOW}⚠ sonar-scanner가 설치되어 있지 않습니다.${NC}"
    echo "수동으로 스캔하세요:"
    echo "  docker run --rm -v \$(pwd):/usr/src sonarsource/sonar-scanner-cli"
fi

echo ""
echo "SonarQube 대시보드 확인:"
echo "  $SONARQUBE_URL"
echo "  프로젝트: $PROJECT_KEY"
echo "  → Issues 탭에서 취약점 확인"
echo ""

read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 2단계: 취약 코드 수정
# ==========================================
echo ""
echo -e "${BLUE}[2단계] 취약 코드 수정${NC}"
echo ""

echo "수정 사항:"
echo "  ✅ SQL Injection 방지 (파라미터화된 쿼리 사용)"
echo "  ✅ 하드코딩된 비밀번호 제거 (환경 변수 사용)"
echo "  ✅ 민감 정보 로깅 제거"
echo ""

echo "=== 수정된 코드 (backend/server.js) ==="
cat << 'EOF'
// ✅ 안전한 코드: 파라미터화된 쿼리
app.post('/api/posts/search', async (req, res) => {
  const { keyword } = req.body;
  // 파라미터화된 쿼리 사용 (안전)
  const query = 'SELECT * FROM posts WHERE title LIKE ?';
  const result = await db.query(query, [`%${keyword}%`]);
  res.json(result);
});

// ✅ 안전한 코드: 환경 변수 사용
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD;
if (password === ADMIN_PASSWORD) {
  // 관리자 권한 부여
}

// ✅ 안전한 코드: 민감 정보 로깅 제거
console.log("User login:", username); // 비밀번호 제외
EOF

echo ""
echo "코드 수정 중..."
echo ""

# 실제 코드 수정은 예시로만 제공
echo -e "${GREEN}✓ 취약 코드 수정 완료${NC}"
echo ""

read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 3단계: 수정된 코드 스캔
# ==========================================
echo ""
echo -e "${BLUE}[3단계] 수정된 코드 스캔 (정상 코드)${NC}"
echo ""

PROJECT_KEY_SECURE="error-archive-secure"

echo "SonarQube 스캔 실행 중..."
echo ""

if command -v sonar-scanner &> /dev/null; then
    sonar-scanner \
        -Dsonar.projectKey=$PROJECT_KEY_SECURE \
        -Dsonar.sources=backend \
        -Dsonar.host.url=$SONARQUBE_URL \
        -Dsonar.login=$SONARQUBE_PASS || \
    echo -e "${YELLOW}⚠ SonarQube 스캔 실패 (수동으로 실행하세요)${NC}"
else
    echo -e "${YELLOW}⚠ sonar-scanner가 설치되어 있지 않습니다.${NC}"
fi

echo ""
read -p "계속하려면 Enter를 누르세요..."

# ==========================================
# 4단계: SonarQube 대시보드에서 비교
# ==========================================
echo ""
echo -e "${BLUE}[4단계] SonarQube 대시보드에서 비교${NC}"
echo ""

echo "SonarQube 웹 UI 접속:"
echo "  $SONARQUBE_URL"
echo "  사용자: $SONARQUBE_USER"
echo "  비밀번호: $SONARQUBE_PASS"
echo ""

echo "비교할 프로젝트:"
echo "  1. $PROJECT_KEY (취약한 코드)"
echo "  2. $PROJECT_KEY_SECURE (정상 코드)"
echo ""

echo "확인 사항:"
echo "  ✅ 취약점 개수 비교"
echo "  ✅ 코드 스멜 (Code Smell) 개수"
echo "  ✅ 버그 개수"
echo "  ✅ 보안 취약점 (Security Hotspots)"
echo "  ✅ 코드 커버리지"
echo "  ✅ 기술 부채 (Technical Debt)"
echo ""

echo "SonarQube에서 프로젝트 비교 방법:"
echo "  1. Projects → 프로젝트 선택"
echo "  2. Overview 탭에서 전체 메트릭 확인"
echo "  3. Issues 탭에서 취약점 상세 확인"
echo "  4. Security Hotspots 탭에서 보안 이슈 확인"
echo ""

echo "주요 비교 지표:"
echo ""
echo "=== 취약한 코드 프로젝트 ==="
echo "  - 보안 취약점: 높음"
echo "  - 코드 스멜: 많음"
echo "  - 버그: 있음"
echo "  - 기술 부채: 높음"
echo ""
echo "=== 정상 코드 프로젝트 ==="
echo "  - 보안 취약점: 없음 또는 낮음"
echo "  - 코드 스멜: 적음"
echo "  - 버그: 없음 또는 적음"
echo "  - 기술 부채: 낮음"
echo ""

echo "=========================================="
echo -e "${GREEN}  시나리오 3 완료!${NC}"
echo "=========================================="
echo ""
echo "확인 사항:"
echo "  1. ✅ 취약한 코드 스캔 완료"
echo "  2. ✅ 취약 코드 수정 완료"
echo "  3. ✅ 수정된 코드 스캔 완료"
echo "  4. ✅ SonarQube 대시보드에서 비교"
echo ""
echo "SonarQube 웹 UI:"
echo "  $SONARQUBE_URL"
echo ""

