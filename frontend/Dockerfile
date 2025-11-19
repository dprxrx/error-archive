# ===============================
# ✅ Error Archive Frontend (Nginx)
# ===============================
FROM nginx:latest

# 기본 nginx 설정 및 페이지 제거
RUN rm -rf /usr/share/nginx/html/* /etc/nginx/conf.d/default.conf

# 정적 파일 복사 (현재 폴더 내의 html, css 등)
COPY ./ /var/www/html/

# 커스텀 설정 파일 복사
COPY nginx.conf /etc/nginx/conf.d/errorarchive.conf

# 심볼릭 링크로 nginx 기본 루트 연결
RUN ln -sf /var/www/html /usr/share/nginx/html

# 포트 노출
EXPOSE 80

# nginx 실행
CMD ["nginx", "-g", "daemon off;"]

