# SonarQube 토큰 확인 및 재생성 방법

## 🔍 SonarQube 대시보드에서 토큰 확인

### 1단계: SonarQube 접속

```bash
# 포트 포워딩 (별도 터미널에서 실행)
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000

# 브라우저에서 접속
# http://localhost:9000
```

### 2단계: 로그인

- **사용자명**: `admin`
- **비밀번호**: `Passpass123123#` (또는 설정한 비밀번호)

### 3단계: 토큰 목록 확인

1. **우측 상단 프로필 아이콘** 클릭 (사용자 아바타)
2. **"My Account"** 선택
3. **"Security"** 탭 클릭
4. **"Tokens"** 섹션에서 생성된 토큰 목록 확인
   - 토큰 이름
   - 생성 날짜
   - 만료 날짜 (설정한 경우)
   - 마지막 사용 날짜

### 4단계: 토큰 값 확인

⚠️ **중요**: SonarQube에서는 **이미 생성된 토큰의 값을 다시 확인할 수 없습니다**. 
토큰은 생성 시 한 번만 표시되며, 이후에는 볼 수 없습니다.

**해결 방법**:
- 기존 토큰이 있다면 Kubernetes Secret에서 확인
- 기존 토큰을 잊어버렸다면 새 토큰 생성 필요

---

## 🔄 새 토큰 생성 방법

### 방법 1: SonarQube UI에서 생성

1. **My Account** > **Security** 탭
2. **"Generate Token"** 버튼 클릭
3. **토큰 이름 입력** (예: `tekton-frontend`, `tekton-backend`)
4. **Expires in**: 
   - `No expiration` (만료 없음) - 권장
   - 또는 원하는 기간 선택
5. **"Generate"** 버튼 클릭
6. **토큰 복사** (한 번만 표시됨! 반드시 저장)

### 방법 2: Kubernetes Secret에서 현재 토큰 확인

```bash
# 백엔드 토큰 확인
kubectl get secret sonarqube-token -n default -o jsonpath='{.data.token}' | base64 -d
echo ""

# 프론트엔드 토큰 확인
kubectl get secret sonarqube-token-frontend -n default -o jsonpath='{.data.token}' | base64 -d
echo ""
```

---

## 📝 토큰 업데이트 (Kubernetes Secret)

### 새 토큰을 Secret에 저장

```bash
# 백엔드 토큰 업데이트
kubectl create secret generic sonarqube-token \
  --from-literal=token=YOUR_NEW_TOKEN_HERE \
  -n default \
  --dry-run=client -o yaml | kubectl apply -f -

# 프론트엔드 토큰 업데이트
kubectl create secret generic sonarqube-token-frontend \
  --from-literal=token=YOUR_NEW_TOKEN_HERE \
  -n default \
  --dry-run=client -o yaml | kubectl apply -f -
```

### 토큰 확인

```bash
# Secret 목록 확인
kubectl get secret -n default | grep sonarqube

# 토큰 값 확인
echo "=== 백엔드 토큰 ==="
kubectl get secret sonarqube-token -n default -o jsonpath='{.data.token}' | base64 -d
echo ""
echo ""
echo "=== 프론트엔드 토큰 ==="
kubectl get secret sonarqube-token-frontend -n default -o jsonpath='{.data.token}' | base64 -d
echo ""
```

---

## 🔐 현재 사용 중인 토큰 정보

### 백엔드 토큰
- **Secret 이름**: `sonarqube-token`
- **토큰**: `sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b`
- **사용처**: Backend 파이프라인

### 프론트엔드 토큰
- **Secret 이름**: `sonarqube-token-frontend`
- **토큰**: `sqp_e0229117ea554f28429d3cd9b92d27b530097798`
- **사용처**: Frontend 파이프라인

### 일반 토큰
- **토큰**: `sqa_b521b117e99b8c38e1b08d69d6ff2396e6f9cc99`
- **사용처**: 테스트 및 수동 스캔

---

## 🧪 토큰 유효성 테스트

### API로 토큰 확인

```bash
# 토큰 설정
export SONAR_TOKEN="sqp_9ea98b26b24829722d2e81b2d9284bfd2383584b"

# 토큰 유효성 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/authentication/validate" | jq

# 프로젝트 목록 확인
curl -s -u $SONAR_TOKEN: \
  "http://localhost:9000/api/projects/search" | jq '.components[] | {key: .key, name: .name}'
```

### 성공 응답 예시
```json
{
  "valid": true
}
```

### 실패 응답 예시
```json
{
  "valid": false,
  "errors": [
    {
      "msg": "Invalid token"
    }
  ]
}
```

---

## ⚠️ 문제 해결

### 토큰이 작동하지 않는 경우

1. **토큰 만료 확인**
   - SonarQube UI > My Account > Security > Tokens
   - 만료된 토큰은 삭제하고 새로 생성

2. **토큰 형식 확인**
   - 올바른 형식: `sqp_` 또는 `sqa_`로 시작
   - 공백이나 특수문자 포함 여부 확인

3. **Secret 확인**
   ```bash
   # Secret 존재 확인
   kubectl get secret sonarqube-token sonarqube-token-frontend -n default
   
   # Secret 값 확인 (base64 디코딩)
   kubectl get secret sonarqube-token -n default -o jsonpath='{.data.token}' | base64 -d
   ```

4. **새 토큰 생성 및 업데이트**
   - SonarQube UI에서 새 토큰 생성
   - Kubernetes Secret 업데이트
   - 파이프라인 재실행

---

## 📋 빠른 확인 명령어

```bash
# 1. SonarQube 포트 포워딩
kubectl port-forward svc/sonarqube -n sonarqube 9000:9000 &

# 2. 현재 Secret의 토큰 확인
echo "=== 백엔드 토큰 ==="
kubectl get secret sonarqube-token -n default -o jsonpath='{.data.token}' | base64 -d
echo ""
echo "=== 프론트엔드 토큰 ==="
kubectl get secret sonarqube-token-frontend -n default -o jsonpath='{.data.token}' | base64 -d
echo ""

# 3. 토큰 유효성 테스트
export SONAR_TOKEN=$(kubectl get secret sonarqube-token -n default -o jsonpath='{.data.token}' | base64 -d)
curl -s -u $SONAR_TOKEN: "http://localhost:9000/api/authentication/validate" | jq
```

---

## 🔗 관련 문서

- `demo/SONARQUBE-인증-해결.md`: 인증 문제 해결 가이드
- `demo/SONARQUBE-토큰-정리.md`: 토큰 정보 정리
- `sonarqube/scripts/get-sonarqube-token.sh`: 토큰 생성 가이드 스크립트

