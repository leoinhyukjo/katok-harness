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
