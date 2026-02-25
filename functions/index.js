const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const axios = require("axios");
.
const openAiKey = defineSecret("OPENAI_API_KEY");

// 'askToChatGPT'라는 이름의 서버 API를 만듭니다.
exports.askToChatGPT = onCall({ secrets: [openAiKey] }, async (request) => {
  try {
    // 1. 플러터 앱에서 보낸 데이터 받기
    const userText = request.data.userText;
    const bookList = request.data.bookList;
    
    // 2. 파이어베이스 에서 API 키 꺼내기
    const apiKey = openAiKey.value();

const systemPrompt = `
너는 'Bookit(북잇)' 앱의 인공지능 사서 '부기'야.
사용자에게 맞는 책을 아래 [보유 도서 목록]에서 찾아 1권만 추천해.

[절대 규칙 - 이것을 어기면 시스템이 고장남]
책을 추천할 때는 대답의 맨 마지막 줄에 무조건 해당 책의 ID를
[BOOK_ID:아이디값] 이라는 정확한 형태로 적어야 해. (예시: [BOOK_ID:1a2b3c4d])

[보유 도서 목록]
${bookList}
`;

    // 서버에서 안전하게 OpenAI로 요청 보내기
    const response = await axios.post(
      "https://api.openai.com/v1/chat/completions",
      {
        model: "gpt-4o-mini",
        messages: [
          { role: "system", content: systemPrompt },
          { role: "user", content: userText }
        ],
        temperature: 0.7,
      },
      {
        headers: {
          "Content-Type": "application/json; charset=utf-8",
          Authorization: `Bearer ${apiKey}`,
        },
      }
    );

    // 플러터 앱으로 결과값 반환
    return { 
      result: response.data.choices[0].message.content 
    };

  } catch (error) {
    console.error("OpenAI Error:", error);
    throw new HttpsError("internal", "GPT 서버 통신 실패");
  }
});