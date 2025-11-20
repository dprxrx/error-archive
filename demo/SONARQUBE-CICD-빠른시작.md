# SonarQube CI/CD 통합 빠른 시작

## 현재 상태 확인

```bash
# 현재 backend 디렉토리에 있는 경우
cd /home/kevin/error-archive/backend

# server.js가 staged 상태인지 확인
git status

# 취약한 코드가 추가되었는지 확인
tail -30 server.js | grep -A 5 "취약한 코드"
```

## 다음 단계

### 1단계: 취약한 코드 커밋 및 푸시
```bash
# 현재 backend 디렉토리에 있는 경우
git commit -m "test: 취약한 코드 추가 (SonarQube 테스트용)"
git push origin main

# 또는 프로젝트 루트에서
cd /home/kevin/error-archive
git commit -m "test: 취약한 코드 추가 (SonarQube 테스트용)"
git push origin main
```

### 2단계: SonarQube 통합 파이프라인 배포
```bash
cd /home/kevin/error-archive

# SonarQube Task 배포
kubectl apply -f sonarqube/tasks/sonarqube-scan-task.yaml

# SonarQube 통합 파이프라인 배포
kubectl apply -f tekton/pipelines/backend-pipeline-ci-with-sonar.yaml

# 배포 확인
kubectl get pipeline backend-pipeline-ci-with-sonar -n default
kubectl get task sonarqube-scan -n default
```

### 3단계: CI/CD 파이프라인 실행
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

### 4단계: SonarQube 스캔 결과 확인
```bash
# PipelineRun 이름 확인
PIPELINE_RUN_NAME=$(kubectl get pipelineruns -n default --sort-by=.metadata.creationTimestamp | tail -1 | awk '{print $1}')

# SonarQube 스캔 TaskRun 로그 확인
kubectl get taskruns -n default | grep sonarqube
kubectl logs -f taskrun/$(kubectl get taskruns -n default | grep sonarqube | tail -1 | awk '{print $1}') -n default

# 파이프라인 상태 확인
kubectl get pipelinerun $PIPELINE_RUN_NAME -n default -o jsonpath='{.status.conditions[0].status}'
```

### 5단계: SonarQube 웹 UI에서 취약점 확인
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

주요 취약점:
- SQL Injection (javascript:S5144)
- 하드코딩된 비밀번호 (javascript:S2068)
- 민감 정보 로깅 (javascript:S4792)
EOF

# API로 취약점 확인
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 취약점 목록
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/issues/search?componentKeys=error-archive-backend&types=VULNERABILITY" | \
  jq '.issues[] | {severity: .severity, message: .message, file: .component, line: .line, rule: .rule}'
```

### 6단계: 취약한 코드 수정
```bash
cd /home/kevin/error-archive/backend

# 취약한 코드 섹션 제거
# demo/취약코드-예시.md 파일 참고

# 수정 확인
git diff server.js

# Git 커밋 및 푸시
git add server.js
git commit -m "fix: SonarQube 취약점 수정 (SQL Injection, 하드코딩 비밀번호 제거)"
git push origin main
```

### 7단계: CI/CD 파이프라인 재실행
```bash
# Backend CI 파이프라인 재실행
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
```

---

## 현재 상태에서 바로 실행

```bash
# 1. 취약한 코드 커밋 및 푸시
cd /home/kevin/error-archive/backend
git commit -m "test: 취약한 코드 추가 (SonarQube 테스트용)"
git push origin main

# 2. SonarQube 통합 파이프라인 배포
cd /home/kevin/error-archive
kubectl apply -f sonarqube/tasks/sonarqube-scan-task.yaml
kubectl apply -f tekton/pipelines/backend-pipeline-ci-with-sonar.yaml

# 3. CI/CD 파이프라인 실행
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
```

---

## 취약점 확인 명령어

```bash
# SonarQube 포트 포워딩
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &

# 취약점 확인
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

