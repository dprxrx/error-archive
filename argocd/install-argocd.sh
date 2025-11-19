#!/bin/bash
# ArgoCD 설치 스크립트

echo "=== ArgoCD 설치 시작 ==="

# ArgoCD 네임스페이스 생성
kubectl create namespace argocd 2>/dev/null || echo "argocd 네임스페이스가 이미 존재합니다."

# ArgoCD 설치 (최신 안정 버전)
echo "ArgoCD 설치 중..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo ""
echo "=== ArgoCD 설치 완료 ==="
echo ""
echo "ArgoCD 서버 접근 방법:"
echo ""
echo "1. Port Forward 사용:"
echo "   kubectl port-forward svc/argocd-server -n argocd 8080:443"
echo "   브라우저에서 https://localhost:8080 접속"
echo ""
echo "2. 초기 admin 비밀번호 확인:"
echo "   kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath=\"{.data.password}\" | base64 -d"
echo ""
echo "3. ArgoCD CLI 설치 (선택사항):"
echo "   curl -sSL -o /usr/local/bin/argocd https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64"
echo "   chmod +x /usr/local/bin/argocd"
echo ""
echo "4. Application 배포:"
echo "   kubectl apply -f argocd/backend-application.yaml"
echo "   kubectl apply -f argocd/frontend-application.yaml"

