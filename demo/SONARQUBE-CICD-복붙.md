# SonarQube CI/CD 통합 시나리오 (복붙용)

## 시나리오 개요

1. **취약한 코드 생성** → SonarQube가 검출할 취약점 포함
2. **CI/CD 파이프라인 실행** → SonarQube 스캔 단계에서 실패
3. **취약점 확인** → 어떤 코드가 문제인지 확인
4. **코드 수정** → 취약점 해결
5. **CI/CD 재실행** → 정상적으로 배포 완료

---

## 사전 준비

### 1단계: SonarQube 토큰 Secret 생성
```bash
# SonarQube 토큰을 Kubernetes Secret에 저장
kubectl create secret generic sonarqube-token \
  --from-literal=token=sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b \
  --namespace=default \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 2단계: SonarQube Task 배포
```bash
# SonarQube 스캔 Task 배포
kubectl apply -f sonarqube/tasks/sonarqube-scan-task.yaml
```

### 3단계: Backend 파이프라인에 SonarQube 통합
```bash
# Backend 파이프라인에 SonarQube 스캔 단계 추가
# tekton/pipelines/backend-pipeline-ci.yaml 파일 수정 필요
```

---

## 시나리오 실행

### 1단계: 취약한 코드 생성

```bash
cd /home/kevin/error-archive/backend

# 취약한 코드 파일 생성 (예시)
cat > vulnerable-code.js << 'EOF'
// ===============================
// ❌ 취약한 코드 예시
// ===============================

// 1. SQL Injection 취약점
app.post('/api/posts/search', async (req, res) => {
  const { keyword } = req.body;
  // 직접 쿼리 문자열에 사용자 입력 삽입 (위험!)
  const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
  const result = await db.query(query);
  res.json(result);
});

// 2. 하드코딩된 비밀번호
const ADMIN_PASSWORD = "admin123";
if (password === ADMIN_PASSWORD) {
  // 관리자 권한 부여
}

// 3. 민감 정보 로깅
console.log("User login:", username, password);

// 4. MongoDB 연결 문자열에 하드코딩된 비밀번호
mongoose.connect("mongodb+srv://user:password123@cluster.mongodb.net/db");
EOF

# 실제 server.js에 취약한 코드 추가 (임시)
# 주의: 실제 프로덕션 코드에는 사용하지 마세요!
cat >> server.js << 'EOF'

// ===============================
// ❌ 취약한 코드 (SonarQube 테스트용)
// ===============================

// SQL Injection 취약점 예시
app.post('/api/test/search', async (req, res) => {
  const { keyword } = req.body;
  // 직접 쿼리 문자열에 사용자 입력 삽입 (위험!)
  const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
  // 실제로는 MongoDB를 사용하지만, SonarQube가 패턴을 감지함
  res.json({ message: "This is vulnerable code for testing" });
});

// 하드코딩된 비밀번호
const TEST_ADMIN_PASSWORD = "admin123";
app.post('/api/test/admin', async (req, res) => {
  const { password } = req.body;
  if (password === TEST_ADMIN_PASSWORD) {
    res.json({ success: true, message: "Admin access granted" });
  } else {
    res.json({ success: false, message: "Invalid password" });
  }
});
EOF

# Git 커밋 및 푸시
# 현재 backend 디렉토리에 있는 경우
git commit -m "test: 취약한 코드 추가 (SonarQube 테스트용)"
git push origin main

# 또는 프로젝트 루트에서
cd /home/kevin/error-archive
git add backend/server.js
git commit -m "test: 취약한 코드 추가 (SonarQube 테스트용)"
git push origin main
```

### 2단계: Backend 파이프라인에 SonarQube 통합 확인

```bash
# Backend 파이프라인 확인
kubectl get pipeline backend-pipeline-ci -n default -o yaml | grep -A 10 sonarqube

# SonarQube 스캔이 포함되어 있지 않다면 추가 필요
# tekton/pipelines/backend-pipeline-ci.yaml 파일 수정
```

### 4단계: CI/CD 파이프라인 실행 (취약한 코드)

```bash
# Backend CI 파이프라인 실행 (SonarQube 통합)
IMAGE_TAG="backend-vulnerable-$(date +%Y%m%d-%H%M%S)"
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: backend-vulnerable-
  namespace: default
spec:
  pipelineRef:
    name: backend-pipeline-ci-with-sonar
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-backend:$IMAGE_TAG
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
  - name: sonarqube-url
    value: http://sonarqube.sonarqube:9000
  - name: sonarqube-token
    value: sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF

# 파이프라인 실행 상태 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -3
```

### 5단계: SonarQube 스캔 실패 확인

```bash
# PipelineRun 이름 확인
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')

# SonarQube 스캔 TaskRun 로그 확인
kubectl get taskruns -n default | grep sonarqube
kubectl logs -f taskrun/$(kubectl get taskruns -n default | grep sonarqube | tail -1 | awk '{print $1}') -n default

# 파이프라인 실패 확인
kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.status.conditions[0].status}'
```

### 6단계: SonarQube에서 취약점 확인

```bash
# SonarQube 포트 포워딩
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &

# SonarQube 웹 UI 접속
cat <<EOF
==========================================
SonarQube 취약점 확인
==========================================
URL: http://localhost:9000
사용자: admin
비밀번호: Passpass123123#

프로젝트: error-archive-backend
확인 사항:
1. Projects → error-archive-backend 선택
2. Issues 탭 → 취약점 목록 확인
3. 각 취약점 클릭 → 파일명과 라인 번호 확인
EOF

# API로 취약점 확인
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 취약점 목록
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-backend&types=VULNERABILITY" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line, rule: .rule}'

# 특정 취약점 상세 정보 (SQL Injection)
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-backend&rules=javascript:S5144" | \
  jq '.issues[] | {message: .message, file: .component, line: .line}'

# 하드코딩된 비밀번호 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-backend&rules=javascript:S2068" | \
  jq '.issues[] | {message: .message, file: .component, line: .line}'
```

### 7단계: 취약한 코드 수정

**참고**: `demo/취약코드-예시.md` 파일에서 취약점 종류와 수정 방법을 확인하세요.

```bash
cd /home/kevin/error-archive/backend

# server.js에서 취약한 코드 제거 또는 수정
# 1. SQL Injection 취약점 수정
# 기존: const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
# 수정: 파라미터화된 쿼리 사용 또는 해당 코드 제거

# 2. 하드코딩된 비밀번호 제거
# 기존: const TEST_ADMIN_PASSWORD = "admin123";
# 수정: 환경 변수 사용 또는 해당 코드 제거

# 실제 수정 예시
# 취약한 코드 섹션 제거
sed -i '/\/\/ ❌ 취약한 코드 (SonarQube 테스트용)/,/^});$/d' server.js

# 또는 수동으로 파일 편집
# vi server.js
# 취약한 코드 부분 삭제

# 수정 확인
git diff server.js

# Git 커밋
git add server.js
git commit -m "fix: SonarQube 취약점 수정 (SQL Injection, 하드코딩 비밀번호 제거)"
git push origin main

# 또는 프로젝트 루트에서
cd /home/kevin/error-archive
git add backend/server.js
git commit -m "fix: SonarQube 취약점 수정 (SQL Injection, 하드코딩 비밀번호 제거)"
git push origin main
```

### 8단계: CI/CD 파이프라인 재실행 (수정된 코드)

```bash
# Backend CI 파이프라인 재실행 (SonarQube 통합)
IMAGE_TAG="backend-secure-$(date +%Y%m%d-%H%M%S)"
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: backend-secure-
  namespace: default
spec:
  pipelineRef:
    name: backend-pipeline-ci-with-sonar
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-backend:$IMAGE_TAG
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
  - name: sonarqube-url
    value: http://sonarqube.sonarqube:9000
  - name: sonarqube-token
    value: sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b
  workspaces:
  - name: shared-workspace
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF

# 파이프라인 성공 확인
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')
kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -w

# SonarQube 스캔 성공 확인
kubectl logs -f taskrun/$(kubectl get taskruns -n default | grep sonarqube | tail -1 | awk '{print $1}') -n default
```

### 9단계: SonarQube에서 수정 확인

```bash
# 수정된 프로젝트의 취약점 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-backend&types=VULNERABILITY" | \
  jq '.total'

# 취약점이 감소했는지 확인
# 이전: 취약점 N개
# 현재: 취약점 M개 (N > M)
```

### 10단계: 정상 배포 확인

```bash
# 이미지 빌드 완료 확인
kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.status.conditions[0].status}'

# Harbor에 이미지 푸시 확인
# Harbor UI: https://192.168.0.169:443
# 프로젝트: project
# 저장소: error-archive-backend
# 태그: backend-secure-YYYYMMDD-HHMMSS

# ArgoCD 배포 (선택사항)
# 매니페스트 이미지 태그 업데이트 후 ArgoCD 동기화
```

---

## Backend 파이프라인에 SonarQube 통합

### backend-pipeline-ci.yaml 수정

```yaml
apiVersion: tekton.dev/v1
kind: Pipeline
metadata:
  name: backend-pipeline-ci
  namespace: default
spec:
  params:
  # ... 기존 params ...
  - name: sonarqube-url
    description: SonarQube 서버 URL
    default: http://sonarqube.sonarqube:9000
    type: string
  - name: sonarqube-token
    description: SonarQube 인증 토큰
    type: string
  tasks:
  - name: git-clone
    # ... 기존 설정 ...
  
  # SonarQube 스캔 추가 (git-clone 이후, docker-build-and-push 이전)
  - name: sonarqube-scan
    runAfter:
    - git-clone
    taskRef:
      name: sonarqube-scan
    params:
    - name: sonarqube-url
      value: $(params.sonarqube-url)
    - name: sonarqube-token
      value: $(params.sonarqube-token)
    - name: project-key
      value: error-archive-backend
    - name: project-name
      value: Error Archive Backend
    - name: source-path
      value: backend
    - name: language
      value: js
    workspaces:
    - name: source
      workspace: shared-workspace
  
  - name: docker-build-and-push
    runAfter:
    - sonarqube-scan  # SonarQube 스캔 성공 후 빌드
    # ... 기존 설정 ...
```

---

## 취약점 종류 및 수정 방법

### 1. SQL Injection (javascript:S5144)
```javascript
// ❌ 취약한 코드
const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;

// ✅ 수정된 코드
const query = 'SELECT * FROM posts WHERE title LIKE ?';
const result = await db.query(query, [`%${keyword}%`]);
```

### 2. 하드코딩된 비밀번호 (javascript:S2068)
```javascript
// ❌ 취약한 코드
const ADMIN_PASSWORD = "admin123";

// ✅ 수정된 코드
const ADMIN_PASSWORD = process.env.ADMIN_PASSWORD || '';
```

### 3. 민감 정보 로깅 (javascript:S4792)
```javascript
// ❌ 취약한 코드
console.log("User login:", username, password);

// ✅ 수정된 코드
console.log("User login:", username); // 비밀번호 제외
```

---

## 빠른 확인 명령어

### 파이프라인 상태
```bash
# 최근 PipelineRun 확인
kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -5

# SonarQube TaskRun 확인
kubectl get taskruns -n default | grep sonarqube

# SonarQube 스캔 로그
kubectl logs -f taskrun/$(kubectl get taskruns -n default | grep sonarqube | tail -1 | awk '{print $1}') -n default
```

### SonarQube 취약점 확인
```bash
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 전체 취약점 개수
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-backend&types=VULNERABILITY" | \
  jq '.total'

# 취약점 목록
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-backend&types=VULNERABILITY" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line}'
```

---

## 체크리스트

- [ ] SonarQube 토큰 Secret 생성
- [ ] SonarQube Task 배포
- [ ] Backend 파이프라인에 SonarQube 통합
- [ ] 취약한 코드 생성 및 Git 푸시
- [ ] CI/CD 파이프라인 실행 (실패 예상)
- [ ] SonarQube에서 취약점 확인
- [ ] 취약한 코드 수정 및 Git 푸시
- [ ] CI/CD 파이프라인 재실행 (성공 예상)
- [ ] SonarQube에서 취약점 감소 확인
- [ ] 정상 배포 확인

