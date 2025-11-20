# 프로젝트 시연 시나리오 가이드

## 시나리오 개요

**가을 테마 → 겨울 테마 전환 → 로그인 → 이벤트 배너 → 룰렛 이벤트**

---

## 시연 순서

### 1단계: 가을 테마 확인 (시작)
- 웹사이트 접속 시 **가을 테마**로 시작
- 배경: 갈색/금색 그라데이션
- 낙엽 효과 (갈색/주황색 낙엽이 떨어짐)

**확인 사항:**
- 우측 상단에 "🍂 가을 테마" 버튼 표시
- 배경이 따뜻한 가을 색상

---

### 2단계: 겨울 테마로 전환
**방법 1: 버튼 클릭 (권장)**
- 우측 상단 "🍂 가을 테마" 버튼 클릭
- 자동으로 "❄️ 겨울 테마"로 변경
- 배경이 보라색/파란색으로 변경
- 눈 내리는 효과 시작

**방법 2: 브라우저 콘솔**
```javascript
changeTheme('winter')
```

**확인 사항:**
- 배경 색상 변경 (보라색 그라데이션)
- 눈 내리는 효과 표시
- 버튼이 "❄️ 겨울 테마"로 변경

---

### 3단계: 로그인
- 일반 로그인 또는 소셜 로그인 (카카오/네이버)
- 로그인 성공 시 `list.html`로 이동

**확인 사항:**
- 로그인 성공 메시지
- list.html 페이지로 자동 이동

---

### 4단계: 이벤트 배너 확인
- 로그인 후 `list.html` 페이지 상단에 **"겨울 맞이 이벤트"** 배너 표시
- 배너 내용: "🎄 겨울 맞이 이벤트 진행 중! 룰렛 돌리고 선물 받자! 🎁"
- "참여하기 →" 버튼 클릭

**확인 사항:**
- 배너가 상단에 표시됨
- "참여하기" 버튼 클릭 시 `roulette.html`로 이동

---

### 5단계: 룰렛 돌리기
- `roulette.html` 페이지 접속
- 룰렛 항목: **꽝, 피자, 치킨, 삼겹살, 소고기**
- "룰렛 돌리기" 버튼 클릭
- 4초 후 결과 표시

**확인 사항:**
- 룰렛이 회전함
- 결과가 표시됨
- 결과가 자동으로 저장됨

---

### 6단계: 히스토리 확인
- 룰렛 페이지 하단에 "나의 룰렛 결과" 섹션 표시
- 이전에 돌린 룰렛 결과 목록 확인

**확인 사항:**
- 사용자별로 결과가 저장됨
- 최근 20개 결과 표시

---

## 롤백 방법

### 테마 롤백
**방법 1: 버튼 클릭**
- 우측 상단 "❄️ 겨울 테마" 버튼 클릭 → 가을 테마로 복구

**방법 2: 브라우저 콘솔**
```javascript
changeTheme('autumn')
```

### 이벤트 배너 숨김 해제
```javascript
localStorage.removeItem('eventBannerClosed')
location.reload()
```

### Git 롤백 (필요시)
```bash
# 특정 파일만 롤백
git checkout HEAD~1 -- frontend/index.html frontend/list.html frontend/roulette.html
git commit -m "Rollback to autumn theme"
git push origin main
```

---

## 시연 팁

### 발표 시 추천 순서
1. **가을 테마 소개** (30초)
   - "현재 가을 테마로 설정되어 있습니다"
   - 낙엽 효과 설명

2. **테마 전환 시연** (30초)
   - 버튼 클릭으로 겨울 테마로 전환
   - "CI/CD를 통해 테마를 업데이트할 수 있습니다"

3. **로그인 및 이벤트 배너** (1분)
   - 로그인 시연
   - 이벤트 배너 자동 표시 설명

4. **룰렛 이벤트** (2분)
   - 룰렛 돌리기
   - 결과 저장 및 히스토리 확인

5. **롤백 시연** (30초)
   - 가을 테마로 롤백
   - "문제 발생 시 빠른 롤백 가능"

**총 소요 시간: 약 4-5분**

---

## 기술 스택

- **프론트엔드**: HTML, CSS, JavaScript
- **백엔드**: Node.js, Express, MongoDB
- **테마 전환**: localStorage 기반
- **룰렛**: Canvas API + CSS Animation
- **데이터 저장**: MongoDB (RouletteResults 컬렉션)

---

## 배포 방법

### 1. Git 커밋 및 푸시
```bash
git add frontend/index.html frontend/list.html frontend/roulette.html backend/server.js
git commit -m "Add seasonal theme change and roulette event feature"
git push origin main
```

### 2. 이미지 빌드
```bash
# Frontend
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-season-2.0-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:2.0
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
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

# Backend
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: backend-roulette-2.0-
  namespace: default
spec:
  pipelineRef:
    name: backend-pipeline-ci
  params:
  - name: git-url
    value: https://github.com/dprxrx/error-archive.git
  - name: git-revision
    value: main
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-backend:2.0
  - name: registry-url
    value: 192.168.0.169:443
  - name: registry-username
    value: admin
  - name: registry-password
    value: Harbor12345
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

### 3. 배포 매니페스트 업데이트
```bash
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:2.0|g' k8s/error-archive/frontend-deployment.yaml
sed -i 's|192.168.0.169:443/project/error-archive-backend:.*|192.168.0.169:443/project/error-archive-backend:2.0|g' k8s/error-archive/backend-deployment.yaml
git add k8s/error-archive/*.yaml
git commit -m "Deploy version 2.0 with seasonal theme and roulette"
git push origin main
```

---

## 문제 해결

### 이벤트 배너가 안 보여요
- 테마가 겨울인지 확인: `localStorage.getItem('theme')`
- 배너가 닫혔는지 확인: `localStorage.getItem('eventBannerClosed')`
- 해결: `localStorage.removeItem('eventBannerClosed')` 후 새로고침

### 룰렛 결과가 저장 안 돼요
- 백엔드 Pod 로그 확인: `kubectl logs -f deployment/backend-deployment -n error-archive`
- MongoDB 연결 확인
- API 엔드포인트 확인: `/api/roulette/save`

### 테마가 전환 안 돼요
- 브라우저 캐시 삭제
- localStorage 확인: `localStorage.getItem('theme')`
- 수동 설정: `changeTheme('winter')`

