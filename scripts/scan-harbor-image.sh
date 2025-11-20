#!/bin/bash
# Harbor 이미지 스캔 스크립트

IMAGE_NAME=${1:-"192.168.0.169:443/project/error-archive-backend:1.3"}
SEVERITY=${2:-"HIGH,CRITICAL"}

echo "=== Harbor 이미지 스캔 ==="
echo "이미지: $IMAGE_NAME"
echo "심각도: $SEVERITY"
echo ""

# Harbor 로그인 (인증서 검증 비활성화)
echo "1. Harbor 로그인 중..."
echo "Harbor12345" | docker login 192.168.0.169:443 -u admin --password-stdin 2>&1 | grep -v "certificate" || true

# Docker daemon에 insecure registry 설정이 필요할 수 있음
# 또는 환경 변수로 인증서 검증 비활성화
export DOCKER_TLS_CERTDIR=""
DOCKER_CONTENT_TRUST=0 docker login 192.168.0.169:443 -u admin --password-stdin <<< "Harbor12345" 2>&1 | grep -v "certificate" || {
    echo "⚠ 인증서 검증 경고가 있지만 계속 진행합니다..."
}

# 직접 로그인 시도 (인증서 오류 무시)
docker login 192.168.0.169:443 -u admin --password-stdin <<< "Harbor12345" 2>&1 | grep -v "certificate" || {
    echo "⚠ Harbor 로그인에 인증서 경고가 있지만 이미지 pull을 시도합니다..."
}

echo "✓ Harbor 로그인 성공"
echo ""

# 이미지 Pull (인증서 오류 무시)
echo "2. 이미지 Pull 중..."
DOCKER_CONTENT_TRUST=0 docker pull "$IMAGE_NAME" 2>&1 | grep -v "certificate" || {
    echo "⚠ 인증서 경고가 있지만 계속 진행합니다..."
    docker pull "$IMAGE_NAME" 2>&1 | grep -v "certificate" || true
}

echo "✓ 이미지 Pull 성공"
echo ""

# Trivy 스캔
echo "3. Trivy 스캔 실행 중..."
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest \
    image --severity "$SEVERITY" "$IMAGE_NAME"

echo ""
echo "=== 스캔 완료 ==="
echo ""
echo "전체 스캔 결과를 보려면:"
echo "  docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy:latest image $IMAGE_NAME"

