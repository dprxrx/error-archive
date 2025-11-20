# 챗봇 기능 가이드

## 현재 구현된 기능

### 1. 기본 대화 기능
- ✅ 인사말 인식 (안녕, hello, hi)
- ✅ 로그인 방법 안내
- ✅ 회원가입 안내
- ✅ 비밀번호 찾기 안내
- ✅ 서비스 소개
- ✅ 도움말 제공
- ✅ 기본 응답 (알 수 없는 질문 처리)

### 2. UI 기능
- ✅ 플로팅 버튼 (우측 하단)
- ✅ 채팅 창 토글
- ✅ 메시지 입력 및 전송
- ✅ Enter 키로 전송
- ✅ 사용자/봇 메시지 구분
- ✅ 자동 스크롤

---

## 추가 가능한 기능

### 1. 고급 대화 기능

#### A. 컨텍스트 기억
```javascript
// 대화 히스토리 저장
let conversationHistory = [];

function addMessage(text, isUser) {
  conversationHistory.push({ text, isUser, timestamp: Date.now() });
  // ... 기존 코드
}
```

#### B. 빠른 응답 버튼
```javascript
// 자주 묻는 질문 버튼
const quickReplies = [
  '로그인 방법',
  '회원가입',
  '비밀번호 찾기',
  '서비스 소개'
];
```

#### C. 이모지 지원
```javascript
// 이모지로 감정 표현
const emojiResponses = {
  '좋아': '👍 좋아요!',
  '고마워': '😊 천만에요!',
  '안녕': '👋 안녕하세요!'
};
```

### 2. 백엔드 연동 기능

#### A. API 연동
```javascript
// 백엔드 API 호출
async function getBotResponse(userMessage) {
  try {
    const response = await fetch('/api/chatbot', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message: userMessage })
    });
    const data = await response.json();
    return data.response;
  } catch (error) {
    return '죄송해요, 서버 연결에 문제가 있어요.';
  }
}
```

#### B. 사용자 정보 활용
```javascript
// 로그인 상태 확인
const user = JSON.parse(localStorage.getItem('user'));
if (user) {
  // 로그인한 사용자에게 맞춤 응답
  return `안녕하세요, ${user.name}님!`;
}
```

### 3. AI 기능 통합

#### A. ChatGPT API 연동
```javascript
async function getAIBotResponse(userMessage) {
  const response = await fetch('/api/chatgpt', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ 
      message: userMessage,
      context: 'Error Archive 서비스에 대한 질문'
    })
  });
  const data = await response.json();
  return data.response;
}
```

#### B. 자연어 처리 개선
```javascript
// 더 정확한 의도 파악
function detectIntent(message) {
  const intents = {
    login: ['로그인', 'login', '접속'],
    signup: ['회원가입', '가입', 'signup'],
    password: ['비밀번호', 'password', '찾기'],
    service: ['서비스', '소개', '뭐', 'what']
  };
  
  for (const [intent, keywords] of Object.entries(intents)) {
    if (keywords.some(keyword => message.includes(keyword))) {
      return intent;
    }
  }
  return 'unknown';
}
```

### 4. 사용자 경험 개선

#### A. 타이핑 애니메이션
```javascript
function addTypingIndicator() {
  const typingDiv = document.createElement('div');
  typingDiv.className = 'message bot typing';
  typingDiv.innerHTML = '<div class="typing-indicator"><span></span><span></span><span></span></div>';
  chatbotMessages.appendChild(typingDiv);
  chatbotMessages.scrollTop = chatbotMessages.scrollHeight;
}

function removeTypingIndicator() {
  const typing = chatbotMessages.querySelector('.typing');
  if (typing) typing.remove();
}
```

#### B. 메시지 읽음 표시
```javascript
function addMessage(text, isUser) {
  // ... 기존 코드
  if (!isUser) {
    setTimeout(() => {
      bubble.classList.add('read');
    }, 1000);
  }
}
```

#### C. 음성 입력
```javascript
// Web Speech API 사용
function startVoiceInput() {
  const recognition = new webkitSpeechRecognition();
  recognition.lang = 'ko-KR';
  recognition.onresult = (event) => {
    const transcript = event.results[0][0].transcript;
    chatbotInput.value = transcript;
    sendMessage();
  };
  recognition.start();
}
```

### 5. 데이터 분석 기능

#### A. 대화 로그 저장
```javascript
// 사용자 질문 통계
function saveConversationLog(message, response) {
  fetch('/api/chatbot/logs', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      question: message,
      answer: response,
      timestamp: new Date().toISOString()
    })
  });
}
```

#### B. 인기 질문 추적
```javascript
// 자주 묻는 질문 분석
const questionStats = {};

function trackQuestion(message) {
  questionStats[message] = (questionStats[message] || 0) + 1;
  // 백엔드로 전송
}
```

### 6. 고급 기능

#### A. 파일 업로드
```javascript
// 에러 로그 파일 업로드 지원
function handleFileUpload(file) {
  const formData = new FormData();
  formData.append('file', file);
  
  fetch('/api/upload-error-log', {
    method: 'POST',
    body: formData
  }).then(response => {
    return '에러 로그를 분석했습니다!';
  });
}
```

#### B. 링크 미리보기
```javascript
// URL 감지 및 미리보기
function detectURLs(text) {
  const urlRegex = /(https?:\/\/[^\s]+)/g;
  return text.replace(urlRegex, (url) => {
    return `<a href="${url}" target="_blank">${url}</a>`;
  });
}
```

#### C. 다국어 지원
```javascript
const translations = {
  ko: {
    greeting: '안녕하세요!',
    help: '도움말'
  },
  en: {
    greeting: 'Hello!',
    help: 'Help'
  }
};

function getTranslation(key, lang = 'ko') {
  return translations[lang][key] || translations.ko[key];
}
```

---

## 구현 우선순위 추천

### 높은 우선순위
1. ✅ 빠른 응답 버튼 (사용자 편의성)
2. ✅ 타이핑 애니메이션 (UX 개선)
3. ✅ 백엔드 API 연동 (확장성)

### 중간 우선순위
4. 컨텍스트 기억
5. 자연어 처리 개선
6. 대화 로그 저장

### 낮은 우선순위
7. AI 기능 통합 (ChatGPT)
8. 음성 입력
9. 파일 업로드
10. 다국어 지원

---

## 구현 예시 코드

### 빠른 응답 버튼 추가
```javascript
function addQuickReplies() {
  const quickReplies = ['로그인 방법', '회원가입', '비밀번호 찾기'];
  const quickReplyContainer = document.createElement('div');
  quickReplyContainer.id = 'quick-replies';
  
  quickReplies.forEach(reply => {
    const button = document.createElement('button');
    button.className = 'quick-reply-btn';
    button.textContent = reply;
    button.onclick = () => {
      chatbotInput.value = reply;
      sendMessage();
    };
    quickReplyContainer.appendChild(button);
  });
  
  chatbotMessages.appendChild(quickReplyContainer);
}
```

### 타이핑 애니메이션 추가
```css
.typing-indicator {
  display: flex;
  gap: 4px;
  padding: 10px;
}

.typing-indicator span {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #999;
  animation: typing 1.4s infinite;
}

.typing-indicator span:nth-child(2) {
  animation-delay: 0.2s;
}

.typing-indicator span:nth-child(3) {
  animation-delay: 0.4s;
}

@keyframes typing {
  0%, 60%, 100% { transform: translateY(0); }
  30% { transform: translateY(-10px); }
}
```

---

## 백엔드 API 예시

### 챗봇 엔드포인트 추가 (backend/server.js)
```javascript
// 챗봇 API
app.post("/api/chatbot", async (req, res) => {
  const { message } = req.body;
  
  // 간단한 규칙 기반 응답
  let response = getBotResponse(message);
  
  // 필요시 AI API 호출
  // const aiResponse = await callChatGPT(message);
  // response = aiResponse || response;
  
  res.json({ response });
});

function getBotResponse(message) {
  const msg = message.toLowerCase();
  
  if (msg.includes('로그인')) {
    return '로그인 페이지에서 아이디와 비밀번호를 입력하시면 됩니다.';
  }
  // ... 기타 응답 로직
  
  return '죄송해요, 좀 더 구체적으로 질문해주시겠어요?';
}
```

