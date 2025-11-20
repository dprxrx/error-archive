#!/bin/bash
# 시나리오 3: 보안 스캔 통합

OLD_VERSION=${1:-"1.6"}
NEW_VERSION=${2:-"1.8"}

cd /home/kevin/proj/error-archive-1

echo "=========================================="
echo "  시나리오 3: 보안 스캔 통합"
echo "  이전 버전: $OLD_VERSION"
echo "  보안 강화 버전: $NEW_VERSION"
echo "=========================================="
echo ""

# 1단계: 현재 이미지 취약점 확인
echo "1단계: 현재 이미지 취약점 확인..."
echo "Harbor UI에서 $OLD_VERSION 버전 스캔 결과 확인:"
echo "  http://192.168.0.169:443"
echo "  프로젝트 → error-archive-frontend → $OLD_VERSION → 취약점"
echo ""
read -p "스캔 결과를 확인하셨나요? (Enter로 계속) "

# 2단계: 보안 강화 Dockerfile 적용
echo ""
echo "2단계: 보안 강화 Dockerfile 적용..."
./scripts/apply-secure-dockerfiles.sh
echo ""

# 3단계: 보안 강화 이미지 빌드
echo "3단계: 보안 강화 이미지 빌드..."
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-secure-$NEW_VERSION-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:$NEW_VERSION
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

echo "✓ 보안 강화 이미지 빌드 시작"
echo "  빌드 완료 대기 중... (약 1-2분)"
sleep 90
echo ""

# 4단계: 취약점 비교
echo "4단계: 취약점 비교..."
echo "Harbor UI에서 취약점 개수 비교:"
echo "  $OLD_VERSION 버전 vs $NEW_VERSION 버전"
echo ""
echo "또는 로컬에서 스캔:"
echo "  ./scripts/scan-harbor-image.sh 192.168.0.169:443/project/error-archive-frontend:$OLD_VERSION"
echo "  ./scripts/scan-harbor-image.sh 192.168.0.169:443/project/error-archive-frontend:$NEW_VERSION"
echo ""

echo "=========================================="
echo "  보안 스캔 완료!"
echo "=========================================="

