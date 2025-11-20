# 프로젝트 발표용 CI/CD 시연 빠른 참조

## 시나리오별 실행 명령어 (복붙용)

### 시나리오 1: 기본 CI/CD 파이프라인
```bash
cd /home/kevin/proj/error-archive-1
./scripts/scenario-1-basic-cicd.sh 1.6
```

### 시나리오 2: 버전 관리 및 롤백
```bash
cd /home/kevin/proj/error-archive-1
./scripts/scenario-2-rollback.sh 1.7 1.6
```

### 시나리오 3: 보안 스캔 통합
```bash
cd /home/kevin/proj/error-archive-1
./scripts/scenario-3-security-scan.sh 1.6 1.8
```

### 시나리오 4: 다중 환경 배포
```bash
cd /home/kevin/proj/error-archive-1
./scripts/scenario-4-multi-env.sh 1.6
```

### 시나리오 5: 모니터링 및 알림
```bash
cd /home/kevin/proj/error-archive-1
./scripts/scenario-5-monitoring.sh
```

### 시나리오 6: 모니터링 심화
```bash
cd /home/kevin/proj/error-archive-1
./scripts/scenario-6-monitoring-advanced.sh
```

---

## 발표 시나리오 체크리스트

### 사전 준비
- [ ] 모든 스크립트 실행 권한 확인: `chmod +x scripts/scenario-*.sh`
- [ ] Git 저장소 최신 상태 확인
- [ ] Harbor 접속 확인
- [ ] ArgoCD 접속 확인
- [ ] Prometheus/Grafana Port Forward 준비

### 시나리오 1: 기본 CI/CD (3-4분)
- [ ] 코드 변경 (배너 추가)
- [ ] Git 푸시
- [ ] Tekton CI Pipeline 실행
- [ ] Harbor 이미지 푸시 확인
- [ ] ArgoCD 자동 배포 확인
- [ ] 웹사이트에서 배너 확인

### 시나리오 2: 롤백 (2-3분)
- [ ] 문제 버전 배포
- [ ] 문제 확인
- [ ] 롤백 실행
- [ ] 롤백 확인

### 시나리오 3: 보안 스캔 (2-3분)
- [ ] 현재 이미지 취약점 확인
- [ ] 보안 강화 Dockerfile 적용
- [ ] 보안 강화 이미지 빌드
- [ ] 취약점 비교

### 시나리오 4: 다중 환경 (2-3분)
- [ ] 개발 환경 배포
- [ ] 스테이징 환경 배포
- [ ] 프로덕션 환경 배포
- [ ] 환경별 상태 확인

### 시나리오 5-6: 모니터링 (2-3분)
- [ ] Prometheus 연결
- [ ] Grafana 연결
- [ ] 메트릭 쿼리 시연
- [ ] 알림 규칙 확인

---

## 빠른 명령어 모음

### 상태 확인
```bash
# PipelineRun 상태
kubectl get pipelineruns

# 배포 상태
kubectl get deployments -n error-archive

# ArgoCD 상태
kubectl get applications -n argocd

# Pod 상태
kubectl get pods -n error-archive
```

### 로그 확인
```bash
# Frontend 로그
kubectl logs -f deployment/frontend -n error-archive

# Backend 로그
kubectl logs -f deployment/backend-deployment -n error-archive
```

### 서비스 접속
```bash
# 모든 서비스 Port Forward
./scripts/port-forwards.sh

# 또는 tmux 사용
./scripts/tmux-services.sh
```

---

## 발표 팁

1. **시나리오 1**: 전체 흐름을 천천히 설명하며 각 단계의 의미 강조
2. **시나리오 2**: 문제 발생 시 빠른 대응 능력 강조
3. **시나리오 3**: 보안의 중요성과 자동화된 보안 검사 강조
4. **시나리오 4**: 엔터프라이즈급 배포 전략 설명
5. **시나리오 5-6**: 운영 관점에서의 모니터링 중요성 강조

각 시나리오는 2-4분 내에 완료되도록 설계되었습니다.

