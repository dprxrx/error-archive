// ===============================
// ❌ 취약한 코드 예시
// ===============================

// 1. SQL Injection 취약점
app.post('/api/posts/search', async (req, res) => {
  const { keyword } = req.body;
  // 직접 쿼리 문자열에 사용자 입력 삽입 (위험!)
  const query = `SELECT * FROM posts WHERE title LIKE '%${keyword}%'`;
  const result = await db.query(query);
  res.json(result);
});

// 2. 하드코딩된 비밀번호
const ADMIN_PASSWORD = "admin123";
if (password === ADMIN_PASSWORD) {
  // 관리자 권한 부여
}

// 3. 민감 정보 로깅
console.log("User login:", username, password);

// 4. MongoDB 연결 문자열에 하드코딩된 비밀번호
mongoose.connect("mongodb+srv://user:password123@cluster.mongodb.net/db");
