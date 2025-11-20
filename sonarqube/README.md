# SonarQube 코드 품질 분석

이 디렉토리는 SonarQube 코드 품질 분석 도구의 Kubernetes 설치 및 Tekton 통합 구성을 포함합니다.

## 구조

```
sonarqube/
├── manifests/          # Kubernetes 배포 매니페스트
│   ├── namespace.yaml
│   ├── postgresql.yaml
│   └── sonarqube.yaml
├── tasks/              # Tekton Tasks
│   └── sonarqube-scan-task.yaml
└── scripts/           # 설치 및 유틸리티 스크립트
    ├── install-sonarqube.sh
    └── get-sonarqube-token.sh
```

## 설치

### 1. SonarQube 설치

```bash
chmod +x sonarqube/scripts/install-sonarqube.sh
./sonarqube/scripts/install-sonarqube.sh
```

### 2. SonarQube 접속 및 초기 설정

```bash
# 포트 포워딩
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000

# 브라우저에서 접속
# http://localhost:9000
# 기본 계정: admin / admin
```

### 3. 토큰 생성

```bash
chmod +x sonarqube/scripts/get-sonarqube-token.sh
./sonarqube/scripts/get-sonarqube-token.sh
```

SonarQube UI에서 토큰을 생성한 후:

```bash
# Kubernetes Secret에 토큰 저장
kubectl create secret generic sonarqube-token \
  --from-literal=token=YOUR_TOKEN_HERE \
  --namespace=default
```

### 4. Tekton Task 배포

```bash
kubectl apply -f sonarqube/tasks/sonarqube-scan-task.yaml
```

## CI 파이프라인 통합

### Backend 파이프라인에 SonarQube 스캔 추가

`tekton/pipelines/backend-pipeline-ci.yaml`에 다음 Task를 추가:

```yaml
- name: sonarqube-scan
  runAfter:
  - git-clone
  taskRef:
    name: sonarqube-scan
  params:
  - name: sonarqube-url
    value: http://sonarqube.sonarqube:9000
  - name: sonarqube-token
    valueFrom:
      secretKeyRef:
        name: sonarqube-token
        key: token
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
```

### Frontend 파이프라인에 SonarQube 스캔 추가

`tekton/pipelines/frontend-pipeline-ci.yaml`에 동일한 방식으로 추가:

```yaml
- name: sonarqube-scan
  runAfter:
  - git-clone
  taskRef:
    name: sonarqube-scan
  params:
  - name: sonarqube-url
    value: http://sonarqube.sonarqube:9000
  - name: sonarqube-token
    valueFrom:
      secretKeyRef:
        name: sonarqube-token
        key: token
  - name: project-key
    value: error-archive-frontend
  - name: project-name
    value: Error Archive Frontend
  - name: source-path
    value: frontend
  - name: language
    value: js
  workspaces:
  - name: source
    workspace: shared-workspace
```

## 사용 방법

### 수동 스캔 실행

```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: TaskRun
metadata:
  generateName: sonarqube-scan-backend-
  namespace: default
spec:
  taskRef:
    name: sonarqube-scan
  params:
  - name: sonarqube-url
    value: http://sonarqube.sonarqube:9000
  - name: sonarqube-token
    valueFrom:
      secretKeyRef:
        name: sonarqube-token
        key: token
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
    volumeClaimTemplate:
      spec:
        accessModes:
        - ReadWriteOnce
        resources:
          requests:
            storage: 1Gi
EOF
```

## SonarQube 접속

```bash
# 포트 포워딩
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000

# 브라우저에서 접속
# http://localhost:9000
```

## 주요 기능

- **코드 품질 분석**: 코드 스멜, 버그, 취약점 감지
- **코드 커버리지**: 테스트 커버리지 측정
- **코드 중복 검사**: 중복 코드 감지
- **보안 취약점**: 보안 취약점 스캔
- **기술 부채**: 기술 부채 측정

## 문제 해결

### SonarQube Pod가 시작되지 않는 경우

```bash
# Pod 상태 확인
kubectl get pods -n sonarqube

# 로그 확인
kubectl logs -f deployment/sonarqube -n sonarqube

# PostgreSQL 연결 확인
kubectl logs deployment/sonarqube-postgresql -n sonarqube
```

### 스캔 실패 시

```bash
# TaskRun 로그 확인
kubectl logs -f <taskrun-pod-name> -c sonar-scanner
```

## 리소스 요구사항

- **PostgreSQL**: 256Mi 메모리, 250m CPU
- **SonarQube**: 1Gi 메모리, 500m CPU
- **스토리지**: 각각 10Gi (총 20Gi)

