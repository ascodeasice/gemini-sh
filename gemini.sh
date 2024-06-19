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
XCLIP_PATH="$(which xclip)"
text=""

echo "使用 help 來查看幫助。使用 exit 退出。"

while true; do
  read -erp "請輸入您的問題：" question

  # if question is empty, continue
  if [ -z "$question" ]; then
    continue
  fi

  case "$question" in
  help)
    echo "
'exit' 退出
'clear' 清除屏幕
'copy' 複製上一次的回答
'help' 顯示此幫助
    "
    continue
    ;;
  exit)
    break
    ;;
  clear)
    clear
    continue
    ;;
  copy)
    if [ -z "$XCLIP_PATH" ]; then
      echo -e "\nxclip 未安裝。\n"
      continue
    else
      echo -n "$text" | xclip -selection clipboard
      echo -e "\n已複製上一次的回答。\n"
      continue
    fi
    ;;
  esac

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
