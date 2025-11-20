#!/bin/bash
# 겨울 테마로 빠른 전환 (복붙용)
cd /home/kevin/error-archive
cp demo/themes/winter/list.html frontend/list.html
cp demo/themes/winter/index.html frontend/index.html
cp demo/themes/winter/roulette.html frontend/roulette.html
git add frontend/list.html frontend/index.html frontend/roulette.html
git commit -m "feat: 겨울 테마 적용"
echo "Git 푸시: git push origin main"
