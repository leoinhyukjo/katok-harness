#!/bin/zsh
# 방별 txt 내보내기(KST). 인자: 방이름 부분일치(없으면 전체). katok_sync.sh 가 신규 적재 때마다 호출.
set -u
DB="$HOME/Library/Application Support/katok/archive.sqlite3"; OUT="$HOME/Downloads/katok-txt"; mkdir -p "$OUT"
WHERE=""; [[ -n "${1:-}" ]] && WHERE="WHERE chat_name LIKE '%${1//\'/\'\'}%'"
sqlite3 "$DB" "SELECT DISTINCT chat_name FROM messages $WHERE;" | while IFS= read -r c; do
  q=${c//\'/\'\'}
  sqlite3 -separator '  ' "$DB" "SELECT strftime('%Y-%m-%d %H:%M', datetime(timestamp,'+9 hours')), sender_nickname||':', replace(replace(text,char(10),' '),char(13),' ') FROM messages WHERE chat_name='$q' ORDER BY timestamp;" > "$OUT/${c//\//_}.txt"
done
