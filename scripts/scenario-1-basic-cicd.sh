#!/bin/bash
# 시나리오 1: 기본 CI/CD 파이프라인 시연

VERSION=${1:-"1.6"}

cd /home/kevin/proj/error-archive-1

echo "=========================================="
echo "  시나리오 1: 기본 CI/CD 파이프라인"
echo "  버전: $VERSION"
echo "=========================================="
echo ""

# 1단계: 코드 변경
echo "1단계: 코드 변경 (배너 추가)..."
cat >> frontend/index.html << EOF

<!-- 배너 추가 (버전 $VERSION) -->
<div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); color: white; padding: 8px; text-align: center; font-size: 14px; font-weight: bold; position: fixed; top: 0; left: 0; right: 0; z-index: 9999;">
  🚀 CI/CD 파이프라인 시연 - 버전 $VERSION
</div>
<style>
  body { padding-top: 40px; }
</style>
EOF
echo "✓ 배너 추가 완료"
echo ""

# 2단계: Git 커밋 및 푸시
echo "2단계: Git 커밋 및 푸시..."
git add frontend/index.html
git commit -m "Add banner for version $VERSION - CI/CD demo" || echo "변경사항 없음"
git push origin main
echo "✓ Git 푸시 완료"
echo ""

# 3단계: CI Pipeline 실행
echo "3단계: CI Pipeline 실행 (이미지 빌드 및 푸시)..."
PIPELINE_RUN=$(kubectl create -f - <<EOF 2>&1 | grep "created" | awk '{print $1}')
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-demo-$VERSION-
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
    value: 192.168.0.169:443/project/error-archive-frontend:$VERSION
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

if [ -n "$PIPELINE_RUN" ]; then
    echo "✓ PipelineRun 생성: $PIPELINE_RUN"
    echo "  빌드 완료 대기 중... (약 1-2분)"
    for i in {1..30}; do
        sleep 5
        STATUS=$(kubectl get $PIPELINE_RUN -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
        if [ "$STATUS" == "True" ]; then
            echo "✓ 빌드 완료!"
            break
        fi
        echo -n "."
    done
    echo ""
else
    echo "⚠ PipelineRun 생성 실패"
fi
echo ""

# 4단계: 매니페스트 업데이트
echo "4단계: Kubernetes 매니페스트 업데이트..."
sed -i "s|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:$VERSION|g" k8s/error-archive/frontend-deployment.yaml
echo "✓ 매니페스트 업데이트 완료"
echo ""

# 5단계: Git 푸시 (ArgoCD 자동 배포)
echo "5단계: Git 푸시 (ArgoCD 자동 배포)..."
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy frontend version $VERSION" || echo "변경사항 없음"
git push origin main
echo "✓ Git 푸시 완료"
echo ""

echo "=========================================="
echo "  배포 완료!"
echo "=========================================="
echo ""
echo "ArgoCD가 자동으로 배포를 시작합니다."
echo ""
echo "배포 상태 확인:"
echo "  kubectl get applications -n argocd"
echo "  kubectl get deployments -n error-archive"

