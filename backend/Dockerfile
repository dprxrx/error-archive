# ===============================
# ✅ Error Archive Backend (Node.js)
# ===============================
FROM node:18

# 작업 디렉토리 생성
WORKDIR /app

# package.json만 먼저 복사 후 종속성 설치
COPY package*.json ./
RUN npm install

# 소스 복사
COPY . .

# 환경 변수 설정 (필요 시 수정)
ENV PORT=3000

# 외부 포트 노출
EXPOSE 3000

# 서버 실행
CMD ["node", "server.js"]
