#!/bin/bash
# Harbor 이미지 스캔 스크립트 (인증서 검증 비활성화)

IMAGE_NAME=${1:-"192.168.0.169:443/project/error-archive-backend:1.3"}
SEVERITY=${2:-"HIGH,CRITICAL"}

echo "=== Harbor 이미지 스캔 (Insecure) ==="
echo "이미지: $IMAGE_NAME"
echo "심각도: $SEVERITY"
echo ""

# Docker daemon 설정 확인
echo "1. Docker daemon insecure registry 설정 확인..."
if ! grep -q "192.168.0.169:443" /etc/docker/daemon.json 2>/dev/null; then
    echo "⚠ /etc/docker/daemon.json에 insecure-registries 설정이 필요할 수 있습니다:"
    echo '  {'
    echo '    "insecure-registries": ["192.168.0.169:443"]'
    echo '  }'
    echo ""
    echo "설정 후: sudo systemctl restart docker"
    echo ""
fi

# Harbor 로그인 (인증서 오류 무시)
echo "2. Harbor 로그인 시도 중..."
echo "Harbor12345" | docker login 192.168.0.169:443 -u admin --password-stdin 2>&1 | grep -v "certificate" || {
    echo "⚠ 인증서 경고가 있지만 계속 진행합니다..."
}

# 이미지 Pull
echo "3. 이미지 Pull 중..."
docker pull "$IMAGE_NAME" 2>&1 | grep -v "certificate" || {
    echo "❌ 이미지 Pull 실패"
    echo ""
    echo "해결 방법:"
    echo "1. /etc/docker/daemon.json 수정:"
    echo '   sudo vi /etc/docker/daemon.json'
    echo '   {'
    echo '     "insecure-registries": ["192.168.0.169:443"]'
    echo '   }'
    echo ""
    echo "2. Docker 재시작:"
    echo "   sudo systemctl restart docker"
    exit 1
}

echo "✓ 이미지 Pull 성공"
echo ""

# Trivy 스캔
echo "4. Trivy 스캔 실행 중..."
docker run --rm \
    -v /var/run/docker.sock:/var/run/docker.sock \
    aquasec/trivy:latest \
    image --severity "$SEVERITY" "$IMAGE_NAME"

echo ""
echo "=== 스캔 완료 ==="

