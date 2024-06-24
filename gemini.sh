#!/bin/bash

escape_json_text() {
  local escaped_text
  escaped_text=$(echo "$1" | sed 's/\\/\\\\/g' | sed 's/"/\\\"/g')

  echo "$escaped_text"
  return 0
}

clear

SCRIPT_DIR=$(dirname "$0")

API_KEY_FILE="$SCRIPT_DIR/gemini_api_key.txt"
CHAT_HISTORY_FILE="$SCRIPT_DIR/chat_history.txt"

USE_BAT=true # print out the response with bat command
BAT_PATH="$(which bat)"

if [ $USE_BAT = "true" ] && [ -z "$BAT_PATH" ]; then
  echo "bat 未安裝。 無法使用 bat 顯示回應，將使用 echo"
  USE_BAT=false
fi

if [ ! -f "$API_KEY_FILE" ]; then
  echo "API 金鑰文件不存在。請創建一個包含 API 金鑰的文件: $API_KEY_FILE"
  exit 1
fi

chat_history=$(cat "$CHAT_HISTORY_FILE")

GEMINI_API_KEY=$(cat "$API_KEY_FILE")

if [ -z "$GEMINI_API_KEY" ]; then
  echo "請先設置 GEMINI_API_KEY 環境變數。"
  exit 1
fi

MODEL="gemini-1.5-flash" # gemini-1.5-flash, gemini-1.5-pro, gemini-pro
API_URL="https://generativelanguage.googleapis.com/v1/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}"
SYSTEM_PROMPT="System prompt: you're a llm assistant, please always respond in traditional chinese #zh-TW in every response, unless the term is a jargon or is better for staying in English."
XCLIP_PATH="$(which xclip)"
text=""
QUESTION_POSTFIX=", please respond in traditional chinese #zh-TW" # text that is always appended to end of every question

echo "使用 help 來查看指令。使用 exit 退出。"

while true; do
  # allow up and down select from history
  read -r -e -d $'\n' -p '請輸入您的問題：' question

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

  escaped_question=$(escape_json_text "$question $QUESTION_POSTFIX")

  request_body="
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
          $chat_history
          {
            \"role\":\"user\",
            \"parts\": [{\"text\":\"$escaped_question\"}]
          }
        ]
      }
      "

  # NOTE: using the stdin input to prevent curl too long argument list size
  response=$(curl -s "$API_URL" -H "Content-Type: application/json"  --data-binary @- << EOF
  $request_body
EOF
)

  text=$(echo "$response" | jq -r '.candidates[0].content.parts[0].text')
  echo -e "====================\n"

  if [ "$text" = "null" ]; then
    echo "沒有收到回應。response: $response"
  else
    if [ $USE_BAT = "true" ]; then
      echo "$text" | bat -l md --paging=never --style="plain" --color=always --theme="OneHalfDark"
    else
      echo "$text" # stays on terminal
    fi

    escaped_text=$(escape_json_text "$text")
    new_lines="{\"role\":\"user\",\"parts\":[{\"text\":\"$escaped_question\"}]},
    {\"role\":\"model\",\"parts\":[{\"text\":\"${escaped_text}\"}]},"
    echo "$new_lines" >>"$CHAT_HISTORY_FILE"
    chat_history+="$new_lines"
  fi

  echo -e "\n"
  history -s "$question"
done
