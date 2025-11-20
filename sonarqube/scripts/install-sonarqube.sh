#!/bin/bash

set -e

echo "=========================================="
echo "  SonarQube 설치"
echo "=========================================="

# 네임스페이스 생성
echo "1. 네임스페이스 생성 중..."
kubectl apply -f sonarqube/manifests/namespace.yaml

# PostgreSQL 배포
echo "2. PostgreSQL 배포 중..."
kubectl apply -f sonarqube/manifests/postgresql.yaml

# PostgreSQL 준비 대기
echo "3. PostgreSQL 준비 대기 중..."
kubectl wait --for=condition=ready pod -l app=sonarqube-postgresql -n sonarqube --timeout=120s

# SonarQube 배포
echo "4. SonarQube 배포 중..."
kubectl apply -f sonarqube/manifests/sonarqube.yaml

# SonarQube 준비 대기
echo "5. SonarQube 준비 대기 중 (최대 5분)..."
kubectl wait --for=condition=ready pod -l app=sonarqube -n sonarqube --timeout=300s || echo "⚠️  SonarQube 시작 중... 잠시 후 확인하세요."

echo ""
echo "=========================================="
echo "  SonarQube 설치 완료!"
echo "=========================================="
echo ""
echo "접속 정보:"
echo "  - 서비스 확인: kubectl get svc -n sonarqube"
echo "  - Pod 상태: kubectl get pods -n sonarqube"
echo "  - 로그 확인: kubectl logs -f deployment/sonarqube -n sonarqube"
echo ""
echo "포트 포워딩:"
echo "  kubectl port-forward svc/sonarqube -n sonarqube 9000:9000"
echo ""
echo "기본 접속:"
echo "  URL: http://localhost:9000"
echo "  기본 계정: admin / admin"
echo "  (첫 로그인 시 비밀번호 변경 필요)"
echo ""

