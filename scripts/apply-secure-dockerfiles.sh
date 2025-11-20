#!/bin/bash
# 보안 강화 Dockerfile 적용 스크립트

echo "=== 보안 강화 Dockerfile 적용 ==="

# 백업 생성
echo "1. 기존 Dockerfile 백업 중..."
cp backend/Dockerfile backend/Dockerfile.backup
cp frontend/Dockerfile frontend/Dockerfile.backup

# 보안 강화 버전 적용
echo "2. 보안 강화 Dockerfile 적용 중..."
cp backend/Dockerfile.secure backend/Dockerfile
cp frontend/Dockerfile.secure frontend/Dockerfile

echo ""
echo "✓ 적용 완료!"
echo ""
echo "변경 사항:"
echo "  - Backend: node:18 → node:18-alpine"
echo "  - Frontend: nginx:latest → nginx:1.25-alpine"
echo "  - 비root 사용자 실행"
echo "  - 보안 업데이트 자동 적용"
echo ""
echo "백업 파일:"
echo "  - backend/Dockerfile.backup"
echo "  - frontend/Dockerfile.backup"
echo ""
echo "다음 단계:"
echo "  1. 이미지 재빌드: kubectl create -f tekton/pipelineruns/..."
echo "  2. Harbor에서 Trivy 스캔 재실행"
echo "  3. 취약점 감소 확인"

