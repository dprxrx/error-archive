# Harbor Trivy 취약점 스캔 시나리오 (복붙용)

## 전체 과정 (순서대로 복붙)

### 1단계: Harbor 로그인
```bash
docker login 192.168.0.169:443 -u admin -p Harbor12345
```

### 2단계: 취약한 이미지 스캔 (높은 취약성)
```bash
# 기존 이미지가 있다면 스캔
trivy image 192.168.0.169:443/project/error-archive-frontend:latest \
  --severity HIGH,CRITICAL --format table

# 또는 Harbor에 있는 특정 이미지 스캔
# trivy image 192.168.0.169:443/project/error-archive-frontend:insecure \
#   --severity HIGH,CRITICAL --format table
```

### 3단계: 취약한 이미지 빌드 (비교용)
```bash
cd /home/kevin/error-archive/frontend

# 취약한 버전 이미지 빌드 (기본 Dockerfile 사용)
docker build -t 192.168.0.169:443/project/error-archive-frontend:insecure .

# Harbor에 푸시
docker push 192.168.0.169:443/project/error-archive-frontend:insecure

# 스캔 결과 확인
trivy image 192.168.0.169:443/project/error-archive-frontend:insecure \
  --severity HIGH,CRITICAL --format table
```

### 4단계: 보안 강화된 이미지 빌드
```bash
cd /home/kevin/error-archive/frontend

# 보안 강화된 Dockerfile로 빌드
docker build -f Dockerfile.secure \
  -t 192.168.0.169:443/project/error-archive-frontend:secure .

# Harbor에 푸시
docker push 192.168.0.169:443/project/error-archive-frontend:secure
```

### 5단계: 수정된 이미지 스캔 (낮은 취약성)
```bash
# 보안 강화된 이미지 스캔
trivy image 192.168.0.169:443/project/error-archive-frontend:secure \
  --severity HIGH,CRITICAL --format table
```

### 6단계: 취약점 개수 비교 (CLI)
```bash
# 취약한 이미지 취약점 개수
echo "=== 취약한 이미지 (insecure) ==="
trivy image 192.168.0.169:443/project/error-archive-frontend:insecure \
  --severity HIGH,CRITICAL --format json 2>/dev/null | \
  jq '[.Results[]?.Vulnerabilities[]?] | length' || echo "스캔 실패"

# 보안 강화된 이미지 취약점 개수
echo "=== 보안 강화된 이미지 (secure) ==="
trivy image 192.168.0.169:443/project/error-archive-frontend:secure \
  --severity HIGH,CRITICAL --format json 2>/dev/null | \
  jq '[.Results[]?.Vulnerabilities[]?] | length' || echo "스캔 실패"
```

### 7단계: Harbor 대시보드에서 비교
```bash
# Harbor 웹 UI 접속 정보
echo "Harbor 웹 UI: https://192.168.0.169:443"
echo "사용자: admin"
echo "비밀번호: Harbor12345"
echo ""
echo "비교 방법:"
echo "1. 프로젝트 → project 선택"
echo "2. error-archive-frontend 저장소 선택"
echo "3. insecure 태그 → 취약성 스캔 탭"
echo "4. secure 태그 → 취약성 스캔 탭"
echo "5. 취약점 개수 및 심각도 비교"
```

---

## 단계별 상세 명령어

### 1단계: Harbor 로그인 및 설정 확인
```bash
# Harbor 로그인
docker login 192.168.0.169:443 -u admin -p Harbor12345

# 로그인 확인
docker images | grep 192.168.0.169:443
```

### 2단계: 기존 이미지 확인 및 스캔
```bash
# Harbor에 있는 이미지 목록 확인 (Harbor UI에서 확인)
# 또는 로컬에 있는 이미지 확인
docker images | grep error-archive-frontend

# 기존 이미지 스캔 (예: latest 태그)
trivy image 192.168.0.169:443/project/error-archive-frontend:latest \
  --severity HIGH,CRITICAL --format table

# 전체 스캔 결과 (모든 심각도)
trivy image 192.168.0.169:443/project/error-archive-frontend:latest \
  --format table
```

### 3단계: 취약한 이미지 빌드 (비교용)
```bash
cd /home/kevin/error-archive/frontend

# 기본 Dockerfile로 빌드 (취약한 버전)
docker build -t 192.168.0.169:443/project/error-archive-frontend:insecure .

# 빌드 확인
docker images | grep insecure

# Harbor에 푸시
docker push 192.168.0.169:443/project/error-archive-frontend:insecure

# 스캔 실행
trivy image 192.168.0.169:443/project/error-archive-frontend:insecure \
  --severity HIGH,CRITICAL --format table
```

### 4단계: 보안 강화된 이미지 빌드
```bash
cd /home/kevin/error-archive/frontend

# 보안 강화된 Dockerfile 확인
cat Dockerfile.secure

# 보안 강화된 이미지 빌드
docker build -f Dockerfile.secure \
  -t 192.168.0.169:443/project/error-archive-frontend:secure .

# 빌드 확인
docker images | grep secure

# Harbor에 푸시
docker push 192.168.0.169:443/project/error-archive-frontend:secure
```

### 5단계: 수정된 이미지 스캔
```bash
# 보안 강화된 이미지 스캔
trivy image 192.168.0.169:443/project/error-archive-frontend:secure \
  --severity HIGH,CRITICAL --format table

# 전체 스캔 결과
trivy image 192.168.0.169:443/project/error-archive-frontend:secure \
  --format table
```

### 6단계: 취약점 개수 비교
```bash
# 취약한 이미지 취약점 개수 (HIGH, CRITICAL)
echo "=== 취약한 이미지 (insecure) ==="
INSECURE_COUNT=$(trivy image 192.168.0.169:443/project/error-archive-frontend:insecure \
  --severity HIGH,CRITICAL --format json 2>/dev/null | \
  jq '[.Results[]?.Vulnerabilities[]?] | length' 2>/dev/null || echo "0")
echo "HIGH/CRITICAL 취약점: $INSECURE_COUNT 개"

# 보안 강화된 이미지 취약점 개수 (HIGH, CRITICAL)
echo ""
echo "=== 보안 강화된 이미지 (secure) ==="
SECURE_COUNT=$(trivy image 192.168.0.169:443/project/error-archive-frontend:secure \
  --severity HIGH,CRITICAL --format json 2>/dev/null | \
  jq '[.Results[]?.Vulnerabilities[]?] | length' 2>/dev/null || echo "0")
echo "HIGH/CRITICAL 취약점: $SECURE_COUNT 개"

# 개선율 계산
echo ""
echo "=== 개선 결과 ==="
if [ "$INSECURE_COUNT" != "0" ] && [ "$SECURE_COUNT" != "0" ]; then
  REDUCTION=$((INSECURE_COUNT - SECURE_COUNT))
  PERCENTAGE=$(echo "scale=2; ($REDUCTION * 100) / $INSECURE_COUNT" | bc)
  echo "취약점 감소: $REDUCTION 개 ($PERCENTAGE%)"
fi
```

### 7단계: Harbor 대시보드 확인
```bash
# Harbor 접속 정보 출력
cat <<EOF
==========================================
Harbor 웹 UI 접속 정보
==========================================
URL: https://192.168.0.169:443
사용자: admin
비밀번호: Harbor12345

비교할 이미지:
1. error-archive-frontend:insecure (취약성 높음)
2. error-archive-frontend:secure (취약성 낮음)

확인 방법:
1. 프로젝트 → project 선택
2. error-archive-frontend 저장소 선택
3. insecure 태그 클릭 → 취약성 스캔 탭
4. secure 태그 클릭 → 취약성 스캔 탭
5. 취약점 개수 및 심각도 비교

확인 사항:
- 취약점 개수 비교
- 심각도별 분류 (CRITICAL, HIGH, MEDIUM, LOW)
- CVE 상세 정보
- 스캔 시간 및 결과
EOF
```

---

## 빠른 확인 명령어

### Trivy 설치 확인
```bash
# Trivy 설치 확인
trivy --version

# Trivy가 없으면 Docker로 실행
docker run --rm aquasec/trivy:latest --version
```

### Harbor 이미지 목록 확인
```bash
# Harbor에 로그인된 이미지 확인
docker images | grep 192.168.0.169:443

# 특정 이미지 정보 확인
docker inspect 192.168.0.169:443/project/error-archive-frontend:insecure
docker inspect 192.168.0.169:443/project/error-archive-frontend:secure
```

### 스캔 결과 JSON 형식으로 저장
```bash
# 취약한 이미지 스캔 결과 저장
trivy image 192.168.0.169:443/project/error-archive-frontend:insecure \
  --format json > insecure-scan.json

# 보안 강화된 이미지 스캔 결과 저장
trivy image 192.168.0.169:443/project/error-archive-frontend:secure \
  --format json > secure-scan.json

# 결과 비교
diff insecure-scan.json secure-scan.json
```

---

## ⚠️ 중요 체크리스트

각 단계마다 확인:

- [ ] **1단계**: Harbor 로그인 성공 확인
- [ ] **2단계**: 취약한 이미지 스캔 완료 (취약점 개수 기록)
- [ ] **3단계**: 취약한 이미지 빌드 및 푸시 완료
- [ ] **4단계**: 보안 강화된 이미지 빌드 및 푸시 완료
- [ ] **5단계**: 보안 강화된 이미지 스캔 완료 (취약점 개수 기록)
- [ ] **6단계**: 취약점 개수 비교 (감소 확인)
- [ ] **7단계**: Harbor 대시보드에서 시각적 비교

---

## 문제 발생 시

### Trivy가 설치되어 있지 않은 경우
```bash
# Docker로 Trivy 실행
docker run --rm \
  -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy:latest \
  image 192.168.0.169:443/project/error-archive-frontend:insecure \
  --severity HIGH,CRITICAL --format table
```

### Harbor 로그인 실패
```bash
# 인증서 오류 무시하고 로그인
echo "Harbor12345" | docker login 192.168.0.169:443 -u admin --password-stdin

# 또는 Docker daemon 설정 확인
cat /etc/docker/daemon.json
# insecure-registries에 192.168.0.169:443 추가 필요할 수 있음
```

### 이미지 Pull 실패
```bash
# Harbor 인증 확인
docker login 192.168.0.169:443 -u admin -p Harbor12345

# 이미지 존재 확인 (Harbor UI에서 확인)
# 또는 직접 pull 시도
docker pull 192.168.0.169:443/project/error-archive-frontend:insecure
```

### Dockerfile.secure가 없는 경우
```bash
# 보안 강화된 Dockerfile 생성
cd /home/kevin/error-archive/frontend

# 기존 Dockerfile을 기반으로 보안 강화
cat Dockerfile | sed 's/FROM nginx:latest/FROM nginx:1.25-alpine/' > Dockerfile.secure
echo "RUN apk update && apk upgrade && rm -rf /var/cache/apk/*" >> Dockerfile.secure
```

---

## 보안 강화 Dockerfile 주요 변경사항

### Frontend Dockerfile.secure
- ✅ 베이스 이미지: `nginx:latest` → `nginx:1.25-alpine`
- ✅ 패키지 업데이트: `apk update && apk upgrade`
- ✅ 캐시 정리: `rm -rf /var/cache/apk/*`
- ✅ 최소 권한 원칙 적용

### Backend Dockerfile.secure (참고)
- ✅ 베이스 이미지: `node:18` → `node:18-alpine`
- ✅ 비root 사용자: `USER nodejs`
- ✅ 패키지 업데이트: `apk update && apk upgrade`
- ✅ npm audit: `npm audit fix`

---

## Harbor에서 자동 스캔 활성화

Harbor UI에서:
1. 프로젝트 → project 선택
2. 설정 → 스캐너
3. Trivy 스캐너 활성화
4. 자동 스캔 활성화 (이미지 푸시 시 자동 스캔)

---

## 시연 시 강조 포인트

1. **취약점 개수 감소**: insecure vs secure 이미지 비교
2. **심각도별 분류**: CRITICAL, HIGH, MEDIUM, LOW
3. **CVE 상세 정보**: 각 취약점의 상세 설명
4. **보안 강화 방법**: Dockerfile 변경사항 설명
5. **Harbor 통합**: 자동 스캔 및 대시보드 시각화

