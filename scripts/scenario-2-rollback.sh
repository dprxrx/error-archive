#!/bin/bash
# 시나리오 2: 버전 관리 및 롤백

PROBLEM_VERSION=${1:-"1.7"}
STABLE_VERSION=${2:-"1.6"}

cd /home/kevin/proj/error-archive-1

echo "=========================================="
echo "  시나리오 2: 버전 관리 및 롤백"
echo "  문제 버전: $PROBLEM_VERSION"
echo "  롤백 버전: $STABLE_VERSION"
echo "=========================================="
echo ""

# 1단계: 문제가 있는 버전 배포
echo "1단계: 문제가 있는 버전 배포..."
cat >> frontend/index.html << EOF

<!-- 문제가 있는 코드 (버전 $PROBLEM_VERSION) -->
<script>
  console.error("Intentional error for demo - version $PROBLEM_VERSION");
</script>
EOF

git add frontend/index.html
git commit -m "Add problematic code - version $PROBLEM_VERSION" || echo "변경사항 없음"
git push origin main

# 이미지 빌드
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-problem-$PROBLEM_VERSION-
  namespace: default
spec:
  pipelineRef:
    name: frontend-pipeline-ci
  params:
  - name: docker-image
    value: 192.168.0.169:443/project/error-archive-frontend:$PROBLEM_VERSION
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

echo "✓ 문제 버전 빌드 시작"
echo ""

# 2단계: 문제 버전 배포
echo "2단계: 문제 버전 배포..."
sed -i "s|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:$PROBLEM_VERSION|g" k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy problematic version $PROBLEM_VERSION" || echo "변경사항 없음"
git push origin main
echo "✓ 문제 버전 배포 완료"
echo ""

# 3단계: 문제 발견 및 롤백
echo "3단계: 문제 발견 및 롤백..."
sleep 10
echo "문제 확인 중..."
kubectl logs deployment/frontend -n error-archive --tail=5 2>&1 | grep -i error || echo "로그 확인 완료"
echo ""

echo "롤백 실행 중..."
sed -i "s|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:$STABLE_VERSION|g" k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Rollback to stable version $STABLE_VERSION" || echo "변경사항 없음"
git push origin main
echo "✓ 롤백 완료"
echo ""

echo "=========================================="
echo "  롤백 완료!"
echo "=========================================="
echo ""
echo "롤백 상태 확인:"
echo "  kubectl rollout status deployment/frontend -n error-archive"
echo "  kubectl get pods -n error-archive -l app=frontend"

