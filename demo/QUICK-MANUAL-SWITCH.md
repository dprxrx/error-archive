# 빠른 수동 전환 (복붙용)

## 겨울 테마로 전환

```bash
# 1. 소스코드 변경
cd /home/kevin/error-archive
cp demo/themes/winter/index.html frontend/index.html
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/roulette.html frontend/roulette.html

# 2. Git 커밋 및 푸시
git add frontend/index.html frontend/list.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용"
git push origin main

# 3. Tekton 빌드
IMAGE_TAG="winter-$(date +%Y%m%d-%H%M%S)"
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-winter-theme-
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
    value: 192.168.0.169:443/project/error-archive-frontend:$IMAGE_TAG
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
