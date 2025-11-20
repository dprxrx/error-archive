#!/bin/bash
# 가을 테마로 빠른 전환 (복붙용)
cd /home/kevin/error-archive
cp demo/themes/autumn/list.html frontend/list.html
cp demo/themes/autumn/index.html frontend/index.html
git add frontend/list.html frontend/index.html
git commit -m "feat: 가을 테마 적용"
echo "Git 푸시: git push origin main"
