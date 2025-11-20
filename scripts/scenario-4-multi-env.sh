#!/bin/bash
# 시나리오 4: 다중 환경 배포

VERSION=${1:-"1.6"}

cd /home/kevin/proj/error-archive-1

echo "=========================================="
echo "  시나리오 4: 다중 환경 배포"
echo "  버전: $VERSION"
echo "=========================================="
echo ""

# 1단계: 개발 환경
echo "1단계: 개발 환경 배포..."
kubectl create namespace error-archive-dev 2>/dev/null || echo "네임스페이스 이미 존재"

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-dev
  namespace: error-archive-dev
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend
      env: dev
  template:
    metadata:
      labels:
        app: frontend
        env: dev
    spec:
      containers:
      - name: nginx
        image: 192.168.0.169:443/project/error-archive-frontend:$VERSION
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 100m
            memory: 64Mi
          requests:
            cpu: 50m
            memory: 32Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-dev
  namespace: error-archive-dev
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: frontend
    env: dev
EOF
echo "✓ 개발 환경 배포 완료"
echo ""

# 2단계: 스테이징 환경
echo "2단계: 스테이징 환경 배포..."
kubectl create namespace error-archive-staging 2>/dev/null || echo "네임스페이스 이미 존재"

kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-staging
  namespace: error-archive-staging
spec:
  replicas: 2
  selector:
    matchLabels:
      app: frontend
      env: staging
  template:
    metadata:
      labels:
        app: frontend
        env: staging
    spec:
      containers:
      - name: nginx
        image: 192.168.0.169:443/project/error-archive-frontend:$VERSION
        ports:
        - containerPort: 80
        resources:
          limits:
            cpu: 150m
            memory: 128Mi
          requests:
            cpu: 50m
            memory: 64Mi
---
apiVersion: v1
kind: Service
metadata:
  name: frontend-staging
  namespace: error-archive-staging
spec:
  type: ClusterIP
  ports:
  - port: 80
    targetPort: 80
  selector:
    app: frontend
    env: staging
EOF
echo "✓ 스테이징 환경 배포 완료"
echo ""

# 3단계: 프로덕션 환경
echo "3단계: 프로덕션 환경 배포..."
sed -i "s|192.168.0.169:443/project/error-archive-frontend:.*|192.168.0.169:443/project/error-archive-frontend:$VERSION|g" k8s/error-archive/frontend-deployment.yaml
git add k8s/error-archive/frontend-deployment.yaml
git commit -m "Deploy to production - version $VERSION" || echo "변경사항 없음"
git push origin main
echo "✓ 프로덕션 환경 배포 완료"
echo ""

# 4단계: 환경별 상태 확인
echo "4단계: 환경별 상태 확인..."
echo ""
echo "=== 개발 환경 ==="
kubectl get pods -n error-archive-dev
echo ""
echo "=== 스테이징 환경 ==="
kubectl get pods -n error-archive-staging
echo ""
echo "=== 프로덕션 환경 ==="
kubectl get pods -n error-archive
echo ""

echo "=========================================="
echo "  다중 환경 배포 완료!"
echo "=========================================="

