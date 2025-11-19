// ===============================
// ✅ Error Archive Backend Server
// ===============================
const express = require("express");
const cors = require("cors");
const mongoose = require("mongoose");
const axios = require("axios");
const jwt = require("jsonwebtoken");
require("dotenv").config();

const app = express();

// ===============================
// ✅ PUBLIC_IP 설정 (환경변수 없이도 기본값 작동)
// ===============================
const PUBLIC_IP = process.env.PUBLIC_IP || "http://localhost:3000"; // 환경 변수가 없으면 로컬 기본값 사용

// ===============================
// ✅ CORS 설정
// ===============================
app.use(cors({
  origin: "*",
  methods: ["GET", "POST", "DELETE"],
  allowedHeaders: ["Content-Type"]
}));
app.use(express.json());

// ===============================
// ✅ MongoDB 연결
// ===============================
mongoose.connect("mongodb+srv://errorAdmin:pass123%23@errorarchive.bjd5r0c.mongodb.net/errorArch?retryWrites=true&w=majority")
  .then(() => console.log("✅ MongoDB Atlas connected"))
  .catch(err => console.error("❌ MongoDB Atlas connection error:", err));

// ===============================
// ✅ 스키마 정의
// ===============================

// 🔹 사용자(User)
const userSchema = new mongoose.Schema({
  userId: String,
  password: String,
  name: String,
  email: String,
  role: String,
  provider: String
});

// 🔹 게시글(ErrorPost)
const errorPostSchema = new mongoose.Schema({
  title: String,
  author: String,
  createdAt: Date,
  category: Number,
  errorContent: String,
  solutionContent: String,
  likes: Number,
  dislikes: Number,
  views: Number,
  approved: Boolean
});

// 🔹 댓글(CommentGroup)
const commentSchema = new mongoose.Schema({
  authorId: String,
  content: String,
  createdAt: { type: Date, default: Date.now }
});

const commentsGroupSchema = new mongoose.Schema({
  postId: { type: mongoose.Schema.Types.ObjectId, ref: "ErrorPost", required: true },
  comments: [commentSchema]
});

// ===============================
// ✅ 모델 등록
// ===============================
const User = mongoose.model("User", userSchema, "User");
const ErrorPost = mongoose.model("ErrorPost", errorPostSchema, "ErrorPosts");
const CommentGroup = mongoose.model("CommentGroup", commentsGroupSchema, "Comments");

// ===============================
// ✅ 게시글 관련 라우트
// ===============================

// 🔹 게시글 목록
app.get("/api/posts", async (req, res) => {
  try {
    const category = parseInt(req.query.category);
    const role = req.query.role;
    const mode = req.query.mode;
    const author = req.query.author;

    let query = {};

    if (mode === "my" && author) query.author = author;
    else if (role === "admin") query.approved = false;
    else query.approved = true;

    if (!isNaN(category) && category !== 0) query.category = category;

    const posts = await ErrorPost.find(query)
      .sort({ createdAt: -1 })
      .select("title author createdAt category approved");

    res.json(posts);
  } catch (err) {
    console.error("❌ Error loading posts:", err);
    res.status(500).json({ message: "서버 오류" });
  }
});

// 🔹 게시글 상세조회 (+ 댓글 포함)
app.get("/api/post/:id", async (req, res) => {
  try {
    const postId = req.params.id;
    const post = await ErrorPost.findById(postId).lean();
    if (!post) return res.status(404).json({ message: "게시글을 찾을 수 없습니다." });

    const commentGroup = await CommentGroup.findOne({ postId: post._id }).lean();
    post.comments = commentGroup ? commentGroup.comments : [];

    res.json(post);
  } catch (err) {
    console.error("❌ 게시글 조회 실패:", err);
    res.status(500).json({ message: "서버 오류" });
  }
});

// 🔹 게시글 작성
app.post("/api/posts/new", async (req, res) => {
  try {
    const { title, author, category, errorContent, solutionContent } = req.body;
    if (!title || !author || !errorContent)
      return res.status(400).json({ success: false, message: "필수 입력값 누락" });

    const newPost = new ErrorPost({
      title,
      author,
      category: parseInt(category) || 6,
      errorContent,
      solutionContent,
      likes: 0,
      dislikes: 0,
      views: 0,
      approved: false,
      createdAt: new Date()
    });

    await newPost.save();
    res.json({ success: true, message: "게시글 등록 완료!" });
  } catch (err) {
    console.error("❌ 게시글 등록 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// 🔹 게시글 수정
app.post("/api/post/:id", async (req, res) => {
  try {
    const { id } = req.params;
    const { title, category, errorContent, solutionContent } = req.body;

    const post = await ErrorPost.findById(id);
    if (!post) return res.status(404).json({ success: false, message: "게시글 없음" });

    post.title = title || post.title;
    post.category = category ? parseInt(category) : post.category;
    post.errorContent = errorContent || post.errorContent;
    post.solutionContent = solutionContent || post.solutionContent;

    await post.save();
    res.json({ success: true, message: "게시글 수정 완료" });
  } catch (err) {
    console.error("❌ 게시글 수정 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// 🔹 게시글 삭제
app.delete("/api/post/:id", async (req, res) => {
  try {
    const { id } = req.params;
    await ErrorPost.findByIdAndDelete(id);
    await CommentGroup.deleteOne({ postId: id });
    res.json({ success: true, message: "게시글 삭제 완료" });
  } catch (err) {
    console.error("❌ 게시글 삭제 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// 🔹 게시글 승인 (관리자)
app.post("/api/post/:id/approve", async (req, res) => {
  try {
    const { id } = req.params;
    const post = await ErrorPost.findById(id);
    if (!post) return res.status(404).json({ success: false, message: "게시글 없음" });
    post.approved = true;
    await post.save();
    res.json({ success: true, message: "게시글 승인 완료" });
  } catch (err) {
    console.error("❌ 게시글 승인 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// 🔹 추천 / 비추천
app.post("/api/post/:id/vote", async (req, res) => {
  try {
    const { id } = req.params;
    const { type } = req.body;
    const post = await ErrorPost.findById(id);
    if (!post) return res.status(404).json({ success: false, message: "게시글 없음" });

    if (type === "up") post.likes = (post.likes || 0) + 1;
    else if (type === "down") post.dislikes = (post.dislikes || 0) + 1;
    else return res.status(400).json({ success: false, message: "잘못된 요청" });

    await post.save();
    res.json({ success: true, likes: post.likes, dislikes: post.dislikes });
  } catch (err) {
    console.error("❌ 추천/비추천 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// =============================
// 🔍 게시글 검색 기능 API (승인 상태 반영)
// =============================
app.get("/api/posts/search", async (req, res) => {
  const { type, keyword, role } = req.query;
  console.log("검색 요청:", type, keyword, role);

  try {
    let query = {};
    if (role !== "admin") query.approved = true;

    if (type === "제목+내용") {
      query.$text = { $search: keyword };
      const results = await ErrorPost.find(query, { score: { $meta: "textScore" } })
        .sort({ score: { $meta: "textScore" } });
      return res.json(results);
    }

    if (type === "작성자") {
      query.author = { $regex: keyword, $options: "i" };
      const results = await ErrorPost.find(query);
      return res.json(results);
    }

    res.json([]);
  } catch (err) {
    console.error("검색 오류:", err);
    res.status(500).json({ error: "검색 중 오류 발생" });
  }
});

// ===============================
// ✅ 댓글 관련 라우트
// ===============================
app.post("/api/posts/:postId/comment", async (req, res) => {
  const { postId } = req.params;
  const { authorId, content } = req.body;
  try {
    const existing = await CommentGroup.findOne({ postId });
    const newComment = { authorId, content, createdAt: new Date() };
    if (existing) await CommentGroup.updateOne({ postId }, { $push: { comments: newComment } });
    else {
      const newGroup = new CommentGroup({ postId, comments: [newComment] });
      await newGroup.save();
    }
    res.json({ success: true, message: "댓글 추가 완료" });
  } catch (err) {
    console.error("❌ 댓글 추가 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

app.get("/api/posts/:postId/comments", async (req, res) => {
  try {
    const group = await CommentGroup.findOne({ postId: req.params.postId });
    if (!group) return res.json([]);
    res.json(group.comments);
  } catch (err) {
    console.error("❌ 댓글 조회 오류:", err);
    res.status(500).json({ message: "서버 오류" });
  }
});

// ===============================
// ✅ 사용자 인증 / 계정 관련
// ===============================
app.post("/api/login", async (req, res) => {
  const { login, pw } = req.body;
  try {
    const user = await User.findOne({ userId: login });
    if (!user) return res.json({ success: false, message: "존재하지 않는 사용자" });
    if (user.password !== pw) return res.json({ success: false, message: "비밀번호 불일치" });

    res.json({ success: true, user: { name: user.name, userId: user.userId, role: user.role } });
  } catch (err) {
    console.error(err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// 🔹 ID 찾기 (이메일로)
app.post("/api/find_id", async (req, res) => {
  try {
    const { "find-email": email } = req.body;
    if (!email) return res.status(400).json({ success: false, message: "이메일이 필요합니다." });

    const user = await User.findOne({ email });
    if (!user) return res.json({ success: false, message: "해당 이메일로 등록된 계정이 없습니다." });

    res.json({ success: true, message: `해당 이메일의 ID는 ${user.userId} 입니다.` });
  } catch (err) {
    console.error("❌ ID 찾기 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// 🔹 PW 찾기 (아이디 + 이메일로)
app.post("/api/find_pw", async (req, res) => {
  try {
    const { "find-id": userId, "find-email2": email } = req.body;
    if (!userId || !email)
      return res.status(400).json({ success: false, message: "아이디와 이메일이 필요합니다." });

    const user = await User.findOne({ userId, email });
    if (!user) return res.json({ success: false, message: "일치하는 계정이 없습니다." });

    res.json({ success: true, message: `해당 계정의 비밀번호는 ${user.password} 입니다.` });
  } catch (err) {
    console.error("❌ PW 찾기 오류:", err);
    res.status(500).json({ success: false, message: "서버 오류" });
  }
});

// 🔹 회원가입 / 중복체크 / 찾기
app.get("/api/check-id", async (req, res) => {
  const { userid } = req.query;
  const exist = await User.findOne({ userId: userid });
  res.json({ exists: !!exist });
});

app.get("/api/check-email", async (req, res) => {
  const { email } = req.query;
  const exist = await User.findOne({ email });
  res.json({ exists: !!exist });
});

app.post("/api/signup", async (req, res) => {
  const { userid, email, pw, name } = req.body;
  if (!userid || !email || !pw || !name)
    return res.status(400).json({ success: false, message: "필수 입력값 누락" });

  const existUser = await User.findOne({ $or: [{ userId: userid }, { email }] });
  if (existUser)
    return res.json({ success: false, message: "이미 존재하는 아이디 또는 이메일입니다." });

  const newUser = new User({
    userId: userid,
    email,
    password: pw,
    name,
    role: "user",
    provider: "local"
  });
  await newUser.save();
  res.json({ success: true, message: "회원가입 완료!" });
});

// ===============================
// ✅ 카카오 로그인 (PUBLIC_IP 적용)
// ===============================
app.get("/auth/kakao", (req, res) => {
  // 하드코딩된 주소 대신 PUBLIC_IP 환경 변수를 사용
  const redirectUri = `${PUBLIC_IP}/auth/kakao/callback`;
  const clientId = process.env.KAKAO_CLIENT_ID;
  const kakaoAuthURL =
    `https://kauth.kakao.com/oauth/authorize?response_type=code&client_id=${clientId}&redirect_uri=${redirectUri}`;
  res.redirect(kakaoAuthURL);
});

// 🔹 카카오 콜백 (PUBLIC_IP 적용)
app.get("/auth/kakao/callback", async (req, res) => {
  const code = req.query.code;
  const tokenUrl = "https://kauth.kakao.com/oauth/token";

  try {
    // 1️⃣ 토큰 요청
    const tokenResponse = await axios.post(tokenUrl, null, {
      params: {
        grant_type: "authorization_code",
        client_id: process.env.KAKAO_CLIENT_ID,
        redirect_uri: `${PUBLIC_IP}/auth/kakao/callback`,
        code
      },
      headers: { "Content-Type": "application/x-www-form-urlencoded;charset=utf-8" }
    });

    const { access_token } = tokenResponse.data;

    // 2️⃣ 사용자 정보 요청
    const userResponse = await axios.get("https://kapi.kakao.com/v2/user/me", {
      headers: { Authorization: `Bearer ${access_token}` }
    });

    const kakaoUser = userResponse.data;
    const kakaoAccount = kakaoUser.kakao_account || {};
    const profile = kakaoAccount.profile || {};

    const email = kakaoAccount.email || `${kakaoUser.id}@kakao.com`;
    const name = profile.nickname || "카카오사용자";

    // 3️⃣ DB에 사용자 등록 or 기존 계정 불러오기
    let user = await User.findOne({ email });
    if (!user) {
      user = new User({
        userId: `kakao_${kakaoUser.id}`,
        name,
        email,
        role: "user",
        provider: "kakao"
      });
      await user.save();
      console.log(`🆕 신규 카카오 사용자 등록: ${name}`);
    }

    // 4️⃣ JWT 발급
    const token = jwt.sign(
      {
        userId: user.userId,
        name: encodeURIComponent(user.name),
        email: user.email
      },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    // 5️⃣ 프론트로 리디렉션 (PUBLIC_IP 사용)
    res.redirect(`${PUBLIC_IP}/loginSuccess.html?token=${token}`);

  } catch (err) {
    console.error("❌ Kakao OAuth Error:", err);
    res.status(500).send("Kakao login failed");
  }
});

// ===============================
// ✅ 네이버 로그인 (PUBLIC_IP 적용)
// ===============================
app.get("/auth/naver", (req, res) => {
  const redirectUri = `${PUBLIC_IP}/auth/naver/callback`;
  const clientId = process.env.NAVER_CLIENT_ID;
  const state = "naver_" + Date.now();
  const naverAuthURL =
    `https://nid.naver.com/oauth2.0/authorize?response_type=code&client_id=${clientId}&redirect_uri=${redirectUri}&state=${state}`;
  res.redirect(naverAuthURL);
});

// 🔹 네이버 콜백 (PUBLIC_IP 적용)
app.get("/auth/naver/callback", async (req, res) => {
  const { code, state } = req.query;
  try {
    const tokenResponse = await axios.get("https://nid.naver.com/oauth2.0/token", {
      params: {
        grant_type: "authorization_code",
        client_id: process.env.NAVER_CLIENT_ID,
        client_secret: process.env.NAVER_CLIENT_SECRET,
        code,
        state
      }
    });

    const { access_token } = tokenResponse.data;
    const userResponse = await axios.get("https://openapi.naver.com/v1/nid/me", {
      headers: { Authorization: `Bearer ${access_token}` }
    });

    const naverUser = userResponse.data.response;
    const email = naverUser.email;
    const name = naverUser.name || "네이버사용자";

    let user = await User.findOne({ email });
    if (!user) {
      user = new User({
        userId: `naver_${naverUser.id}`,
        name,
        email,
        role: "user",
        provider: "naver"
      });
      await user.save();
      console.log(`🆕 신규 네이버 사용자 등록: ${name}`);
    }

    const token = jwt.sign(
      { userId: user.userId, name: encodeURIComponent(user.name), email: user.email },
      process.env.JWT_SECRET,
      { expiresIn: "1h" }
    );

    // ✅ 프론트로 리디렉션
    res.redirect(`${PUBLIC_IP}/loginSuccess.html?token=${token}`);

  } catch (err) {
    console.error("❌ Naver OAuth Error:", err);
    res.status(500).send("Naver login failed");
  }
});

// ===============================
// ✅ 챗봇 관련 스키마
// ===============================
const chatbotLogSchema = new mongoose.Schema({
  question: String,
  answer: String,
  intent: String,
  timestamp: { type: Date, default: Date.now },
  userId: String
});

const ChatbotLog = mongoose.model("ChatbotLog", chatbotLogSchema, "ChatbotLogs");

// ===============================
// ✅ 챗봇 API
// ===============================

// 챗봇 응답 생성
function getChatbotResponse(message, intent, history = []) {
  const msg = message.toLowerCase().trim();
  
  // 컨텍스트 기반 응답 (대화 히스토리 활용)
  if (history.length > 0) {
    const lastMessage = history[history.length - 1];
    if (lastMessage && lastMessage.text && lastMessage.text.includes('로그인')) {
      if (msg.includes('카카오') || msg.includes('네이버')) {
        return '네! 카카오나 네이버 계정으로 간편하게 로그인할 수 있어요. 로그인 페이지에서 해당 버튼을 클릭하시면 됩니다.';
      }
    }
  }

  // 의도별 응답
  switch(intent) {
    case 'greeting':
      return '안녕하세요! Error Archive 챗봇입니다. 무엇을 도와드릴까요?';
    
    case 'login':
      return '로그인 페이지에서 아이디와 비밀번호를 입력하시면 됩니다. 카카오나 네이버 계정으로도 로그인할 수 있어요!';
    
    case 'signup':
      return '회원가입은 상단의 "회원가입" 링크를 클릭하시면 됩니다. 간단한 정보만 입력하시면 바로 가입할 수 있어요!';
    
    case 'password':
      return '비밀번호를 찾으시려면 상단의 "ID/PW 찾기" 링크를 이용해주세요. 이메일로 비밀번호 재설정 링크를 보내드립니다.';
    
    case 'help':
      return '다음과 같은 질문에 답변할 수 있어요:\n- 로그인 방법\n- 회원가입\n- 비밀번호 찾기\n- 서비스 소개\n- 에러 로그 관리 방법';
    
    case 'service':
      return 'Error Archive는 에러 로그를 관리하고 분석하는 서비스입니다. 개발자들이 에러를 체계적으로 관리하고, 해결 방법을 공유할 수 있도록 도와드려요!';
    
    case 'error':
      return '에러 로그를 관리하고 싶으시다면 로그인 후 게시판에서 에러를 등록하고 해결 방법을 공유할 수 있어요! 다른 개발자들의 도움도 받을 수 있습니다.';
    
    case 'thanks':
      return '천만에요! 😊 다른 도움이 필요하시면 언제든지 말씀해주세요!';
    
    default:
      // 키워드 기반 응답
      if (msg.includes('에러') || msg.includes('오류')) {
        return '에러 로그를 등록하거나 검색하고 싶으시다면 로그인 후 게시판을 이용해주세요!';
      }
      if (msg.includes('게시판') || msg.includes('글')) {
        return '게시판에서는 에러 로그를 등록하고, 다른 개발자들의 해결 방법을 확인할 수 있어요. 로그인 후 이용 가능합니다.';
      }
      return '죄송해요, 그 질문에 대해 정확히 답변드리기 어려워요. 로그인, 회원가입, 비밀번호 찾기, 서비스 소개 등에 대해 물어보실 수 있어요.';
  }
}

// 챗봇 메시지 처리 API
app.post("/api/chatbot", async (req, res) => {
  try {
    const { message, intent, history } = req.body;
    
    if (!message) {
      return res.status(400).json({ error: "메시지가 필요합니다." });
    }

    // 챗봇 응답 생성
    const response = getChatbotResponse(message, intent, history);
    
    res.json({ response });
  } catch (error) {
    console.error("❌ 챗봇 API 오류:", error);
    res.status(500).json({ error: "서버 오류가 발생했습니다." });
  }
});

// 챗봇 대화 로그 저장 API
app.post("/api/chatbot/logs", async (req, res) => {
  try {
    const { question, answer, timestamp } = req.body;
    
    // 사용자 정보 가져오기 (있는 경우)
    const token = req.headers.authorization?.replace('Bearer ', '');
    let userId = null;
    
    if (token) {
      try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        userId = decoded.userId;
      } catch (err) {
        // 토큰이 없거나 유효하지 않아도 로그는 저장
      }
    }

    const log = new ChatbotLog({
      question,
      answer,
      timestamp: timestamp || new Date(),
      userId: userId
    });

    await log.save();
    res.json({ success: true });
  } catch (error) {
    console.error("❌ 챗봇 로그 저장 오류:", error);
    res.status(500).json({ error: "로그 저장 실패" });
  }
});

// 챗봇 통계 API (관리자용)
app.get("/api/chatbot/stats", async (req, res) => {
  try {
    // 인기 질문 통계
    const popularQuestions = await ChatbotLog.aggregate([
      { $group: { _id: "$question", count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 10 }
    ]);

    // 의도별 통계
    const intentStats = await ChatbotLog.aggregate([
      { $group: { _id: "$intent", count: { $sum: 1 } } },
      { $sort: { count: -1 } }
    ]);

    res.json({
      popularQuestions,
      intentStats,
      totalLogs: await ChatbotLog.countDocuments()
    });
  } catch (error) {
    console.error("❌ 챗봇 통계 오류:", error);
    res.status(500).json({ error: "통계 조회 실패" });
  }
});

// ===============================
// ✅ 서버 실행
// ===============================
app.listen(3000, "0.0.0.0", () => {
  console.log(`✅ Backend running on ${PUBLIC_IP}`);
});
