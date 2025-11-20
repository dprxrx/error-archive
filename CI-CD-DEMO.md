# CI/CD 시연 가이드 - 배너 추가 및 롤백

## 시연 시나리오
1. Frontend에 배너 추가 (버전 1.4)
2. 자동 빌드 및 배포
3. 배포 확인
4. 롤백 (버전 1.3으로 복구)

---

## 1단계: 소스 코드 수정 (배너 추가)

### Frontend 배너 추가
```bash
cd /home/kevin/proj/error-archive-1

# index.html에 배너 추가
cat >> frontend/index.html << 'BANNER_EOF'

<!-- 배너 추가 (버전 1.4) -->
<div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); color: white; padding: 8px; text-align: center; font-size: 14px; font-weight: bold; position: fixed; top: 0; left: 0; right: 0; z-index: 9999; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">
  🚀 CI/CD 자동 배포 성공! 버전 1.4 배포 완료
</div>
<style>
  body { padding-top: 40px; }
</style>
BANNER_EOF
```

---

## 2단계: Git 커밋 및 푸시

```bash
cd /home/kevin/proj/error-archive-1

git add frontend/index.html
git commit -m "Add banner for version 1.4 - CI/CD demo"
git push origin main
```

---

## 3단계: CI Pipeline 실행 (이미지 빌드 및 푸시)

### Frontend 1.4 이미지 빌드
```bash
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-demo-1.4-
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
    value: 192.168.0.169:443/project/error-archive-frontend:1.4
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

### 빌드 상태 확인
```bash
# PipelineRun 상태 확인
kubectl get pipelineruns | grep frontend-demo-1.4

# 완료 대기 (약 1-2분)
watch -n 5 'kubectl get pipelineruns | grep frontend-demo-1.4'
```

---

## 4단계: Kubernetes 매니페스트 업데이트

```bash
cd /home/kevin/proj/error-archive-1

# Frontend 이미지 버전 업데이트 (1.3 → 1.4)
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.4|g' k8s/error-archive/frontend-deployment.yaml

# 변경사항 확인
grep "image:" k8s/error-archive/frontend-deployment.yaml
```

---

## 5단계: Git에 매니페스트 푸시 (ArgoCD 자동 배포)

```bash
cd /home/kevin/proj/error-archive-1

git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy frontend version 1.4 with banner"
git push origin main
```

---

## 6단계: ArgoCD 자동 배포 확인

```bash
# ArgoCD Application 상태 확인
kubectl get applications -n argocd

# 배포 상태 확인
kubectl get deployments -n error-archive

# Pod 상태 확인
kubectl get pods -n error-archive -l app=frontend

# 실시간 모니터링
watch -n 2 'kubectl get deployments -n error-archive -o custom-columns=NAME:.metadata.name,IMAGE:.spec.template.spec.containers[0].image,READY:.status.readyReplicas/..spec.replicas'
```

---

## 7단계: 배포 확인 (웹사이트 접속)

```bash
# Frontend Service 확인
kubectl get svc -n error-archive frontend

# 브라우저에서 접속하여 배너 확인
# LoadBalancer IP 또는 NodePort로 접속
```

---

## 8단계: 롤백 (버전 1.3으로 복구)

### 방법 1: Git Revert (권장)
```bash
cd /home/kevin/proj/error-archive-1

# 매니페스트만 롤백 (이전 커밋으로)
git log --oneline k8s/error-archive/frontend-deployment.yaml | head -5

# 이전 버전으로 복구
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.3|g' k8s/error-archive/frontend-deployment.yaml

git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Rollback frontend to version 1.3"
git push origin main
```

### 방법 2: ArgoCD CLI 사용
```bash
# ArgoCD CLI로 롤백
argocd app rollback error-archive-frontend

# 또는 특정 리비전으로 롤백
argocd app rollback error-archive-frontend <revision-hash>
```

### 방법 3: kubectl로 직접 롤백
```bash
# Deployment 이미지 직접 변경
kubectl set image deployment/frontend nginx=192.168.0.169:443/project/error-archive-frontend:1.3 -n error-archive

# 롤아웃 상태 확인
kubectl rollout status deployment/frontend -n error-archive
```

---

## 롤백 확인

```bash
# 배포 상태 확인
kubectl get deployments -n error-archive -o wide

# Pod 이미지 확인
kubectl get pods -n error-archive -l app=frontend -o jsonpath='{.items[0].spec.containers[0].image}'
echo ""

# 웹사이트에서 배너가 사라졌는지 확인
```

---

## 전체 시연 스크립트 (한 번에 실행)

```bash
#!/bin/bash
# CI/CD 시연 전체 스크립트

cd /home/kevin/proj/error-archive-1

echo "=== 1단계: 배너 추가 ==="
cat >> frontend/index.html << 'BANNER_EOF'

<!-- 배너 추가 (버전 1.4) -->
<div style="background: linear-gradient(90deg, #667eea 0%, #764ba2 100%); color: white; padding: 8px; text-align: center; font-size: 14px; font-weight: bold; position: fixed; top: 0; left: 0; right: 0; z-index: 9999; box-shadow: 0 2px 4px rgba(0,0,0,0.2);">
  🚀 CI/CD 자동 배포 성공! 버전 1.4 배포 완료
</div>
<style>
  body { padding-top: 40px; }
</style>
BANNER_EOF

echo "=== 2단계: Git 커밋 및 푸시 ==="
git add frontend/index.html
git commit -m "Add banner for version 1.4 - CI/CD demo"
git push origin main

echo "=== 3단계: CI Pipeline 실행 ==="
kubectl create -f - <<EOF
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: frontend-demo-1.4-
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
    value: 192.168.0.169:443/project/error-archive-frontend:1.4
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

echo "빌드 완료 대기 중... (약 1-2분)"
sleep 90

echo "=== 4단계: 매니페스트 업데이트 ==="
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.4|g' k8s/error-archive/frontend-deployment.yaml

echo "=== 5단계: Git 푸시 (ArgoCD 자동 배포) ==="
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy frontend version 1.4 with banner"
git push origin main

echo ""
echo "=== 배포 완료! ==="
echo "ArgoCD가 자동으로 배포를 시작합니다."
echo "상태 확인: kubectl get applications -n argocd"
echo "배포 확인: kubectl get deployments -n error-archive"
```

---

## 롤백 스크립트

```bash
#!/bin/bash
# 롤백 스크립트

cd /home/kevin/proj/error-archive-1

echo "=== 롤백: 버전 1.3으로 복구 ==="

# 매니페스트 롤백
sed -i 's|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:1.3|g' k8s/error-archive/frontend-deployment.yaml

# Git 커밋 및 푸시
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Rollback frontend to version 1.3"
git push origin main

echo ""
echo "=== 롤백 완료! ==="
echo "ArgoCD가 자동으로 롤백을 시작합니다."
echo "상태 확인: kubectl get deployments -n error-archive"
```

---

## 빠른 참조 명령어

### 배포 상태 확인
```bash
kubectl get deployments -n error-archive
kubectl get pods -n error-archive -l app=frontend
kubectl get applications -n argocd
```

### 로그 확인
```bash
kubectl logs -f deployment/frontend -n error-archive
```

### 수동 롤백 (긴급)
```bash
kubectl set image deployment/frontend nginx=192.168.0.169:443/project/error-archive-frontend:1.3 -n error-archive
kubectl rollout status deployment/frontend -n error-archive
```

