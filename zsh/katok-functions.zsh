kt() {
  local q=${1//\'/\'\'}
  sqlite3 -separator '  |  ' "$HOME/Library/Application Support/katok/archive.sqlite3" \
    "SELECT substr(timestamp,1,16), chat_name, sender_nickname, replace(replace(text,char(10),' '),char(13),' ')
     FROM messages WHERE text LIKE '%$q%' ORDER BY timestamp DESC LIMIT ${2:-20};"
}
ktc() {
  local q=${1//\'/\'\'}
  sqlite3 -separator '  |  ' "$HOME/Library/Application Support/katok/archive.sqlite3" \
    "SELECT substr(timestamp,1,16), sender_nickname, replace(replace(text,char(10),' '),char(13),' ')
     FROM messages WHERE chat_name LIKE '%$q%' ORDER BY timestamp DESC LIMIT ${2:-30};"
}
# ktx [방이름] — 방별 txt(~/Downloads/katok-txt/, 실시간: katok_sync.sh 가 갱신). 인자 있으면 그 방 TextEdit 로 열기
ktx() {
  "$HOME/.claude/scripts/katok_txt.sh" "$@"
  [[ -n $1 ]] && open -a TextEdit "$HOME/Downloads/katok-txt"/*"$1"*.txt || open "$HOME/Downloads/katok-txt"
}
