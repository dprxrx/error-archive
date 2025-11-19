#!/bin/bash
# Tekton Completed Pod 정리 스크립트

echo "=== Tekton Completed Pod 정리 ==="

# 1. 오래된 Completed PipelineRun Pod 정리 (24시간 이상 된 것)
echo "1. 오래된 Completed Pod 정리 중..."
kubectl get pods -l tekton.dev/pipelineRun --field-selector=status.phase=Succeeded -o json | \
  jq -r '.items[] | select(.status.startTime != null) | select((now - (.status.startTime | fromdateiso8601)) > 86400) | .metadata.name' | \
  while read pod; do
    if [ -n "$pod" ]; then
      echo "  삭제: $pod"
      kubectl delete pod $pod --ignore-not-found=true
    fi
  done

# 2. Completed TaskRun Pod 정리 (24시간 이상 된 것)
echo "2. 오래된 Completed TaskRun Pod 정리 중..."
kubectl get pods -l tekton.dev/taskRun --field-selector=status.phase=Succeeded -o json | \
  jq -r '.items[] | select(.status.startTime != null) | select((now - (.status.startTime | fromdateiso8601)) > 86400) | .metadata.name' | \
  while read pod; do
    if [ -n "$pod" ]; then
      echo "  삭제: $pod"
      kubectl delete pod $pod --ignore-not-found=true
    fi
  done

# 3. 모든 Completed PipelineRun Pod 정리 (강제)
if [ "$1" == "--all" ]; then
  echo "3. 모든 Completed Pod 강제 정리 중..."
  kubectl get pods -l tekton.dev/pipelineRun --field-selector=status.phase=Succeeded -o jsonpath='{.items[*].metadata.name}' | \
    tr ' ' '\n' | \
    while read pod; do
      if [ -n "$pod" ]; then
        echo "  삭제: $pod"
        kubectl delete pod $pod --ignore-not-found=true
      fi
    done
  
  kubectl get pods -l tekton.dev/taskRun --field-selector=status.phase=Succeeded -o jsonpath='{.items[*].metadata.name}' | \
    tr ' ' '\n' | \
    while read pod; do
      if [ -n "$pod" ]; then
        echo "  삭제: $pod"
        kubectl delete pod $pod --ignore-not-found=true
      fi
    done
fi

# 4. PipelineRun 삭제 (선택사항)
if [ "$1" == "--pipelineruns" ]; then
  echo "4. 오래된 PipelineRun 삭제 중..."
  kubectl get pipelineruns -o json | \
    jq -r '.items[] | select(.status.completionTime != null) | select((now - (.status.completionTime | fromdateiso8601)) > 86400) | .metadata.name' | \
    while read pr; do
      if [ -n "$pr" ]; then
        echo "  삭제: $pr"
        kubectl delete pipelinerun $pr --ignore-not-found=true
      fi
    done
fi

echo ""
echo "=== 정리 완료 ==="
echo ""
echo "사용법:"
echo "  ./cleanup.sh           - 24시간 이상 된 Completed Pod 정리"
echo "  ./cleanup.sh --all      - 모든 Completed Pod 강제 정리"
echo "  ./cleanup.sh --pipelineruns - 오래된 PipelineRun 삭제"

