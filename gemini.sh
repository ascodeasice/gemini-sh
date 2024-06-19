#!/bin/bash

clear

SCRIPT_DIR=$(dirname "$0")

API_KEY_FILE="$SCRIPT_DIR/gemini_api_key.txt"

if [ ! -f "$API_KEY_FILE" ]; then
  echo "API 金鑰文件不存在。請創建一個包含 API 金鑰的文件: $API_KEY_FILE"
  exit 1
fi

GEMINI_API_KEY=$(cat "$API_KEY_FILE")

if [ -z "$GEMINI_API_KEY" ]; then
  echo "請先設置 GEMINI_API_KEY 環境變數。"
  exit 1
fi

API_URL="https://generativelanguage.googleapis.com/v1/models/gemini-pro:generateContent?key=${GEMINI_API_KEY}"
SYSTEM_PROMPT="System prompt: please respond in traditional chinese #zh-TW, unless the term is a jargon or is better for staying in English."

while true; do
  read -erp "請輸入您的問題：" question
  # TODO: if question is empty, continue

  if [ "$question" == "help" ]; then
    echo -e "'exit' 退出\n'clear' 清除屏幕\n"
    continue
  fi

  if [ "$question" == "exit" ]; then
    echo "再見！"
    break
  fi

  if [ "$question" == "clear" ]; then
    clear
    continue
  fi

  # TODO: copy the last response if the question is copy

  response=$(curl -s "$API_URL" -H "Content-Type: application/json" \
    -d "
      {
        \"contents\": [
          {
            role: \"user\",
            parts: [ { \"text\": \"$SYSTEM_PROMPT\"}]
          },
          {
            role: \"model\",
            parts: [{ text: \"Understood.\"}]
          },
          {
            \"role\":\"user\",
            \"parts\": [{\"text\":\"$question\"}]
          }
        ]
      }
      ")

  text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text')
  echo -e "====================\n"

  echo "$text"

  if [ "$text" = "null" ]; then
    echo "沒有收到回應。response: $response"
  fi
  echo -e "\n"
done
